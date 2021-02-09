# specurve
 
`specurve` is a Stata command used to perform Specification Curve Analysis and generate the Specification Curve plot.

## Dependencies

`specurve` depends on Stata 16's Python integration and requires a Python version of 3.8 or above.

Python modules required:

* [`pandas`](https://pandas.pydata.org/): for basic dataset manipulation.
* [`pyyaml`](https://pyyaml.org/): for reading and parsing the YAML-formatted configuration file.
* [`plotly`](https://plotly.com/python/): for generating the specification curve plot.
* [`kaleido`](https://github.com/plotly/Kaleido): for static image export with `plotly`.

To install the required modules, try:

```
pip install pandas pyyaml plotly kaleido
```

## Installation

Download `specurve.ado` and `specurve.hlp` and put them in your personal ado folder. To find the path to your personal ado folder, type `adopath` in Stata.

## Example usage

The associated help file contains a step-by-step guide on using `specurve`. To open the help file, type `help specurve` in Stata after installation.

## Example output

![example1](https://github.com/mgao6767/specurve/raw/main/images/example1.png)

![example2](https://github.com/mgao6767/specurve/raw/main/images/example2.png)
