# Compute an average dose-response function

`sim_adrf()` is a wrapper for [`sim_apply()`](sim_apply.md) that
computes average dose-response functions (ADRFs) and average marginal
effect functions (AMEFs). An ADRF describes the relationship between
values a focal variable can take and the expected value of the outcome
were all units to be given each value of the variable. An AMEF describes
the relationship between values a focal variable can take and the
derivative of ADRF at each value.

## Usage

``` r
sim_adrf(
  sim,
  var,
  subset = NULL,
  by = NULL,
  contrast = "adrf",
  at = NULL,
  n = 21,
  outcome = NULL,
  type = NULL,
  eps = 1e-05,
  verbose = interactive(),
  cl = NULL,
  ...
)

# S3 method for class 'clarify_adrf'
print(x, digits = 4L, max.ests = 6L, ...)
```

## Arguments

- sim:

  a `<clarify_sim>` object; the output of a call to [`sim()`](sim.md) or
  [`misim()`](misim.md).

- var:

  the name of a variable for which the ADRF or AMEF is to be computed.
  This variable must be present in the model supplied to
  [`sim()`](sim.md) and must be a numeric variable taking on more than
  two unique values.

- subset:

  optional; a vector used to subset the data used to compute the ADRF or
  AMEF. This will be evaluated within the original dataset used to fit
  the model using [`subset()`](https://rdrr.io/r/base/subset.html), so
  nonstandard evaluation is allowed.

- by:

  a one-sided formula or character vector containing the names of
  variables for which to stratify the estimates. Each quantity will be
  computed within each level of the complete cross of the variables
  specified in `by`.

- contrast:

  a string naming the type of quantity to be produced: `"adrf"` for the
  ADRF (the default) or `"amef"` for the AMEF.

- at:

  the levels of the variable named in `var` at which to evaluate the
  ADRF or AMEF. Should be a vector of numeric values corresponding to
  possible levels of `var`. If `NULL`, will be set to a range from
  slightly below the lowest observed value of `var` to slightly above
  the largest value.

- n:

  when `at = NULL`, the number of points to evaluate the ADRF or AMEF.
  Default is 21. Ignored when `at` is not `NULL`.

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

- eps:

  when `contrast = "amef"`, the value by which to shift the value of
  `var` to approximate the derivative. See Details.

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

  for `sim_adrf()`, additional arguments passed to
  [`marginaleffects::get_predict()`](https://rdrr.io/pkg/marginaleffects/man/get_predict.html)
  (and eventually to
  [`predict()`](https://rdrr.io/r/stats/predict.html)) to compute
  predictions. For [`print()`](https://rdrr.io/r/base/print.html),
  ignored.

- x:

  a `<clarify_adrf>` object.

- digits:

  the minimum number of significant digits to be used; passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

- max.ests:

  the maximum number of estimates to display.

## Value

A `<clarify_adrf>` object, which inherits from `<clarify_est>` and is
similar to the output of [`sim_apply()`](sim_apply.md), with the
additional attributes `"var"` containing the variable named in `var`,
`"by"` containing the names of the variables specified in `by` (if any),
`"at"` containing values at which the ADRF or AMEF is evaluated, and
`"contrast"` containing the argument supplied to `contrast`. For an
ADRF, the average marginal means will be named `E[Y({v})]`, where `{v}`
is replaced with the values in `at`. For an AMEF, the average marginal
effects will be named `dY/d({x})|{a}` where `{x}` is replaced with `var`
and `{a}` is replaced by the values in `at`.

## Details

The ADRF is composed of average marginal means across levels of the
focal predictor. For each level of the focal predictor, predicted values
of the outcome are computed after setting the value of the predictor to
that level, and those values of the outcome are averaged across all
units in the sample to arrive at an average marginal mean. Thus, the
ADRF represent the relationship between the "dose" (i.e., the level of
the focal predictor) and the average "response" (i.e., the outcome
variable). It is the continuous analog to the average marginal effect
computed for a binary predictor, e.g., using [`sim_ame()`](sim_ame.md).
Although inference can be at each level of the predictor or between two
levels of the predictor, typically a plot of the ADRF is the most useful
relevant quantity. These can be requested using
[`plot.clarify_adrf()`](plot.clarify_adrf.md).

The AMEF is the derivative of the ADRF; if we call the derivative of the
ADRF at each point a "treatment effect" (i.e., the rate at which the
outcome changes corresponding to a small change in the predictor, or
"treatment"), the AMEF is a function that relates the size of the
treatment effect to the level of the treatment. The shape of the AMEF is
usually of less importance than the value of the AMEF at each level of
the predictor, which corresponds to the size of the treatment effect at
the corresponding level. The AMEF is computed by computing the ADRF at
each level of the focal predictor specified in `at`, shifting the
predictor value by a tiny amount (control by `eps`), and computing the
ratio of the change in the outcome to the shift, then averaging this
value across all units. This quantity is related the the average
marginal effect of a continuous predictor as computed by
[`sim_ame()`](sim_ame.md), but rather than average these treatment
effects across all observed levels of the treatment, the AMEF is a
function evaluated at each possible level of the treatment. The "tiny
amount" used is `eps` times the standard deviation of `var`.

Note that inference on the computed quantities treats the other
variables in the model as fixed; that is, it only accounts for
model-based uncertainty, not uncertainty due to sampling.

## See also

- [`plot.clarify_adrf()`](plot.clarify_adrf.md) for plotting the ADRF or
  AMEF.

- [`sim_ame()`](sim_ame.md) for computing average marginal effects.

- [`sim_apply()`](sim_apply.md), which provides a general interface to
  computing any quantities for simulation-based inference.

- [`summary.clarify_est()`](summary.clarify_est.md) for computing
  p-values and confidence intervals for the estimated quantities.

- [`marginaleffects::avg_slopes()`](https://rdrr.io/pkg/marginaleffects/man/slopes.html)
  and
  [`marginaleffects::avg_predictions()`](https://rdrr.io/pkg/marginaleffects/man/predictions.html)
  for delta method-based implementations of computing average marginal
  effects and average marginal means.

- the [adrftools](https://CRAN.R-project.org/package=adrftools) package,
  which performs inference, testing, and visualization of the ADRF and
  AMEF.

## Examples

``` r
data("lalonde", package = "MatchIt")

# Fit the model
fit <- glm(I(re78 > 0) ~ treat + age + race +
             married + re74,
           data = lalonde, family = binomial)

# Simulate coefficients
set.seed(123)
s <- sim(fit, n = 100)

# ADRF for `age`
est <- sim_adrf(s, var = "age",
                at = seq(15, 55, length.out = 6))
est
#> A <clarify_est> object (from `sim_adrf()`)
#>  - Average dose-response function of `age`
#>  - 100 simulated values
#>  - 6 quantities estimated
#>                 
#>  E[Y(15)] 0.8443
#>  E[Y(23)] 0.7976
#>  E[Y(31)] 0.7416
#>  E[Y(39)] 0.6770
#>  E[Y(47)] 0.6052
#>  E[Y(55)] 0.5290
plot(est)


# AMEF for `age`
est <- sim_adrf(s, var = "age", contrast = "amef",
               at = seq(15, 55, length.out = 6))
est
#> A <clarify_est> object (from `sim_adrf()`)
#>  - Average marginal effect function of `age`
#>  - 100 simulated values
#>  - 6 quantities estimated
#>                           
#>  E[dY/d(age)|15] -0.005258
#>  E[dY/d(age)|23] -0.006415
#>  E[dY/d(age)|31] -0.007563
#>  E[dY/d(age)|39] -0.008575
#>  E[dY/d(age)|47] -0.009314
#>  E[dY/d(age)|55] -0.009668
summary(est)
#>                 Estimate    2.5 %   97.5 %
#> E[dY/d(age)|15] -0.00526 -0.00702 -0.00273
#> E[dY/d(age)|23] -0.00641 -0.00919 -0.00301
#> E[dY/d(age)|31] -0.00756 -0.01138 -0.00330
#> E[dY/d(age)|39] -0.00858 -0.01303 -0.00356
#> E[dY/d(age)|47] -0.00931 -0.01377 -0.00378
#> E[dY/d(age)|55] -0.00967 -0.01320 -0.00398
plot(est)


# ADRF for `age` within levels of `married`
est <- sim_adrf(s, var = "age",
                at = seq(15, 55, length.out = 6),
                by = ~married)
est
#> A <clarify_est> object (from `sim_adrf()`)
#>  - Average dose-response function of `age`
#>    - within levels of `married`
#>  - 100 simulated values
#>  - 12 quantities estimated
#>                   
#>  E[Y(15)|0] 0.8215
#>  E[Y(23)|0] 0.7694
#>  E[Y(31)|0] 0.7077
#> --- 6 rows omitted. ---
#>  E[Y(39)|1] 0.7324
#>  E[Y(47)|1] 0.6669
#>  E[Y(55)|1] 0.5948
plot(est)


## Difference between ADRFs
est_diff <- est[7:12] - est[1:6]
plot(est_diff) + ggplot2::labs(y = "Diff")
```
