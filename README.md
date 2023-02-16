# specurve

`specurve` is a Stata command for [Specification Curve Analysis](https://mingze-gao.com/posts/specification-curve-analysis/).

## Installation

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

```stata
. specurve using example_config_nlswork_reghdfe.yml, saving(specurve_demo)
```

The output is

```stata
[specurve] 10:18:11 - 72 total specifications to estimate.
[specurve] 10:18:11 - Estimating model 1 of 72
  ...
[specurve] 10:18:17 - Estimating model 72 of 72
[specurve] 10:18:18 - 69 out of 72 models have point estimates significant at 1% level.
[specurve] 10:18:18 - 72 out of 72 models have point estimates significant at 5% level.
[specurve] 10:18:18 - Results saved in frame. Use frame change specurve to check. frame change default to restore.
[specurve] 10:18:18 - Plotting specification curve...
(file specurve_demo.gph saved)
[specurve] 10:18:19 - Completed.
```

![example_reghdfe](https://github.com/mgao6767/specurve/raw/main/images/example_reghdfe.png)

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

**specurve** using _filename_, [**w**idth(_real_) **h**eight(_real_) realativesize(_real_) scale(_real_) title(_string_) saving(_name_) name(_string_) **desc**ending outcmd **out**put **b**enchmark(_real_) cmd(_name_)]

### Options

| options              | Description                                                                                              |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| **w**idth(_real_)    | set width of the specification curve plot.                                                               |
| **h**eight(_real_)   | set height of the specification curve plot.                                                              |
| relativesize(_real_) | set the size of coefficients panel relative to the entire plot. Defaults to 0.6.                         |
| scale(_real_)        | resize text, markers, and line widths.                                                                   |
| title(_string_)      | set graph title.                                                                                         |
| saving(name)         | save graph as name.                                                                                      |
| name(_string_)       | set graph title as string.                                                                               |
| **desc**ending       | plot coefficients in descending order.                                                                   |
| outcmd               | display the full regression command.                                                                     |
| **out**put           | display all regression outputs.                                                                          |
| **b**enchmark        | set the benchmark level. Defaults to 0.                                                                  |
| cmd(_name_)          | set the command used to estimate models. Defaults to `reghdfe`. Can be one of `reghdfe` and `ivreghdfe`. |

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

If there's any issue (likely), please contact me at [mingze.gao@sydney.edu.au](mailto:mingze.gao@sydney.edu.au)
