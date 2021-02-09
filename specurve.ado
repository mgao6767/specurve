version 16.1

python:
from sfi import SFIToolkit, Macro, Scalar, Frame
import yaml
import itertools
import pandas as pd
from typing import Dict, List, NewType
from dataclasses import dataclass, field
try:
    import plotly.graph_objects as go
    SFIToolkit.displayln("Python modules loaded successfully.")
except ImportError:
    SFIToolkit.errprintln("Python module 'plotly' not found.")
    SFIToolkit.errprintln("You should try to install plotly via pip. Check https://pypi.org/project/plotly/ for installation guide.")
    SFIToolkit.exit(198)


Group = NewType("Name of the group", str)
Label = NewType("Label of the case in the group", str)
Variables = NewType("Variables or condition of a case in the group", str)


required_keywords = {
    "Dependent Variable",
    "Focal Variable",
    "Control Variables",
}

category_array = []

model_specs, label_to_variables, label_to_group = {}, {}, {}

@dataclass
class Specification:
    choices: Dict[Group, Label]
    conditions: Dict[Group, Label]
    variables: Dict[Label, Variables]
    focal_variable: Label
    specification = None
    stata_cmd = None

    def __post_init__(self):
        # human-readable model specification
        self.specification = {**self.choices, **self.conditions}
        # building the Stata command for this specification
        lhs = self.variables.get(self.choices.get("Dependent Variable"))
        key = self.variables.get(self.choices.get("Focal Variable"))
        ctrl = self.variables.get(self.choices.get("Control Variables"))
        self.stata_cmd = f"reghdfe {lhs} {key} {ctrl}, "
        fixed_effects = self.variables.get(self.choices.get("Fixed Effects"))
        if fixed_effects:
            self.stata_cmd += f"absorb({fixed_effects}) "
        else:
            self.stata_cmd += "noabsorb "
        se_cluster = self.variables.get(
            self.choices.get("Standard Error Clustering")
        )
        if se_cluster:
            self.stata_cmd += f"cluster({se_cluster})"
        if self.conditions:
            combined_condition = " & ".join(
                f"({self.variables.get(condition)})"
                for _, condition in self.conditions.items()
            )
            self.stata_cmd = self.stata_cmd.replace(
                ",", f" if {combined_condition},"
            )


def read_configuration(config_file: str):
    SFIToolkit.errprintlnDebug("Debug mode on.")
    try:
        with open(config_file) as f:
            cfg = yaml.load(f, Loader=yaml.FullLoader)
    except FileNotFoundError:
        SFIToolkit.errprintln("Configuration file not found.")
        SFIToolkit.exit(601)

    choices: Dict[Group, List[Dict[Label, Variables]]] = cfg.get("Choices")
    conditions: Dict[Group, List[Dict[Label, Variables]]] = cfg.get("Conditions")

    # Check the presence of choices in configuration
    if not choices:
        SFIToolkit.errprintln("No choices found in configuration file.")
        SFIToolkit.exit(198)
    # Check all required groups presented
    if not required_keywords.issubset(choices.keys()):
        SFIToolkit.errprintln("Insufficient specification.")
        SFIToolkit.exit(198)

    # Build dicts of label to its variables and of label to its group
    global label_to_variables  # bad usage of global variable but anyway
    global label_to_group  # bad usage of global variable but anyway

    label_to_variables = {
        **lbl_to_vars(choices),
        **lbl_to_vars(conditions),
    }
    label_to_group = {
        **lbl_to_grp(choices),
        **lbl_to_grp(conditions),
    }

    focal_vars = choices.get("Focal Variable")
    alternatives: Dict[Group, List[Dict[Label, Variables]]] = {
        **choices,
        **conditions,
    }

    global category_array
    category_array = []  # reset to empty list
    for group, cases in choices.items():
        if group == "Focal Variable":
            continue
        category_array.append(f"<b>{group}</b>")
        for case in cases:
            label, _ = next(iter(case.items()))
            category_array.append(label)

    for group, cases in conditions.items():
        if group == "Focal Variable":
            continue
        category_array.append(f"<b>{group}</b>")
        for case in cases:
            label, _ = next(iter(case.items()))
            category_array.append(label)

    if not len(focal_vars):
        SFIToolkit.errprintln("No focal variable found in configuration file.")
        SFIToolkit.exit(198)

    return focal_vars, choices, conditions, alternatives

def gen_models_from(config_file: str):

    focal_vars, choices, conditions, alternatives = read_configuration(config_file)
    labels_of_ = lambda x: [k for cs in x.values() for c in cs for k in c]
    labels_of_choices: List[Label] = labels_of_(choices)
    labels_of_conditions: List[Label] = labels_of_(conditions)
    # Compose the Stata command to estimate the models
    models = []
    for focal_var in focal_vars:
        label_focal_var, _ = next(iter(focal_var.items()))
        alternatives["Focal Variable"] = [focal_var]
        for spec in itertools.product(*alternatives.values()):
            labels_of_spec: List[Label] = [k for case in spec for k, v in case.items()]
            _choices, _conditions = {}, {}
            for label in labels_of_spec:
                group = label_to_group.get(label)
                if label in labels_of_choices:
                    _choices.update({group: label})
                elif label in labels_of_conditions:
                    _conditions.update({group: label})
            models.append(
                Specification(
                    _choices, _conditions, label_to_variables, label_focal_var
                )
            )
    # Store the Stata command to macro (to be executed in Stata environment)
    Scalar.setValue("num_models", len(models))
    global model_specs
    model_specs = {}  # reset model_specs
    for i in range(len(models)):
        model = models[i]
        Macro.setLocal(f"model{i+1}_cmd", model.stata_cmd)
        Macro.setLocal(
            f"model{i+1}_focal_var",
            label_to_variables.get(model.focal_variable),
        )
        model_specs.update({f"model{i+1}": model.specification})

