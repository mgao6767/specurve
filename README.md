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

## Troubleshooting

* **When following the help file, Stata reports error "file example_config_nlswork_1.yml could not be opened".**

This is mostly due to permission error. Stata does not have write permission to the current working directory so it cannot download the example configuration file. You can solve it by changing the working directory to somewhere else.

## Note

This Stata command was originally developed when writing my first paper, Gao, M., Leung, H., & Qiu, B. (2021) "Organization capital and executive performance incentives" at the *Journal of Banking & Finance*.

The [earlier version](https://github.com/mgao6767/specurve/tree/python) depends on Stata 16's Python integration and a range of external Python packages, which has caused many compatibility issues. 

The current version has removed Python dependency and implements everything from parsing configuration file, composing specifications, estimating models, to plotting specification curve in Stata Mata.

If there's any issue (likely), please contact me at [mingze.gao@sydney.edu.au](mailto:mingze.gao@sydney.edu.au)
