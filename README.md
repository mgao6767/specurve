# specurve

`specurve` is a Stata command for Specification Curve Analysis.

## Installation

Run the following command in Stata:

```Stata
net install specurve, from("https://raw.githubusercontent.com/mgao6767/specurve/master")
```

## Example usage & output

```stata
. use http://www.stata-press.com/data/r13/nlswork.dta, clear
. copy https://mingze-gao.com/specurve/example_config_nlswork_1.yml ., replace
. specurve using example_config_nlswork_1.yml
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
