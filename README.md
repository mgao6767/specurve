# specurve

Most recent update: **2023-10-27**

`specurve` is a Stata command for [Specification Curve Analysis](https://mingze-gao.com/posts/specification-curve-analysis/).

## Installation & update

Run the following command in Stata:

```stata
net install specurve, from("https://raw.githubusercontent.com/mgao6767/specurve/master") replace
```

## Example usage & output

### Setup

```stata
. use "http://www.stata-press.com/data/r13/nlswork.dta", clear
. copy "https://mingze-gao.com/specurve/example_config_nlswork_reghdfe.yml" ., replace
```

### Regressions with `reghdfe`

#### Basic usage

```stata
. specurve using example_config_nlswork_reghdfe.yml, saving(specurve_demo)
```

The output is

```stata
[specurve] 11:43:54 - 84 total specifications to estimate.
[specurve] 11:43:54 - Estimating model 1 of 84
[specurve] 11:43:54 - Estimating model 2 of 84
......
[specurve] 11:43:57 - Estimating model 84 of 84
[specurve] 11:43:57 - 81 out of 84 models have point estimates significant at 1% level.
[specurve] 11:43:57 - 84 out of 84 models have point estimates significant at 5% level.
[specurve] 11:43:57 - Plotting specification curve...
file specurve_demo.gph saved
[specurve] 11:43:58 - Completed.
[specurve] use frame change specurve to see results
[specurve] use frame change default to switch back to current frame
```

![example_reghdfe](https://github.com/mgao6767/specurve/raw/main/images/example_reghdfe.png)

#### Display options

In this example, we

- turn off the benchmark line,
- set the number of decimals to display to 4,
- set the number of y-axis ticks/labels to 8, and
- display the coefficients in descending order.

```stata
. specurve using example_config_nlswork_reghdfe.yml, nob yticks(8) rounding(.0001) desc
```

![example_reghdfe_with_options](https://github.com/mgao6767/specurve/raw/main/images/example_reghdfe_with_options.png)

### IV regressions with `ivreghdfe`

```stata
. copy "https://mingze-gao.com/specurve/example_config_nlswork_ivreghdfe.yml" ., replace
. specurve using example_config_nlswork_ivreghdfe.yml, cmd(ivreghdfe) rounding(0.01) title("IV regression with ivreghdfe")
```

![example_ivreghdfe](https://github.com/mgao6767/specurve/raw/main/images/example_ivreghdfe.png)

Check `help specurve` in Stata for a step-by-step guide.

### Post estimation

Estimation results are saved in the [frame](https://www.stata.com/manuals/dframesintro.pdf) named "specurve".

Use `frame change specurve` to check the results.

Use `frame change default` to switch back to the original dataset.

## Syntax

**specurve** using _filename_, [**w**idth(_real_) **h**eight(_real_) realativesize(_real_) scale(_real_) title(_string_) saving(_name_) name(_string_) **desc**ending outcmd **out**put **b**enchmark(_real_) **nob**enchmark **round**ing(_real_) yticks(_int_) ymin(_real_) ymax(_real_) cmd(_name_) **keepsin**gletons]

### Options

| options               | Description                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------- |
| **w**idth(_real_)     | set width of the specification curve plot.                                                               |
| **h**eight(_real_)    | set height of the specification curve plot.                                                              |
| relativesize(_real_)  | set the size of coefficients panel relative to the entire plot. Defaults to 0.6.                         |
| scale(_real_)         | resize text, markers, and line widths.                                                                   |
| title(_string_)       | set graph title.                                                                                         |
| saving(name)          | save graph as name.                                                                                      |
| name(_string_)        | set graph title as string.                                                                               |
| **desc**ending        | plot coefficients in descending order.                                                                   |
| outcmd                | display the full regression command.                                                                     |
| **out**put            | display all regression outputs.                                                                          |
| **b**enchmark(_real_) | set the benchmark level. Defaults to 0.                                                                  |
| **nob**enchmark       | turnoff the benchmark line                                                                               |
| **round**ing(_real_)  | set the rounding of y-axis labels and hence number of decimal places to display. Defaults to 0.001.      |
| yticks(_int_)         | set the number of ticks/labels to display on y-axis. Defaults to 5.                                      |
| ymin(_real_)          | set the min tick of y-axis. Default is automatically set.                                                |
| ymax(_real_)          | set the max tick of y-axis. Default is automatically set.                                                |
| cmd(_name_)           | set the command used to estimate models. Defaults to `reghdfe`. Can be one of `reghdfe` and `ivreghdfe`. |
| **keepsin**gletons    | keep singleton groups. Only useful when using `reghdfe`.                                                 |

## Update log

2023-10-27:

- Fix a bug about y-axis labels display due to early rounding.

2023-10-26:

- Added options `ymin` and `ymax` to manually specify the range of y-axix.
- Thanks to Jonas Happel from Frankfurt School of Finance & Management for suggesting the feature.

2023-07-02:

- Added an option to turn off benchmark line.
- Added an option to decide the number of ticks and labels on the y-axis.
- Thanks to John Iselin from University of Maryland for suggesting the features.

2023-06-22:

- Added a dependency check for `reghdfe` and `ivreghdfe`.
- Thanks to Brittany O'Duffy from Oxford Internet Institute at University of Oxford for identifying the bug.

2023-04-22:

- Fix a bug that mistakes the hashtag in Stata interactions (e.g., `var1#var2`) for inline comments.
- Thanks to Kenneth Shores from University of Delaware for identifying the bug and suggesting solutions.

2023-04-03:

- Preserve the order of choices in each group as specified in the configuration file.
- Allow no conditions specified in the configuration file.
- Thanks to Christopher Whaley from RAND Corp for suggesting the improvement.

2023-04-02:

- Allow `keepsingletons` option for `reghdfe`. 
- Thanks to Ken P.Y. Wang from National Taiwan University for suggesting the improvement.

2023-02-13:

- Remove Python dependencies.
- Thanks to Germán Guerra from the National Institute of Public Health (Mexico), Kausik Chaudhuri from University of Leeds for numerous installation tests which ultimately lead me to rewrite `specurve` in pure Stata.

## Troubleshooting

* **When following the help file, Stata reports error "file example_config_nlswork_1.yml could not be opened".**

This is mostly due to permission error. Stata does not have write permission to the current working directory so it cannot download the example configuration file. You can solve it by changing the working directory to somewhere else.

## Thanks to

Uri Simonsohn, Joseph Simmons and Leif D. Nelson for their paper "Specification Curve Analysis" (Nat Hum Behav, 2020, and previous working paper), first suggesting the specification curve.

Rawley Heimer from Boston College who visited our discipline in 2019 and introduced the Specification Curve Analysis to us in the seminar on research methods.

Martin Andresen from University of Oslo who wrote the [speccurve](https://github.com/martin-andresen/speccurve) and Hans Sievertsen from University of Bristol who wrote a [speccurve](https://github.com/hhsievertsen/speccurve) demo.

## Note

This Stata command was originally developed when writing my first paper, Gao, M., Leung, H., & Qiu, B. (2021) "Organization capital and executive performance incentives" at the *Journal of Banking & Finance*.

The [earlier version](https://github.com/mgao6767/specurve/tree/python) depends on Stata 16's Python integration and a range of external Python packages, which has caused many compatibility issues. 

The current version has removed Python dependency and implements everything from parsing configuration file, composing specifications, estimating models, to plotting specification curve in Stata Mata.

If there's any issue (likely), please contact me at [mingze.gao@mq.edu.au](mailto:mingze.gao@mq.edu.au)

## Used in

Rodriguez, B., Huynh, K. P., Jacho-Chávez, D. T., & Sánchez-Aragón, L. (2024). [Abstract readability: Evidence from top-5 economics journals](https://doi.org/10.1016/j.econlet.2024.111541). _Economics Letters_, 111541.
