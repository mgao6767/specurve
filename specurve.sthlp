{smcl}
{* *! version 16.0 31mar2024}{...}
{title:specurve - Specification Curve Analysis}{smcl}

{cmd:specurve} performs {browse "https://mingze-gao.com/posts/specification-curve-analysis/":specification curve analysis} as specified by the YAML-formatted {it:filename} and plot the specification curve.
{viewerjumpto "Syntax" "specurve##syntax"}{...}
{viewerjumpto "Options" "specurve##options"}{...}
{viewerjumpto "Examples" "specurve##examples"}{...}
{viewerjumpto "Configuration file" "specurve##configuration"}{...}
{viewerjumpto "Thanks" "specurve##thanks"}{...}
{viewerjumpto "Author" "specurve##author"}{...}

{marker syntax}{...}

{title:Syntax}

{cmd:specurve} {cmd:using} {it:filename}{cmd:,} [{opt w:idth(real)} {opt h:eight(real)} {opt relativesize(real)} {opt scale(real)}
    {opt title(string)} {opt saving(name)} {opt name(string)} {opt desc:ending} {opt outcmd} {opt out:put} 
    {opt b:enchmark(real)} {opt nob:enchmark} {opt nod:ependent} {opt nof:ocal} {opt nofix:edeffect} {opt noc:luster} {opt nocond:ition}
    {opt noci99} {opt noci95}
    {opt round:ing(real)} {opt yticks(int)} {opt ymin(real)} {opt ymax(real)} {opt cmd(name)} {opt keepsin:gletons} {opt controlvariablebygroup}]

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
{synopt:{opt outcmd}} display the full regression command.{p_end}
{synopt:{opt out:put}} display all regression outputs.{p_end}
{synopt:{opt b:enchmark}} set the benchmark level. Defaults to 0.{p_end}
{synopt:{opt nob:enchmark}} turnoff the benchmark line.{p_end}
{synopt:{opt nod:ependent}} turnoff the display of dependent variable.{p_end}
{synopt:{opt nof:ocal}} turnoff the display of focal variable.{p_end}
{synopt:{opt nofix:edeffect}} turnoff the display of fixed effect.{p_end}
{synopt:{opt noc:luster}} turnoff the display of standard error clustering.{p_end}
{synopt:{opt nocond:ition}} turnoff the display of conditions.{p_end}
{synopt:{opt noci99}} turnoff the display of 99% confidence intervals.{p_end}
{synopt:{opt noci95}} turnoff the display of 95% confidence intervals.{p_end}
{synopt:{opt round:ing(real)}} set the rounding of y-axis labels and hence number of decimal places to display. Defaults to 0.001.{p_end}
{synopt:{opt yticks(int)}} set the number of ticks/labels to display on y-axis. Defaults to 5.{p_end}
{synopt:{opt ymin(real)}} set the min tick of y-axis. Default is automatically set.{p_end}
{synopt:{opt ymax(real)}} set the max tick of y-axis. Default is automatically set.{p_end}
{synopt:{opt cmd(name)}} set the command used to estimate models. Defaults to {cmd:reghdfe}. Can be one of {cmd:reghdfe} and {cmd:ivreghdfe}.{p_end}
{synopt:{opt keepsin:gletons}} keep singleton groups. Only useful when using {cmd:reghdfe}.{p_end}
{synopt:{opt controlvariablebygroup}} the labels of control variables in the configuration file indicate combination of groups, instead of each indicating a distinct group. Please see the example on GitHub to better understand the difference.{p_end}
{synoptline}

{marker examples}{...}

{title:Examples}

{pstd}Use the National Longitudinal Survey (Young Women 14-26 years of age in 1968) as an example.

{phang2}{stata "use http://www.stata-press.com/data/r13/nlswork.dta, clear"}

{pstd}Download an example YAML-formatted configuration file:

{phang2}{stata "copy https://mingze-gao.com/specurve/example_config_nlswork_reghdfe.yml ., replace"}

{pstd}Run {cmd:specurve} using the downloaded configuration file and make a specification curve plot with default options.

{phang2}{stata specurve using example_config_nlswork_reghdfe.yml}
 
{pstd}We can also add options:

{phang2}{stata specurve using example_config_nlswork_reghdfe.yml, desc outcmd width(2) height(2.5) relativesize(0.5) saving(specurve_demo, replace)}

{pstd}For IV regression, we can set the option {opt cmd} to {cmd: ivreghdfe}. As an example, download the example configuration file for IV regression:

{phang2}{stata "copy https://mingze-gao.com/specurve/example_config_nlswork_ivreghdfe.yml ., replace"}

{phang2}{stata specurve using example_config_nlswork_ivreghdfe.yml, cmd(ivreghdfe) rounding(0.01) title("IV regression with ivreghdfe")}

{pstd}Lastly, to remove the downloaded example configuration files, run the following commands:

{phang2}{stata rm example_config_nlswork_reghdfe.yml}

{phang2}{stata rm example_config_nlswork_ivreghdfe.yml}

{pstd}Note that estimation results are saved in the frame named "specurve".

{hline}

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

{marker thanks}{...}
{title:Thanks to}

Uri Simonsohn, Joseph Simmons and Leif D. Nelson for their paper "Specification Curve Analysis" (Nat Hum Behav, 2020, and previous working paper), first (?) suggesting the specification curve.

Rawley Heimer from Boston College who visited our discipline in 2019 and introduced the Specification Curve Analysis to us in the seminar on research methods.

Martin Andresen from University of Oslo who made the {browse "https://github.com/martin-andresen/speccurve":{cmd:speccurve}} open-sourced on GitHub.

Hans Sievertsen from University of Bristol who wrote a {browse "https://github.com/hhsievertsen/speccurve":specurve demo}.

{marker author}{...}
{title:Author}

{browse "https://mingze-gao.com":Mingze Gao} from the Macquarie University.

{marker note}{...}
{title:Note}

This version of {cmd:specurve} has removed Python dependency. 
