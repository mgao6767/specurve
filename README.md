# specurve

Most recent update: **2025-02-06**

`specurve` is a Stata command for [Specification Curve Analysis](https://mingze-gao.com/posts/specification-curve-analysis/).

## Installation & update

Run the following command in Stata:

```stata
net install specurve, from("https://raw.githubusercontent.com/mgao6767/specurve/master") replace
```

> [!NOTE]
> Ensure that you've correctly installed [`reghdfe`](https://github.com/sergiocorreia/reghdfe/) and [`ivreghdfe`](https://github.com/sergiocorreia/ivreghdfe).
> Known issue is that `ivreghdfe` from `ssc` may not work.

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

In this first example, we

- turn off the benchmark line,
- set the number of decimals to display to 4,
- set the number of y-axis ticks/labels to 8, and
- display the coefficients in descending order.

```stata
. specurve using example_config_nlswork_reghdfe.yml, nob yticks(8) rounding(.0001) desc
```

![example_reghdfe_with_options](https://github.com/mgao6767/specurve/raw/main/images/example_reghdfe_with_options.png)

Given that we have only a single dependent and focal variable, it may be redundant to display dependent and focal variable in the lower panel. In this second example, we

- turn off the display of dependent variable
- turn off the display of focal variable

```stata
. specurve using example_config_nlswork_reghdfe.yml, nodependent nofocal
```

![example_reghdfe_with_options_hide_dep_focal](https://github.com/mgao6767/specurve/raw/main/images/example_reghdfe_with_options_hide_dep_focal.png)

### IV regressions with `ivreghdfe`

```stata
. copy "https://mingze-gao.com/specurve/example_config_nlswork_ivreghdfe.yml" ., replace
. specurve using example_config_nlswork_ivreghdfe.yml, cmd(ivreghdfe) rounding(0.01) title("IV regression with ivreghdfe")
```

![example_ivreghdfe](https://github.com/mgao6767/specurve/raw/main/images/example_ivreghdfe.png)

Check `help specurve` in Stata for a step-by-step guide.

### Poisson pseudo-likelihood regression with `ppmlhdfe`

`ppmlhdfe` is supported. Examples to be added.

### Advanced usage

Sometimes, we are interested in combinations of controls. We can use the `controlvariablebygroup` option to present a more concise plot. See [Issue 2](https://github.com/mgao6767/specurve/issues/2) for a related discussion.

The plot below demonstrate the difference. The left one does not set `controlvariablebygroup` and the right one does. It's obvious that if we have say 2^6=64 models, the left one needs 64 lines but the right one uses only 6 lines for showing specifications.

![example_controlvariablebygroup](https://github.com/mgao6767/specurve/raw/main/images/example_controlvariablebygroup.png)

However, to achieve this, we **MUST** make a small change in the configuration file. We need to use **"comma-followed-by-space"** style to label each control variable choice. This allows the program to parse the _combination_ of control variables that forms the prevailing model specification. By default, the program assumes the entirety of the label uniquely identifies a specification of control variables.

To produce the example, use the following code.

```stata
. copy https://mingze-gao.com/specurve/example_config_nlswork_reghdfe_2.yml ., replace
. specurve using example_config_nlswork_reghdfe_2.yml, controlvariablebygroup
```

### Post estimation

Estimation results are saved in the [frame](https://www.stata.com/manuals/dframesintro.pdf) named "specurve".

Use `frame change specurve` to check the results.

Use `frame change default` to switch back to the original dataset.

## Syntax

**specurve** using _filename_, [**w**idth(_real_) **h**eight(_real_) relativesize(_real_) scale(_real_) title(_string_) saving(_name_) name(_string_) **desc**ending outcmd **out**put **b**enchmark(_real_) **nob**enchmark **nod**ependent **nof**ocal **nofix**edeffect **noc**luster **nocond**ition noci99 noci95 **round**ing(_real_) yticks(_int_) ymin(_real_) ymax(_real_) cmd(_name_) **keepsin**gletons controlvariablebygroup]

### Options

| options                | Description                                                                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **w**idth(_real_)      | set width of the specification curve plot.                                                                                                                                                               |
| **h**eight(_real_)     | set height of the specification curve plot.                                                                                                                                                              |
| relativesize(_real_)   | set the size of coefficients panel relative to the entire plot. Defaults to 0.6.                                                                                                                         |
| scale(_real_)          | resize text, markers, and line widths.                                                                                                                                                                   |
| title(_string_)        | set graph title.                                                                                                                                                                                         |
| saving(name)           | save graph as name.                                                                                                                                                                                      |
| name(_string_)         | set graph title as string.                                                                                                                                                                               |
| **desc**ending         | plot coefficients in descending order.                                                                                                                                                                   |
| outcmd                 | display the full regression command.                                                                                                                                                                     |
| **out**put             | display all regression outputs.                                                                                                                                                                          |
| **b**enchmark(_real_)  | set the benchmark level. Defaults to 0.                                                                                                                                                                  |
| **nob**enchmark        | turnoff the benchmark line                                                                                                                                                                               |
| **nod**ependent        | turnoff the display of dependent variable.                                                                                                                                                               |
| **nof**ocal            | turnoff the display of focal variable.                                                                                                                                                                   |
| **nofix**edeffect      | turnoff the display of fixed effect.                                                                                                                                                                     |
| **noc**luster          | turnoff the display of standard error clustering.                                                                                                                                                        |
| **nocond**ition        | turnoff the display of conditions.                                                                                                                                                                       |
| noci99                 | turnoff the display of 99% confidence intervals.                                                                                                                                                         |
| noci95                 | turnoff the display of 95% confidence intervals.                                                                                                                                                         |
| **round**ing(_real_)   | set the rounding of y-axis labels and hence number of decimal places to display. Defaults to 0.001.                                                                                                      |
| yticks(_int_)          | set the number of ticks/labels to display on y-axis. Defaults to 5.                                                                                                                                      |
| ymin(_real_)           | set the min tick of y-axis. Default is automatically set.                                                                                                                                                |
| ymax(_real_)           | set the max tick of y-axis. Default is automatically set.                                                                                                                                                |
| cmd(_name_)            | set the command used to estimate models. Defaults to `reghdfe`. Can be one of `reghdfe`, `ivreghdfe` or `ppmlhdfe`.                                                                                      |
| **keepsin**gletons     | keep singleton groups. Only useful when using `reghdfe`.                                                                                                                                                 |
| controlvariablebygroup | the labels of control variables in the configuration file indicate combination of groups, instead of each indicating a distinct group. Please see the example above to better understand the difference. |

## Update log

2025-02-06:

- Remove link to auto-install missing packages (`reghdfe`, `ivreghdfe` and `ppmlhdfe`) via `ssc install`. It is recommended to follow the most updated installation guide of respective packages.
- Thanks to Leonardo Sánchez-Aragón from ESPOL for identifying the bug.

2024-03-31:

- Add support for `ppmlhdfe`. Simply use `specurve ...., cmd(ppmlhdfe)`. No additional changes needed. However, note that this version does not support the `expsure` and `offset` options in `ppmlhdfe`.
- Thanks to Leonhard Friedel from WHU Otto Beisheim School of Management for suggesting the features.

2024-03-07:

- Fix a bug of options `noci99` and `noci95` not effective.

2024-03-03:

- Add options `noci99` and `noci95` to hide the 99% and 95% confidence intervals, respectively.
- Thanks to Kausik Chaudhuri from University of Leeds for suggesting the feature.

2024-02-18:

- Allow for labels in "control variables" to indicate combination of variables, instead of each label indicating a unique specification of control variables. Fix [https://github.com/mgao6767/specurve/issues/2](https://github.com/mgao6767/specurve/issues/2).
- Improve the legend. Now it shows point estimates of different significance levels.
- Fix a typo in the help file.
- Thanks to Leonhard Friedel from WHU Otto Beisheim School of Management for suggesting the features.

2024-01-31:

- Add options to individually control what (not) to display in the lower panel. For example, `nodependent` turns off the display of dependent variable.
- Thanks to Victor van Pelt from WHU Otto Beisheim School of Management for suggesting the feature.

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

* **When following the guide, Stata reports the following error.**

```
. specurve using example_config_nlswork_ivreghdfe.yml, cmd(ivreghdfe) rounding(0.01) title("IV regression with ivreghdfe")
[specurve] 07:11:18 - 60 total specifications to estimate.
[specurve] 07:11:18 - Estimating model 1 of 60
                 stata():  3598  Stata returned error
              estimate():     -  function returned error
                  main():     -  function returned error
                 <istmt>:     -  function returned error
r(3598);
```

This is most likely due to errors related to the underlying packages used. Please uninstall `ivreghdfe` and follow its [latest installation guide](https://github.com/sergiocorreia/ivreghdfe). Chances are that you'll need to do `net install` rather than `ssc install`.


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

As far as I know, `specurve` is used in

- Iselin, J. (2024). [The Labor Supply Effects of the California Earned Income Tax Credit](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5004846). _SSRN Working Paper_.
- Zhang, L., & Wu, K. (2024). [Banking Liberalization and Analyst Forecast Accuracy](https://ssrn.com/abstract=4691259). _SSRN Working Paper_.
- Rodriguez, B., Huynh, K. P., Jacho-Chávez, D. T., & Sánchez-Aragón, L. (2024). [Abstract readability: Evidence from top-5 economics journals](https://doi.org/10.1016/j.econlet.2024.111541). _Economics Letters_, 111541.
- Gao, M., Leung, H., & Qiu, B. (2021). [Organization capital and executive performance incentives](https://doi.org/10.1016/j.jbankfin.2020.106017). _Journal of Banking & Finance_, 106017.
