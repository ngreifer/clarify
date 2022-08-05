
<!-- README.md is generated from README.Rmd. Please edit that file -->

# simbased

<!-- badges: start -->
<!-- badges: end -->

`simbased` implements simulation-based inference as an alternative to
the delta method for computing functions of model parameters, such as
marginal effects.

## Installation

You can install the development version of `simbased` from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("ngreifer/simbased")
```

## Example

Below is an example of performing g-computation for the ATT after
logistic regression to compute the marginal risk ratio and its
confidence interval:

``` r
library(simbased)

data("lalonde", package = "MatchIt")

fit <- glm(I(re78 == 0) ~ treat * (age + educ + race + married + nodegree + re74 + re75),
           data = lalonde, family = binomial)

set.seed(123)
sim_coefs <- sim(fit)

sim_est <- sim_apply(sim_coefs, function(fit) {
  d <- subset(lalonde, treat == 1)
  d$treat <- 1
  p1 <- mean(predict(fit, newdata = d, type = "response"))
  d$treat <- 0
  p0 <- mean(predict(fit, newdata = d, type = "response"))
  c(`E[Y(0)]` = p0, `E[Y(1)]` = p1, RR = p1 / p0)
}, verbose = FALSE)

summary(sim_est, null = c(NA, NA, 1))
#>         Estimate CI 2.5 % CI 97.5 % P-value
#> E[Y(0)]    0.294    0.220     0.388       .
#> E[Y(1)]    0.243    0.209     0.364       .
#> RR         0.826    0.646     1.411    0.79
sim_plot(sim_est)
```

<img src="man/figures/README-example-1.png" width="80%" />

We could have used `marginaleffects`, which uses the delta method
instead:

``` r
# Marginal risk ratio ATT, delta method-based
marginaleffects::comparisons(fit, variables = list(treat = 0:1),
                             newdata = subset(lalonde, treat == 1),
                             transform_pre = "lnratioavg") |>
  summary(transform_avg = exp)
#>                   treat Effect Pr(>|z|)  2.5 % 97.5 %
#> 1 ln(mean(1) / mean(0)) 0.8261  0.32119 0.5664  1.205
#> 
#> Model type:  glm 
#> Prediction type:  response 
#> Average-transformation:
```

The simulation-based confidence intervals are a bit wider, reflecting
that the delta method may be a poor approximation.

`simbased` provides a shortcut for computing average marginal effects
and comparisons between average adjusted predictions, `sim_ame()`, which
is essentially a wrapper for `sim_apply()` with extra processing. We can
compute the marginal risk ratio below:

``` r
# Marginal risk ratio ATT, simulation-based
sim_est <- sim_ame(sim_coefs, var = "treat", subset = treat == 1,
                   contrast = "RR", verbose = FALSE)

summary(sim_est, null = c(NA, NA, 1))
#>         Estimate CI 2.5 % CI 97.5 % P-value
#> E[Y(0)]    0.294    0.220     0.388       .
#> E[Y(1)]    0.243    0.209     0.364       .
#> RR         0.826    0.646     1.411    0.79
```

We can also use `simbased` to compute predictions and first differences
at set and typical values of the predictors, mimicking the functionality
of `Zelig`’s `setx()` and `setx1()` functions, using `sim_setx()`:

``` r
# Predictions across age and treat at typical values
# of the other predictors
sim_est <- sim_setx(sim_coefs, x = list(age = 20:50, treat = 0:1),
                    verbose = FALSE)

setx_plot(sim_est)
```

<img src="man/figures/README-unnamed-chunk-4-1.png" width="80%" />

`simbased` offers parallel processing for all estimation functions to
speed up computation.

The methodology of simulation-based inference is described in King,
Tomz, and Wittenberg (2000).

King, G., Tomz, M., & Wittenberg, J. (2000). Making the Most of
Statistical Analyses: Improving Interpretation and Presentation.
*American Journal of Political Science*, 44(2), 347–361.
<https://doi.org/10.2307/2669316>