def gen_specurve_plot(results_file: str, output_file: str, width: int, height: int, fontscale: float, annotation_shift: int):
    SFIToolkit.displayln("Generating specification curve plots.")
    SFIToolkit.errprintlnDebug(f"{results_file=}")
    frame = Frame.connect(results_file)
    data = frame.getAsDict()
    results = pd.DataFrame.from_dict(data).set_index("model")
    annotation = pd.DataFrame(model_specs).T
    data = annotation.join(results)

    depvars = list(set(data["Dependent Variable"]))
    SFIToolkit.displayln(f"{depvars=}")
    n_depvars = len(depvars)
    key_vars = set(results["variable"])

    # Let's focus on one focal variable first
    focal_var = key_vars.pop()

    #######################################
    traces_ests, traces_spec = [], []
    y1axes, y2axes, y3axes = [], [], []
    x1axes, x2axes = [], []

    for idx, depvar in enumerate(depvars):
        (
            trace_ests,
            trace_spec,
            y1_layout,
            y2_layout,
            y3_layout,
            x1_layout,
            x2_layout,
        ) = gen_traces(data, depvar, focal_var, idx, n_depvars)

        traces_ests.extend(trace_ests)
        traces_spec.extend(trace_spec)
        y1axes.append(y1_layout)
        y2axes.append(y2_layout)
        y3axes.append(y3_layout)
        x1axes.append(x1_layout)
        x2axes.append(x2_layout)

    focal_var_label = list(label_to_variables.keys())[
        list(label_to_variables.values()).index(focal_var)
    ]
    fig = go.Figure(
        data=traces_ests + traces_spec,
        layout=dict(
            showlegend=False,
            width=1200,
            height=900,
            title=dict(text=f"Specification Curve Analysis of {focal_var_label}", 
                x=0.5,
                font=dict(size=22),
                xanchor="center", yanchor="top")
        ),
    )

    for idx in range(len(depvars)):
        fig["layout"][f"xaxis{idx*2+1}"] = x1axes[idx]
        fig["layout"][f"xaxis{idx*2+2}"] = x2axes[idx]
        fig["layout"][f"yaxis{idx*3+1}"] = y1axes[idx]
        fig["layout"][f"yaxis{idx*3+2}"] = y2axes[idx]
        fig["layout"][f"yaxis{idx*3+3}"] = y3axes[idx]

    # Annotation

    tmp = data[data["Dependent Variable"] == depvars[0]].sort_values(
        ["beta"], ascending=False
    )
    annotations = [
        dict(
            xref="paper",
            yref="y3",
            x=0.01,
            xshift=annotation_shift,
            y=0,
            xanchor="right",
            yanchor="middle",
            text="Threshold of 0",
            font={"size": 12*fontscale},
            showarrow=False,
        ),
        dict(
            xref="paper",
            yref="y3",
            x=0.01,
            xshift=annotation_shift,
            y=tmp["beta"][0],
            xanchor="right",
            yanchor="middle",
            text="<b>coefficient estimates</b>",
            font={"size": 13*fontscale},
            showarrow=False,
        ),
        dict(
            xref="paper",
            yref="y3",
            x=0.01,
            xshift=annotation_shift,
            y=tmp["ub"][0],
            xanchor="right",
            yanchor="middle",
            text="95% Upper Interval",
            font={"size": 10*fontscale},
            showarrow=False,
        ),
        dict(
            xref="paper",
            yref="y3",
            x=0.01,
            xshift=annotation_shift,
            y=tmp["lb"][0],
            xanchor="right",
            yanchor="middle",
            text="95% Lower Interval",
            font={"size": 10*fontscale},
            showarrow=False,
        ),
        dict(
            xref="paper",
            yref="y1",
            x=0.01,
            xshift=annotation_shift,
            y=tmp["obs"][0],
            xanchor="right",
            yanchor="middle",
            text="sample size",
            font={"size": 10*fontscale},
            showarrow=False,
        ),
    ]
    fig.layout.annotations = annotations
    fig.write_image(output_file, width=width, height=height)


