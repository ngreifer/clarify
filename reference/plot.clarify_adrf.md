# Plot marginal predictions from `sim_adrf()`

`plot.clarify_adrf()` plots the output of [`sim_adrf()`](sim_adrf.md).
For the average dose-response function (ADRF, requested with
`contrast = "adrf"` in [`sim_adrf()`](sim_adrf.md)), this is a plot of
the average marginal mean of the outcome against the requested values of
the focal predictor; for the average marginal effects function (AMEF,
requested with `contrast = "amef"` in [`sim_adrf()`](sim_adrf.md)), this
is a plot of the instantaneous average marginal effect of the focal
predictor on the outcome against the requested values of the focal
predictor.

## Usage

``` r
# S3 method for class 'clarify_adrf'
plot(
  x,
  ci = TRUE,
  level = 0.95,
  method = "quantile",
  baseline = NULL,
  color = "black",
  simultaneous = FALSE,
  ...
)
```

## Arguments

- x:

  a `clarify_adrf` object resulting from a call to
  [`sim_adrf()`](sim_adrf.md).

- ci:

  `logical`; whether to display confidence bands for the estimates.
  Default is `TRUE`.

- level:

  the confidence level desired. Default is .95 for 95% confidence
  intervals.

- method:

  the method used to compute confidence bands. Can be `"wald"` to use a
  Normal approximation or `"quantile"` to use the simulated sampling
  distribution (default). See
  [`summary.clarify_est()`](summary.clarify_est.md) for details.
  Abbreviations allowed.

- baseline:

  `logical`; whether to include a horizontal line at `y = 0` on the
  plot. Default is `FALSE` for the ADRF (since 0 might not be in the
  range of the outcome) and `TRUE` for the AMEF.

- color:

  the color of the line and confidence band in the plot.

- simultaneous:

  `logical`; whether confidence bands should be simultaneous or not
  (i.e., for nominal coverage of the whole effect curve); default is
  `FALSE`, but `TRUE` is recommended. See Details at
  [`summary.clarify_est()`](summary.clarify_est.md) for details.

- ...:

  for [`plot()`](https://rdrr.io/r/graphics/plot.default.html), further
  arguments passed to
  [`ggplot2::geom_density()`](https://ggplot2.tidyverse.org/reference/geom_density.html).

## Value

A `ggplot` object.

## Details

These plots are produced using
[`ggplot2::geom_line()`](https://ggplot2.tidyverse.org/reference/geom_path.html)
and
[`ggplot2::geom_ribbon()`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html).
The confidence bands should be interpreted pointwise (i.e., they do not
account for simultaneous inference) unless `simultaneous = TRUE`.

## See also

[`summary.clarify_est()`](summary.clarify_est.md) for computing p-values
and confidence intervals for the estimated quantities.

## Examples

``` r
## See help("sim_adrf") for examples
```
