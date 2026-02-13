# Transform and combine `clarify_est` objects

[`transform()`](https://rdrr.io/r/base/transform.html) modifies a
`clarify_est` object by allowing for the calculation of new quantities
from the existing quantities without re-simulating them.
[`cbind()`](https://rdrr.io/r/base/cbind.html) binds two `clarify_est`
objects together.

## Usage

``` r
# S3 method for class 'clarify_est'
transform(`_data`, ...)

# S3 method for class 'clarify_est'
cbind(..., deparse.level = 1)
```

## Arguments

- \_data:

  the `clarify_est` object to be transformed.

- ...:

  for [`transform()`](https://rdrr.io/r/base/transform.html), arguments
  in the form `name = value`, where `name` is the name of a new quantity
  to be computed and `value` is an expression that is a function of the
  existing quantities corresponding to the new quantity to be computed.
  See Details. For [`cbind()`](https://rdrr.io/r/base/cbind.html),
  `clarify_est` objects to be combined.

- deparse.level:

  ignored.

## Value

A `clarify_est` object, either with new columns added (when using
[`transform()`](https://rdrr.io/r/base/transform.html)) or combining two
`clarify_est` objects. Note that any type attributes corresponding to
the [`sim_apply()`](sim_apply.md) wrapper used (e.g.,
[`sim_ame()`](sim_ame.md)) is lost when using either function. This can
affect any helper functions (e.g.,
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)) designed to
work with the output of specific wrappers.

## Details

For [`transform()`](https://rdrr.io/r/base/transform.html), the
expression on the right side of the `=` should use the names of the
existing quantities (e.g., `` `E[Y(1)]` - `E[Y(1)]` ``), with `` ` ``
appropriately included when the quantity name include parentheses or
brackets. Alternatively, it can use indexes prefixed by `.b`, e.g.,
`.b2 - .b1`, to refer to the corresponding quantity by position. This
can aid in computing derived quantities of quantities with complicated
names. (Note that if a quantity is named something like `.b1`, it will
need to be referred to by position rather than name, as the
position-based label takes precedence). See examples. Setting an
existing value to `NULL` will remove that quantity from the object.

[`cbind()`](https://rdrr.io/r/base/cbind.html) does not rename the
quantities or check for uniqueness of the names, so it is important to
rename them yourself prior to combining the objects.

## See also

[`transform()`](https://rdrr.io/r/base/transform.html),
[`cbind()`](https://rdrr.io/r/base/cbind.html), [`sim()`](sim.md)

## Examples

``` r
data("lalonde", package = "MatchIt")

# Fit the model
fit <- lm(re78 ~ treat * (age + educ + race +
             married + re74 + re75),
           data = lalonde)

# Simulate coefficients
set.seed(123)
s <- sim(fit, n = 100)

# Average adjusted predictions for `treat` within
# subsets of `race`
est_b <- sim_ame(s, var = "treat", verbose = FALSE,
                 subset = race == "black")
est_b
#> A <clarify_est> object (from `sim_ame()`)
#>  - Average adjusted predictions for `treat`
#>  - 100 simulated values
#>  - 2 quantities estimated
#>              
#>  E[Y(0)] 4589
#>  E[Y(1)] 6148

est_h <- sim_ame(s, var = "treat", verbose = FALSE,
                 subset = race == "hispan")
est_h
#> A <clarify_est> object (from `sim_ame()`)
#>  - Average adjusted predictions for `treat`
#>  - 100 simulated values
#>  - 2 quantities estimated
#>              
#>  E[Y(0)] 7015
#>  E[Y(1)] 7183

# Compute differences between adjusted predictions
est_b <- transform(est_b,
                   diff = `E[Y(1)]` - `E[Y(0)]`)
est_b
#> A <clarify_est> object (from `sim_apply()`)
#>  - 100 simulated values
#>  - 3 quantities estimated
#>              
#>  E[Y(0)] 4589
#>  E[Y(1)] 6148
#>  diff    1559

est_h <- transform(est_h,
                   diff = `E[Y(1)]` - `E[Y(0)]`)
est_h
#> A <clarify_est> object (from `sim_apply()`)
#>  - 100 simulated values
#>  - 3 quantities estimated
#>              
#>  E[Y(0)] 7015
#>  E[Y(1)] 7183
#>  diff     169

# Bind estimates together after renaming
names(est_b) <- paste0(names(est_b), "_b")
names(est_h) <- paste0(names(est_h), "_h")

est <- cbind(est_b, est_h)
est
#> A <clarify_est> object (from `sim_apply()`)
#>  - 100 simulated values
#>  - 6 quantities estimated
#>                
#>  E[Y(0)]_b 4589
#>  E[Y(1)]_b 6148
#>  diff_b    1559
#>  E[Y(0)]_h 7015
#>  E[Y(1)]_h 7183
#>  diff_h     169

# Compute difference in race-specific differences
est <- transform(est,
                 `diff-diff` = .b6 - .b3)

summary(est,
        parm = c("diff_b", "diff_h", "diff-diff"))
#>           Estimate   2.5 %  97.5 %
#> diff_b      1559.0   -39.7  3095.6
#> diff_h       168.6 -4582.5  5141.3
#> diff-diff  -1390.4 -6392.9  3749.6

# Remove last quantity by using `NULL`
transform(est, `diff-diff` = NULL)
#> A <clarify_est> object (from `sim_apply()`)
#>  - 100 simulated values
#>  - 6 quantities estimated
#>                
#>  E[Y(0)]_b 4589
#>  E[Y(1)]_b 6148
#>  diff_b    1559
#>  E[Y(0)]_h 7015
#>  E[Y(1)]_h 7183
#>  diff_h     169
```