def gen_traces(data, depvar, focal_var, idx, n_depvars):

    y1 = f"y{idx*3+1}"
    y2 = f"y{idx*3+2}"
    y3 = f"y{idx*3+3}"
    x1 = f"x{idx*2+1}"
    x2 = f"x{idx*2+2}"

    data = data[data["Dependent Variable"] == depvar].copy()
    groups = set(data.columns) - set(
        ["ub", "lb", "beta", "obs", "model", "Focal Variable", "variable"]
    )
    data.sort_values(["beta"], inplace=True, ascending=False)
    data.index = [f"{i+1}" for i in range(len(data))]

    trace_ests = [
        # Sample size
        # yaxis is set to y1 because yaxis1 is drawn first
        go.Bar(
            x=data.index,
            y=data["obs"],
            name="Observations",
            xaxis=x1,
            yaxis=y1,
            marker_color="rgba(150, 150, 150, 0.8)",
        ),
        # Confidence interval lower bound
        # yaxis3 is drawn after y1 so these series overlay sample size
        go.Scatter(
            x=data.index,
            y=data["lb"],
            name="95% Interval (Lower)",
            mode="lines+markers",
            xaxis=x1,
            yaxis=y3,
            showlegend=True,
            marker_color="rgb(200, 200, 200)",
        ),
        # Confidence internval upper bound
        go.Scatter(
            x=data.index,
            y=data["ub"],
            name="95% Interval (Upper)",
            mode="lines+markers",
            xaxis=x1,
            yaxis=y3,
            showlegend=True,
            fill="tonexty",
            marker_color="rgb(200, 200, 200)",
        ),
        # Beta estimates
        go.Scatter(
            x=data.index,
            y=data["beta"],
            name=f"{focal_var.upper()}",
            mode="lines+markers+text",
            text=[round(data["beta"][0], 2)]
            + [None] * (len(data) - 2)
            + [round(data["beta"][-1], 2)],
            textposition="bottom center",
            xaxis=x1,
            yaxis=y3,
            showlegend=True,
            marker_color="#3366CC",
        ),
        # Threshold y=0
        go.Scatter(
            x=data.index,
            y=[0] * len(data),
            name="Threshold=0",
            xaxis=x1,
            yaxis=y3,
            mode="lines",
            marker_color="grey",
        ),
    ]
    trace_spec = [
        go.Scatter(
            x=data.index,
            y=data[col],
            mode="markers",
            showlegend=False,
            xaxis=x2,
            yaxis=y2,
        )
        for col in groups
    ] + [
        go.Scatter(
            x=data.index,
            y=[col],
            showlegend=False,
            marker_color="rgba(255,255,255,0)",
            xaxis=x2,
            yaxis=y2,
        )
        for col in category_array
        if "<b>" in col
    ]

    domain_len = 1 / n_depvars

    x1_layout = dict(
        showticklabels=False,
        anchor=y1,
        domain=[domain_len * idx + domain_len / 12, domain_len * (idx + 1)],
    )
    x2_layout = dict(
        anchor=y2,
        domain=[domain_len * idx + domain_len / 12, domain_len * (idx + 1)],
        title="Model",
    )
    y1_layout = dict(
        anchor=x1,
        showticklabels=False,
        side="right",
        domain=[0.6, 1],
        range=(0, max(data["obs"]) * 6),
    )
    y2_layout = dict(
        domain=[0, 0.6],
        anchor=x2,
        showticklabels=False if idx > 0 else True,
        showgrid=False,
        categoryorder="array",
        categoryarray=list(reversed(category_array)),
    )
    y3_layout = dict(
        anchor=x1,
        overlaying=y1,
        side="left",
        zeroline=True,
        showgrid=False,
        showticklabels=False
        # ticks="inside",
        # tickfont=dict(size=5),
    )
    return (
        trace_ests,
        trace_spec,
        y1_layout,
        y2_layout,
        y3_layout,
        x1_layout,
        x2_layout,
    )




# Some helper functions

# build dicts of label to its vars and of label to its group
lbl_to_vars = lambda x: {
    k: v for cs in x.values() for c in cs for k, v in c.items()
}
lbl_to_grp = lambda x: {k: grp for grp, cs in x.items() for c in cs for k in c}

# check if label x is in group of choices/conditions
in_group = lambda x, group, alterinatives: any(
    x in c for c in alterinatives.get(group)
)
end

capture drop program specurve
program specurve
    /* args config width height */
    syntax using/ [, Width(integer 900) Height(integer 1100) FONTScale(real 1.2) annotationshift(integer 50)]
    tempname res
    mkf `res' str32(model variable) double(beta lb ub) int(obs)
    
    python: gen_models_from("`using'")
    
    di as text "`=num_models' models to estimate"
    forvalues i=1/`=num_models' {
        di as text "Estimating model `i'"
        local id = "model`i'"
        local var = "`model`i'_focal_var'"
        
        qui `model`i'_cmd'
        local est = _b[`var']
        local lb = _b[`var'] - invttail(e(df_r),0.025)*_se[`var']
        local ub = _b[`var'] + invttail(e(df_r),0.025)*_se[`var']
        frame post `res' ("`id'") ("`var'") (`est') (`lb') (`ub') (`e(N)')
    }	
    
    local output = "output.png"
    python: gen_specurve_plot("`res'", "`output'", `width', `height', `fontscale', `annotationshift')
    
    frame drop `res'
    
    di as smcl "The specification curve is saved at {browse `output'}"
end 