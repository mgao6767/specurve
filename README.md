# specurve

`specurve` is a Stata command for [Specification Curve Analysis](https://mingze-gao.com/posts/specification-curve-analysis/).

## Installation

Run the following command in Stata:

```stata
net install specurve, from("https://raw.githubusercontent.com/mgao6767/specurve/master") replace
```

## Example usage & output

```stata
. use "http://www.stata-press.com/data/r13/nlswork.dta", clear
(National Longitudinal Survey.  Young Women 14-26 years of age in 1968)

. copy "https://mingze-gao.com/specurve/example_config_nlswork_1.yml" ., replace

. specurve using example_config_nlswork_1.yml, width(2) height(2.5) relativesize(0.5) saving(specurve_demo)
[specurve] 22:11:02 - 40 total specifications to estimate.
[specurve] 22:11:02 - Estimating model 1 of 40
  ...
[specurve] 22:11:04 - Estimating model 40 of 40
[specurve] 22:11:04 - 37 out of 40 models have point estimates significant at 1% level.
[specurve] 22:11:04 - 40 out of 40 models have point estimates significant at 5% level.
[specurve] 22:11:04 - Plotting specification curve...
(file specurve_demo.gph saved)
[specurve] 22:11:04 - Completed.
```

![example1](https://github.com/mgao6767/specurve/raw/main/images/example1.png)

Check `help specurve` in Stata for a step-by-step guide.

## Syntax

**specurve** using _filename_, [**w**idth(real) **h**eight(real) realativesize(real) scale(real) title(string) saving(name) name(string) **desc**ending **out**put **b**enchmark(real)]

### Options

| options            | Description                                                                      |
| ------------------ | -------------------------------------------------------------------------------- |
| **w**idth(real)    | set width of the specification curve plot.                                       |
| **h**eight(real)   | set height of the specification curve plot.                                      |
| relativesize(real) | set the size of coefficients panel relative to the entire plot. Defaults to 0.6. |
| scale(real)        | resize text, markers, and line widths.                                           |
| title(string)      | set graph title.                                                                 |
| saving(name)       | save graph as name.                                                              |
| name(string)       | set graph title as string.                                                       |
| **desc**ending     | plot coefficients in descending order.                                           |
| **out**put         | display all regression outputs.                                                  |
| **b**enchmark      | set the benchmark level. Defaults to 0.                                          |

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
