# Compute average marginal effects

`sim_ame()` is a wrapper for [`sim_apply()`](sim_apply.md) that computes
average marginal effects, the average effect of changing a single
variable from one value to another (i.e., from one category to another
for categorical variables or a tiny change for continuous variables).

## Usage

``` r
sim_ame(
  sim,
  var,
  subset = NULL,
  by = NULL,
  contrast = NULL,
  outcome = NULL,
  type = NULL,
  eps = 1e-05,
  verbose = TRUE,
  cl = NULL,
  ...
)

# S3 method for class 'clarify_ame'
print(x, digits = 4L, max.ests = 6L, ...)
```

## Arguments

- sim:

  a `clarify_sim` object; the output of a call to [`sim()`](sim.md) or
  [`misim()`](misim.md).

- var:

  either the names of the variables for which marginal effects are to be
  computed or a named list containing the values the variables should
  take. See Details.

- subset:

  optional; a vector used to subset the data used to compute the
  marginal effects. This will be evaluated within the original dataset
  used to fit the model using
  [`subset()`](https://rdrr.io/r/base/subset.html), so nonstandard
  evaluation is allowed.

- by:

  a one-sided formula or character vector containing the names of
  variables for which to stratify the estimates. Each quantity will be
  computed within each level of the complete cross of the variables
  specified in `by`.

- contrast:

  a string containing the name of a contrast between the average
  marginal means when the variable named in `var` is categorical and
  takes on two values. Allowed options include `"diff"` for the
  difference in means (also `"rd"`), `"rr"` for the risk ratio (also
  `"irr"`), `"log(rr):` for the log risk ratio (also `"log(irr)"`),
  `"sr"` for the survival ratio, `"log(sr):` for the log survival ratio,
  `"srr"` for the switch relative risk (also `"grrr"`), `"or"` for the
  odds ratio, `"log(or)"` for the log odds ratio, and `"nnt"` for the
  number needed to treat. These options are not case sensitive, but the
  parentheses must be included if present.

- outcome:

  a string containing the name of the outcome or outcome level for
  multivariate (multiple outcomes) or multi-category outcomes. Ignored
  for univariate (single outcome) and binary outcomes.

- type:

  a string containing the type of predicted values (e.g., the link or
  the response). Passed to
  [`marginaleffects::get_predict()`](https://marginaleffects.com/man/r/get_predict.html)
  and eventually to [`predict()`](https://rdrr.io/r/stats/predict.html)
  in most cases. The default and allowable option depend on the type of
  model supplied, but almost always corresponds to the response scale
  (e.g., predicted probabilities for binomial models).

- eps:

  when the variable named in `var` is continuous, the value by which to
  change the variable values to approximate the derivative. See Details.

- verbose:

  `logical`; whether to display a text progress bar indicating progress
  and estimated time remaining for the procedure. Default is `TRUE`.

- cl:

  a cluster object created by
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html),
  or an integer to indicate the number of child-processes (integer
  values are ignored on Windows) for parallel evaluations. See
  [`pbapply::pblapply()`](https://peter.solymos.org/pbapply/reference/pbapply.html)
  for details. If `NULL`, no parallelization will take place.

- ...:

  for `sim_ame()`, additional arguments passed to
  [`marginaleffects::get_predict()`](https://marginaleffects.com/man/r/get_predict.html)
  (and eventually to
  [`predict()`](https://rdrr.io/r/stats/predict.html)) to compute
  predictions. For [`print()`](https://rdrr.io/r/base/print.html),
  ignored.

- x:

  a `clarify_ame` object.

- digits:

  the minimum number of significant digits to be used; passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

- max.ests:

  the maximum number of estimates to display.

## Value

A `clarify_ame` object, which inherits from `clarify_est` and is similar
to the output of [`sim_apply()`](sim_apply.md), with the additional
attributes `"var"` containing the variable values specified in `var` and
`"by"` containing the names of the variables specified in `by` (if any).
The average adjusted predictions will be named `E[Y({v})]`, where `{v}`
is replaced with the values the variables named in `var` take on. The
average marginal effect for a continuous `var` will be named
`E[dY/d({x})]` where `{x}` is replaced with `var`. When `by` is
specified, the average adjusted predictions will be named
`E[Y({v})|{b}]` and the average marginal effect `E[dY/d({x})|{b}]` where
`{b}` is a comma-separated list of of values of the `by` variables at
which the quantity is computed. See examples.

## Details

`sim_ame()` computes average adjusted predictions or average marginal
effects depending on which variables are named in `var` and how they are
specified. Canonically, `var` should be specified as a named list with
the value(s) each variable should be set to. For example, specifying
`var = list(x1 = 0:1)` computes average adjusted predictions setting
`x1` to 0 and 1. Specifying a variable's values as `NULL`, e.g.,
`list(x1 = NULL)`, is equivalent to requesting average adjusted
predictions at each unique value of the variable when that variable is
binary or a factor or character and requests the average marginal effect
of that variable otherwise. Specifying an unnamed entry in the list with
a string containing the value of that variable, e.g., `list("x1")` is
equivalent to specifying `list(x1 = NULL)`. Similarly, supplying a
vector with the names of the variables is equivalent to specifying a
list, e.g., `var = "x1"` is equivalent to `var = list(x1 = NULL)`.

Multiple variables can be supplied to `var` at the same time to set the
corresponding variables to those values. If all values are specified
directly or the variables are categorical, e.g.,
`list(x1 = 0:1, x2 = c(5, 10))`, this computes average adjusted
predictions at each combination of the supplied variables. If any one
variable's values is specified as `NULL` and the variable is continuous,
the average marginal effect of that variable will be computed with the
other variables set to their corresponding combinations. For example, if
`x2` is a continuous variable, specifying
`var = list(x1 = 0:1, x2 = NULL)` requests the average marginal effect
of `x2` computed first setting `x1` to 0 and then setting `x1` to 1. The
average marginal effect can only be computed for one variable at a time.

Below are some examples of specifications and what they request,
assuming `x1` is a binary variable taking on values of 0 and 1 and `x2`
is a continuous variable:

- `list(x1 = 0:1)`, `list(x1 = NULL)`, `list("x1")`, `"x1"` – the
  average adjusted predictions setting `x1` to 0 and to 1

- `list(x2 = NULL)`, `list("x2")`, `"x2"` – the average marginal effect
  of `x2`

- `list(x2 = c(5, 10))` – the average adjusted predictions setting `x2`
  to 5 and to 10

- `list(x1 = 0:1, x2 = c(5, 10))`, `list("x1", x2 = c(5, 10))` – the
  average adjusted predictions setting `x1` and `x2` in a full cross of
  0, 1 and 5, 10, respectively (e.g., (0, 5), (0, 10), (1, 5), and (1,
  10))

- `list(x1 = 0:1, "x2")`, `list("x1", "x2")`, `c("x1", "x2")` – the
  average marginal effects of `x2` setting `x1` to 0 and to 1

The average adjusted prediction is the average predicted outcome value
after setting all units' value of a variable to a specified level. (This
quantity has several names, including the average potential outcome,
average marginal mean, and standardized mean). When exactly two average
adjusted predictions are requested, a contrast between them can be
requested by supplying an argument to `contrast` (see Effect Measures
section below). Contrasts can be manually computed using
[`transform()`](https://rdrr.io/r/base/transform.html) afterward as
well; this is required when multiple average adjusted predictions are
requested (i.e., because a single variable was supplied to `var` with
more than two levels or a combination of multiple variables was
supplied).

A marginal effect is the instantaneous rate of change corresponding to
changing a unit's observed value of a variable by a tiny amount and
considering to what degree the predicted outcome changes. The ratio of
the change in the predicted outcome to the change in the value of the
variable is the marginal effect; these are averaged across the sample to
arrive at an average marginal effect. The "tiny amount" used is `eps`
times the standard deviation of the focal variable.

The difference between using `by` or `subset` vs. `var` is that `by` and
`subset` subset the data when computing the requested quantity, whereas
`var` sets the corresponding variable to given a value for all units.
For example, using `by = ~v` computes the quantity of interest
separately for each subset of the data defined by `v`, whereas setting
`var = list(., "v")` computes the quantity of interest for all units
setting their value of `v` to its unique values. The resulting
quantities have different interpretations. Both `by` and `var` can be
used simultaneously.

### Effect measures

The effect measures specified in `contrast` are defined below. Typically
only `"diff"` is appropriate for continuous outcomes and `"diff"` or
`"irr"` are appropriate for count outcomes; the rest are appropriate for
binary outcomes. For a focal variable with two levels, `0` and `1`, and
an outcome `Y`, the average marginal means will be denoted in the below
formulas as `E[Y(0)]` and `E[Y(1)]`, respectively.

|                  |                                 |                                             |
|------------------|---------------------------------|---------------------------------------------|
| `contrast`       | **Description**                 | **Formula**                                 |
| `"diff"`/`"rd"`  | Mean/risk difference            | `E[Y(1)] - E[Y(0)]`                         |
| `"rr"`/`"irr"`   | Risk ratio/incidence rate ratio | `E[Y(1)] / E[Y(0)]`                         |
| `"sr"`           | Survival ratio                  | `(1 - E[Y(1)]) / (1 - E[Y(0)])`             |
| `"srr"`/`"grrr"` | Switch risk ratio               | `1 - sr` if `E[Y(1)] > E[Y(0)]`             |
|                  |                                 | `rr - 1` if `E[Y(1)] < E[Y(0)]`             |
|                  |                                 | `0` otherwise                               |
| `"or"`           | Odds ratio                      | `O[Y(1)] / O[Y(0)]`                         |
|                  |                                 | where `O[Y(.)]` = `E[Y(.)] / (1 - E[Y(.)])` |
| `"nnt"`          | Number needed to treat          | `1 / rd`                                    |

The `log(.)` versions are defined by taking the
[`log()`](https://rdrr.io/r/base/Log.html) (natural log) of the
corresponding effect measure.

## See also

[`sim_apply()`](sim_apply.md), which provides a general interface to
computing any quantities for simulation-based inference;
[`plot.clarify_est()`](summary.clarify_est.md) for plotting the output
of a call to `sim_ame()`;
[`summary.clarify_est()`](summary.clarify_est.md) for computing p-values
and confidence intervals for the estimated quantities.

[`marginaleffects::avg_predictions()`](https://marginaleffects.com/man/r/predictions.html),
[`marginaleffects::avg_comparisons()`](https://marginaleffects.com/man/r/comparisons.html)
and
[`marginaleffects::avg_slopes()`](https://marginaleffects.com/man/r/slopes.html)
for delta method-based implementations of computing average marginal
effects.

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

# Average marginal effect of `age`
est <- sim_ame(s, var = "age", verbose = FALSE)
summary(est)
#>              Estimate    2.5 %   97.5 %
#> E[dY/d(age)] -0.00695 -0.01008 -0.00316

# Contrast between average adjusted predictions
# for `treat`
est <- sim_ame(s, var = "treat", contrast = "rr",
               verbose = FALSE)
summary(est)
#>         Estimate 2.5 % 97.5 %
#> E[Y(0)]    0.743 0.688  0.783
#> E[Y(1)]    0.810 0.748  0.857
#> RR         1.090 0.968  1.200

# Average adjusted predictions for `race`; need to follow up
# with contrasts for specific levels
est <- sim_ame(s, var = "race", verbose = FALSE)

est <- transform(est,
                 `RR(h,b)` = `E[Y(hispan)]` / `E[Y(black)]`)

summary(est)
#>              Estimate 2.5 % 97.5 %
#> E[Y(black)]     0.706 0.630  0.754
#> E[Y(hispan)]    0.832 0.734  0.885
#> E[Y(white)]     0.800 0.746  0.836
#> RR(h,b)         1.178 1.014  1.360

# Average adjusted predictions for `treat` within levels of
# `married`, first using `subset` and then using `by`
est0 <- sim_ame(s, var = "treat", subset = married == 0,
                contrast = "rd", verbose = FALSE)
names(est0) <- paste0(names(est0), "|married=0")
est1 <- sim_ame(s, var = "treat", subset = married == 1,
                contrast = "rd", verbose = FALSE)
names(est1) <- paste0(names(est1), "|married=1")

summary(cbind(est0, est1))
#>                   Estimate   2.5 %  97.5 %
#> E[Y(0)]|married=0   0.7241  0.6562  0.7810
#> E[Y(1)]|married=0   0.7952  0.7299  0.8469
#> RD|married=0        0.0711 -0.0273  0.1543
#> E[Y(0)]|married=1   0.7697  0.7211  0.8202
#> E[Y(1)]|married=1   0.8308  0.7501  0.8818
#> RD|married=1        0.0610 -0.0235  0.1231

est <- sim_ame(s, var = "treat", by = ~married,
               contrast = "rd", verbose = FALSE)

est
#> A <clarify_est> object (from `sim_ame()`)
#>  - Average adjusted predictions for `treat`
#>    - within levels of `married`
#>  - 100 simulated values
#>  - 6 quantities estimated
#>                  
#>  E[Y(0)|0] 0.7241
#>  E[Y(1)|0] 0.7952
#>  RD[0]     0.0711
#>  E[Y(0)|1] 0.7697
#>  E[Y(1)|1] 0.8308
#>  RD[1]     0.0610
summary(est)
#>           Estimate   2.5 %  97.5 %
#> E[Y(0)|0]   0.7241  0.6562  0.7810
#> E[Y(1)|0]   0.7952  0.7299  0.8469
#> RD[0]       0.0711 -0.0273  0.1543
#> E[Y(0)|1]   0.7697  0.7211  0.8202
#> E[Y(1)|1]   0.8308  0.7501  0.8818
#> RD[1]       0.0610 -0.0235  0.1231

# Average marginal effect of `age` within levels of
# married*race
est <- sim_ame(s, var = "age", by = ~married + race,
               verbose = FALSE)
est
#> A <clarify_est> object (from `sim_ame()`)
#>  - Average marginal effect of `age`
#>    - within levels of `married` and `race`
#>  - 100 simulated values
#>  - 6 quantities estimated
#>                                 
#>  E[dY/d(age)|0,black]  -0.007950
#>  E[dY/d(age)|0,hispan] -0.005600
#>  E[dY/d(age)|0,white]  -0.006626
#>  E[dY/d(age)|1,black]  -0.008058
#>  E[dY/d(age)|1,hispan] -0.005498
#>  E[dY/d(age)|1,white]  -0.006304
summary(est, null = 0)
#>                       Estimate    2.5 %   97.5 % P-value    
#> E[dY/d(age)|0,black]  -0.00795 -0.01171 -0.00372  <2e-16 ***
#> E[dY/d(age)|0,hispan] -0.00560 -0.00923 -0.00236  <2e-16 ***
#> E[dY/d(age)|0,white]  -0.00663 -0.00941 -0.00278  <2e-16 ***
#> E[dY/d(age)|1,black]  -0.00806 -0.01181 -0.00385  <2e-16 ***
#> E[dY/d(age)|1,hispan] -0.00550 -0.00946 -0.00236  <2e-16 ***
#> E[dY/d(age)|1,white]  -0.00630 -0.00963 -0.00276  <2e-16 ***
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# Comparing AMEs between married and unmarried for
# each level of `race`
est_diff <- est[4:6] - est[1:3]
names(est_diff) <- paste0("AME_diff|", levels(lalonde$race))
summary(est_diff)
#>                  Estimate     2.5 %    97.5 %
#> AME_diff|black  -0.000108 -0.000827  0.001258
#> AME_diff|hispan  0.000102 -0.000965  0.001716
#> AME_diff|white   0.000323 -0.000840  0.001768

# Average adjusted predictions at a combination of `treat`
# and `married`
est <- sim_ame(s, var = c("treat", "married"),
               verbose = FALSE)
est
#> A <clarify_est> object (from `sim_ame()`)
#>  - Average adjusted predictions for `treat` and `married`
#>  - 100 simulated values
#>  - 4 quantities estimated
#>                  
#>  E[Y(0,0)] 0.7374
#>  E[Y(1,0)] 0.8055
#>  E[Y(0,1)] 0.7518
#>  E[Y(1,1)] 0.8171

# Average marginal effect of `age` setting `married` to 1
est <- sim_ame(s, var = list("age", married = 1),
               verbose = FALSE)
```
