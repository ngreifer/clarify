# Plot marginal predictions from `sim_setx()`

`plot.clarify_sext()` plots the output of [`sim_setx()`](sim_setx.md),
providing graphics similar to those of
[`plot.clarify_est()`](summary.clarify_est.md) but with features
specifically for plot marginal predictions. For continues predictors,
this is a plot of the marginal predictions and their confidence bands
across levels of the predictor. Otherwise, this is is a plot of
simulated sampling distribution of the marginal predictions.

## Usage

``` r
# S3 method for class 'clarify_setx'
plot(
  x,
  var = NULL,
  ci = TRUE,
  level = 0.95,
  method = "quantile",
  reference = FALSE,
  simultaneous = FALSE,
  ...
)
```

## Arguments

- x:

  a `<clarify_est>` object resulting from a call to
  [`sim_setx()`](sim_setx.md).

- var:

  the name of the focal varying predictor, i.e., the variable to be on
  the x-axis of the plot. All other variables with varying set values
  will be used to color the resulting plot. See Details. Ignored if no
  predictors vary or if only one predictor varies in the reference grid
  or if `x1` was specified in [`sim_setx()`](sim_setx.md). If not set,
  will use the predictor with the greatest number of unique values
  specified in the reference grid.

- ci:

  `logical`; whether to display confidence intervals or bands for the
  estimates. Default is `TRUE`.

- level:

  the confidence level desired. Default is .95 for 95% confidence
  intervals.

- method:

  the method used to compute confidence intervals or bands. Can be
  `"wald"` to use a Normal approximation or `"quantile"` to use the
  simulated sampling distribution (default). See
  [`summary.clarify_est()`](summary.clarify_est.md) for details.
  Abbreviations allowed.

- reference:

  `logical`; whether to overlay a normal density reference distribution
  over the plots. Default is `FALSE`. Ignored when variables other than
  the focal varying predictor vary.

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

A `<ggplot>` object.

## Details

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) creates one of
two kinds of plots depending on how the reference grid was specified in
the call to [`sim_setx()`](sim_setx.md) and what `var` is set to. When
the focal varying predictor (i.e., the one set in `var`) is numeric and
takes on three or more unique values in the reference grid, the produced
plot is a line graph displaying the value of the marginal prediction
(denoted as `E[Y|X]`) across values of the focal varying predictor, with
confidence bands displayed when `ci = TRUE`. If other predictors also
vary, lines for different values will be displayed in different colors.
These plots are produced using
[`ggplot2::geom_line()`](https://ggplot2.tidyverse.org/reference/geom_path.html)
and
[`ggplot2::geom_ribbon()`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)

When the focal varying predictor is a factor or character or only takes
on two or fewer values in the reference grid, the produced plot is a
density plot of the simulated predictions, similar to the plot resulting
from [`plot.clarify_est()`](summary.clarify_est.md). When other
variables vary, densities for different values will be displayed in
different colors. These plots are produced using
[`ggplot2::geom_density()`](https://ggplot2.tidyverse.org/reference/geom_density.html).

Marginal predictions are identified by the corresponding levels of the
predictors that vary. The user should keep track of whether the
non-varying predictors are set at specified or automatically set
"typical" levels.

## See also

[`summary.clarify_est()`](summary.clarify_est.md) for computing p-values
and confidence intervals for the estimated quantities.

## Examples

``` r
## See help("sim_setx") for examples
```
