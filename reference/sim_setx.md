# Compute predictions and first differences at set values

`sim_setx()` is a wrapper for [`sim_apply()`](sim_apply.md) that
computes predicted values of the outcome at specified values of the
predictors, sometimes called marginal predictions. One can also compute
the difference between two marginal predictions (the "first
difference"). Although any function that accepted `clarify_est` objects
can be used with `sim_setx()` output objects, a special plotting
function, [`plot.clarify_setx()`](plot.clarify_setx.md), can be used to
plot marginal predictions.

## Usage

``` r
sim_setx(
  sim,
  x = list(),
  x1 = list(),
  outcome = NULL,
  type = NULL,
  verbose = interactive(),
  cl = NULL,
  ...
)

# S3 method for class 'clarify_setx'
print(x, digits = 4L, max.ests = 6L, ...)
```

## Arguments

- sim:

  a `<clarify_sim>` object; the output of a call to [`sim()`](sim.md) or
  [`misim()`](misim.md).

- x:

  a data frame containing a reference grid of predictor values or a
  named list of values each predictor should take defining such a
  reference grid, e.g., `list(v1 = 1:4, v2 = c("A", "B"))`. Any omitted
  predictors are fixed at a "typical" value. See Details. When `x1` is
  specified, `x` should identify a single reference unit.

  For [`print()`](https://rdrr.io/r/base/print.html), a `<clarify_setx>`
  object.

- x1:

  a data.frame or named list of the value each predictor should take to
  compute the first difference from the predictor combination specified
  in `x`. `x1` can only identify a single unit. See Details.

- outcome:

  a string containing the name of the outcome or outcome level for
  multivariate (multiple outcomes) or multi-category outcomes. Ignored
  for univariate (single outcome) and binary outcomes.

- type:

  a string containing the type of predicted values (e.g., the link or
  the response). Passed to
  [`marginaleffects::get_predict()`](https://rdrr.io/pkg/marginaleffects/man/get_predict.html)
  and eventually to [`predict()`](https://rdrr.io/r/stats/predict.html)
  in most cases. The default and allowable option depend on the type of
  model supplied, but almost always corresponds to the response scale
  (e.g., predicted probabilities for binomial models).

- verbose:

  `logical`; whether to display a text progress bar indicating progress
  and estimated time remaining for the procedure. Default is `TRUE` for
  interactive sessions and `FALSE` otherwise.

- cl:

  a cluster object created by
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html),
  or an integer to indicate the number of child-processes (integer
  values are ignored on Windows) for parallel evaluations. See
  [`pbapply::pblapply()`](https://peter.solymos.org/pbapply/reference/pbapply.html)
  for details. If `NULL`, no parallelization will take place.

- ...:

  for `sim_setx()`, additional arguments passed to
  [`marginaleffects::get_predict()`](https://rdrr.io/pkg/marginaleffects/man/get_predict.html)
  (and eventually to
  [`predict()`](https://rdrr.io/r/stats/predict.html)) to compute
  predictions. For [`print()`](https://rdrr.io/r/base/print.html),
  ignored.

- digits:

  the minimum number of significant digits to be used; passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

- max.ests:

  the maximum number of estimates to display.

## Value

A `<clarify_setx>` object, which inherits from `<clarify_est>` and is
similar to the output of [`sim_apply()`](sim_apply.md), with the
following additional attributes:

- `"setx"` - a data frame containing the values at which predictions are
  to be made

- `"fd"` - whether or not the first difference is to be computed; set to
  `TRUE` if `x1` is specified and `FALSE` otherwise

## Details

When `x` is a named list of predictor values, they will be crossed to
form a reference grid for the marginal predictions. Any predictors not
set in `x` are assigned their "typical" value, which, for factor,
character, logical, and binary variables is the mode, for numeric
variables is the mean, and for ordered variables is the median. These
values can be seen in the `"setx"` attribute of the output object. If
`x` is empty, a prediction will be made at a point corresponding to the
typical value of every predictor. Estimates are identified (in
[`summary()`](https://rdrr.io/r/base/summary.html), etc.) only by the
variables that differ across predictions.

When `x1` is supplied, the first difference is computed, which here is
considered as the difference between two marginal predictions. One
marginal prediction must be specified in `x` and another, ideally with a
single predictor changed, specified in `x1`.

## See also

- [`sim_apply()`](sim_apply.md), which provides a general interface to
  computing any quantities for simulation-based inference.

- [`plot.clarify_setx()`](plot.clarify_setx.md) for plotting the output
  of a call to `sim_setx()`.

- [`summary.clarify_est()`](summary.clarify_est.md) for computing
  p-values and confidence intervals for the estimated quantities.

- [`marginaleffects::predictions()`](https://rdrr.io/pkg/marginaleffects/man/predictions.html)
  and
  [`marginaleffects::comparisons()`](https://rdrr.io/pkg/marginaleffects/man/comparisons.html)
  for delta method-based implementations of computing predicted values
  and first differences.

## Examples

``` r
data("lalonde", package = "MatchIt")

fit <- lm(re78 ~ treat + age + educ + married + race + re74,
          data = lalonde)

# Simulate coefficients
set.seed(123)
s <- sim(fit, n = 100)

# Predicted values at specified values of values, typical
# values for other predictors
est <- sim_setx(s, x = list(treat = 0:1,
                            re74 = c(0, 10000)))
summary(est)
#>                         Estimate 2.5 % 97.5 %
#> treat = 0, re74 = 0         4771  3709   5771
#> treat = 1, re74 = 0         6389  4561   8040
#> treat = 0, re74 = 10000     8353  6939   9306
#> treat = 1, re74 = 10000     9971  8298  11631
plot(est)


# Predicted values at specified grid of values, typical
# values for other predictors
est <- sim_setx(s, x = list(age = c(20, 25, 30, 35),
                            married = 0:1))
summary(est)
#>                       Estimate 2.5 % 97.5 %
#> age = 20, married = 0     6377  5211   7464
#> age = 25, married = 0     6395  5349   7243
#> age = 30, married = 0     6413  5472   7319
#> age = 35, married = 0     6431  5410   7561
#> age = 20, married = 1     7066  5904   8412
#> age = 25, married = 1     7084  6147   8234
#> age = 30, married = 1     7102  6356   8314
#> age = 35, married = 1     7120  6284   8343
plot(est)


# First differences of treat at specified value of
# race, typical values for other predictors
est <- sim_setx(s, x = data.frame(treat = 0, race = "hispan"),
                x1 = data.frame(treat = 1, race = "hispan"))
summary(est)
#>           Estimate   2.5 %  97.5 %
#> treat = 0   7053.6  5340.1  8589.0
#> treat = 1   8671.5  6883.4 10666.5
#> FD          1617.9   -45.8  2605.4
plot(est)
```
