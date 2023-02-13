{smcl}
{* *! version 16.0 13feb2023}{...}
{title:specurve - Specification Curve Analysis}{smcl}

{cmd:specurve} performs {browse "https://mingze-gao.com/posts/specification-curve-analysis/":specification curve analysis} as specified by the YAML-formatted {it:filename} and plot the specification curve.
{viewerjumpto "Syntax" "specurve##syntax"}{...}
{viewerjumpto "Options" "specurve##options"}{...}
{viewerjumpto "Configuration file" "specurve##configuration"}{...}
{viewerjumpto "Examples" "specurve##examples"}{...}
{viewerjumpto "Thanks" "specurve##thanks"}{...}
{viewerjumpto "Author" "specurve##author"}{...}

{marker syntax}{...}

{title:Syntax}

{cmd:specurve} {cmd:using} {it:filename}{cmd:,} [{opt w:idth(real)} {opt h:eight(real)} {opt realativesize(real)} {opt scale(real)} {opt title(string)} {opt saving(name)} {opt name(string)} {opt desc:ending} {opt out:put} {opt b:enchmark(real)}]

{marker Options}{...}

{title:Options}

{synoptset 30}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt w:idth(real)}} set width of the specification curve plot.{p_end}
{synopt:{opt h:eight(real)}} set height of the specification curve plot.{p_end}
{synopt:{opt relativesize(real)}} set the size of coefficients panel relative to the entire plot. Defaults to 0.6.{p_end}
{synopt:{opt scale(real)}} resize text, markers, and line widths.{p_end}
{synopt:{opt title(string)}} set graph title.{p_end}
{synopt:{opt saving(name)}} save graph as {it:name}.{p_end}
{synopt:{opt name(string)}} set graph title as {it:string}.{p_end}
{synopt:{opt desc:ending}} plot coefficients in descending order.{p_end}
{synopt:{opt out:put}} display all regression outputs.{p_end}
{synopt:{opt b:enchmark}} set the benchmark level. Defaults to 0.{p_end}
{synoptline}

{marker Configuration}{...}

{title:Configuration file}

{p}
The configuration file is a YAML-formatted text file that describes all the model specifications. Its basic format is:

    Choices:
        Group:
            - Label: Variables
    Conditions:
        Group:
            - Label: Variables

Some reserved keywords (in bold font below) must present in the configuration file.

    {bf:Choices:}
        {bf:Dependent Variable:}
            - Label of the dependent variable: {var}
        {bf:Focal Variable:}
            - Label of the key independent variable of interest: {var}
        {bf:Control Variables:}
            - Label of a set of control variables, such as "baseline": {varlist}
            - Label of another set of control variables: {varlist}

For example:

    Choices:
        Dependent Variable:
            - Depvar1 label: depvar1
            - Depvar2 label: depvar2
        Focal Variable:
            - Key measure of something: focal_var1
        Control Variables:
            - Baseline: ctrl1 ctrl2 ctrl3 ctrl4
            - Baseline and Ctrl5: ctrl1 ctrl2 ctrl3 ctrl4 ctrl5
        Fixed Effects:
            - Firm and Year: gvkey fyear
            - Industry and Year: sic2 fyear
        Standard Error Clustering:
            - By Firm: gvkey
            - By Industry: sic2

    Conditions:
        Sample Period:
            - Full Sample: 1993 <= fyear & fyear <= 2020
            - Excluding GFC: (1993 <= fyear & fyear <= 2006) | fyear >= 2009


{hline}
{marker examples}{...}

{title:Examples}


{pstd}Use the National Longitudinal Survey (Young Women 14-26 years of age in 1968) as an example.

{phang2}{stata "use http://www.stata-press.com/data/r13/nlswork.dta, clear"}

{pstd}Download an example YAML-formatted configuration file:

{phang2}{stata "copy https://mingze-gao.com/specurve/example_config_nlswork_1.yml ., replace"}

{pstd}Run {cmd:specurve} using the downloaded configuration file and make a specification curve plot with default options.

{phang2}{stata specurve using example_config_nlswork_1.yml}
 
{pstd}Next, let's try two dependent variables. For illustration, we create a {bf:wage} variable by exponentiating {bf:ln_wage}:

{phang2}{stata gen wage = exp(ln_wage)}

{pstd}Then download and use the second example configuration file:

{phang2}{stata "copy https://mingze-gao.com/specurve/example_config_nlswork_2.yml ., replace"}

{phang2}{stata specurve using example_config_nlswork_2.yml, desc width(10) height(13) scale(0.95) relativesize(0.4)}

{pstd}Note here, we changed the width of the plot and modified the (left) spacing between the annotation and plot margin.

{pstd}Lastly, to remove the downloaded example configuration files, run the following commands:

{phang2}{stata rm example_config_nlswork_1.yml}

{phang2}{stata rm example_config_nlswork_2.yml}

{hline}

{marker thanks}{...}
{title:Thanks to}

Uri Simonsohn, Joseph Simmons and Leif D. Nelson for their paper "Specification Curve Analysis" (Nat Hum Behav, 2020, and previous working paper), first (?) suggesting the specification curve.

Rawley Heimer from Boston College who visited our discipline in 2019 and introduced the Specification Curve Analysis to us in the seminar on research methods.

Martin Andresen from University of Oslo who made the {browse "https://github.com/martin-andresen/speccurve":{cmd:speccurve}} open-sourced on GitHub.

{marker author}{...}
{title:Author}

{browse "https://mingze-gao.com":Mingze Gao} from the University of Sydney.

{marker note}{...}
{title:Note}

This version of {cmd:specurve} has removed Python dependency. 
