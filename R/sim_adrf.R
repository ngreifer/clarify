#' Compute an average dose-response function
#'
#' `sim_adrf()` is a wrapper for [sim_apply()] that computes average dose-response functions (ADRFs) and average marginal effect functions (AMEFs). An ADRF describes the relationship between values a focal variable can take and the expected value of the outcome were all units to be given each value of the variable. An AMEF describes the relationship between values a focal variable can take and the derivative of ADRF at each value.
#'
#' @inheritParams sim_apply
#' @param var the name of a variable for which the ADRF or AMEF is to be computed. This variable must be present in the model supplied to `sim()` and must be a numeric variable taking on more than two unique values.
#' @param subset optional; a vector used to subset the data used to compute the ADRF or AMEF. This will be evaluated within the original dataset used to fit the model using [subset()], so nonstandard evaluation is allowed.
#' @param by a one-sided formula or character vector containing the names of variables for which to stratify the estimates. Each quantity will be computed within each level of the complete cross of the variables specified in `by`.
#' @param contrast a string naming the type of quantity to be produced: `"adrf"` for the ADRF (the default) or `"amef"` for the AMEF.
#' @param at the levels of the variable named in `var` at which to evaluate the ADRF or AMEF. Should be a vector of numeric values corresponding to possible levels of `var`. If `NULL`, will be set to a range from slightly below the lowest observed value of `var` to slightly above the largest value.
#' @param n when `at = NULL`, the number of points to evaluate the ADRF or AMEF. Default is 21. Ignored when `at` is not `NULL`.
#' @param outcome a string containing the name of the outcome or outcome level for multivariate (multiple outcomes) or multi-category outcomes. Ignored for univariate (single outcome) and binary outcomes.
#' @param type a string containing the type of predicted values (e.g., the link or the response). Passed to [marginaleffects::get_predict()] and eventually to `predict()` in most cases. The default and allowable option depend on the type of model supplied, but almost always corresponds to the response scale (e.g., predicted probabilities for binomial models).
#' @param eps when `contrast = "amef"`, the value by which to shift the value of `var` to approximate the derivative. See Details.
#' @param \dots for `sim_adrf()`, additional arguments passed to [marginaleffects::get_predict()] (and eventually to `predict()`) to compute predictions. For `print()`, ignored.
#' @param x a `<clarify_adrf>` object.
#'
#' @details
#' The ADRF is composed of average marginal means across levels of the focal predictor. For each level of the focal predictor, predicted values of the outcome are computed after setting the value of the predictor to that level, and those values of the outcome are averaged across all units in the sample to arrive at an average marginal mean. Thus, the ADRF represent the relationship between the "dose" (i.e., the level of the focal predictor) and the average "response" (i.e., the outcome variable). It is the continuous analog to the average marginal effect computed for a binary predictor, e.g., using [sim_ame()]. Although inference can be at each level of the predictor or between two levels of the predictor, typically a plot of the ADRF is the most useful relevant quantity. These can be requested using [plot.clarify_adrf()].
#'
#' The AMEF is the derivative of the ADRF; if we call the derivative of the ADRF at each point a "treatment effect" (i.e., the rate at which the outcome changes corresponding to a small change in the predictor, or "treatment"), the AMEF is a function that relates the size of the treatment effect to the level of the treatment. The shape of the AMEF is usually of less importance than the value of the AMEF at each level of the predictor, which corresponds to the size of the treatment effect at the corresponding level. The AMEF is computed by computing the ADRF at each level of the focal predictor specified in `at`, shifting the predictor value by a tiny amount (control by `eps`), and computing the ratio of the change in the outcome to the shift, then averaging this value across all units. This quantity is related the the average marginal effect of a continuous predictor as computed by [sim_ame()], but rather than average these treatment effects across all observed levels of the treatment, the AMEF is a function evaluated at each possible level of the treatment. The "tiny amount" used is `eps` times the standard deviation of `var`.
#'
#' Note that inference on the computed quantities treats the other variables in the model as fixed; that is, it only accounts for model-based uncertainty, not uncertainty due to sampling.
#'
#' @returns
#' A `<clarify_adrf>` object, which inherits from `<clarify_est>` and is similar to the output of `sim_apply()`, with the additional attributes `"var"` containing the variable named in `var`, `"by"` containing the names of the variables specified in `by` (if any), `"at"` containing values at which the ADRF or AMEF is evaluated, and `"contrast"` containing the argument supplied to `contrast`. For an ADRF, the average marginal means will be named `E[Y({v})]`, where `{v}` is replaced with the values in `at`. For an AMEF, the average marginal effects will be named `dY/d({x})|{a}` where `{x}` is replaced with `var` and `{a}` is replaced by the values in `at`.
#'
#' @seealso
#' * [plot.clarify_adrf()] for plotting the ADRF or AMEF.
#' * [sim_ame()] for computing average marginal effects.
#' * [sim_apply()], which provides a general interface to computing any quantities for simulation-based inference.
#' * [summary.clarify_est()] for computing p-values and confidence intervals for the estimated quantities.
#' * [marginaleffects::avg_slopes()] and [marginaleffects::avg_predictions()] for delta method-based implementations of computing average marginal effects and average marginal means.
#' * the \CRANpkg{adrftools} package, which performs inference, testing, and visualization of the ADRF and AMEF.
#'
#' @examplesIf rlang::is_installed("MatchIt")
#' data("lalonde", package = "MatchIt")
#'
#' # Fit the model
#' fit <- glm(I(re78 > 0) ~ treat + age + race +
#'              married + re74,
#'            data = lalonde, family = binomial)
#'
#' # Simulate coefficients
#' set.seed(123)
#' s <- sim(fit, n = 100)
#'
#' # ADRF for `age`
#' est <- sim_adrf(s, var = "age",
#'                 at = seq(15, 55, length.out = 6))
#' est
#' plot(est)
#'
#' # AMEF for `age`
#' est <- sim_adrf(s, var = "age", contrast = "amef",
#'                at = seq(15, 55, length.out = 6))
#' est
#' summary(est)
#' plot(est)
#'
#' # ADRF for `age` within levels of `married`
#' est <- sim_adrf(s, var = "age",
#'                 at = seq(15, 55, length.out = 6),
#'                 by = ~married)
#' est
#' plot(est)
#'
#' ## Difference between ADRFs
#' est_diff <- est[7:12] - est[1:6]
#' plot(est_diff) + ggplot2::labs(y = "Diff")

#' @export
sim_adrf <- function(sim,
                     var,
                     subset = NULL,
                     by = NULL,
                     contrast = "adrf",
                     at = NULL,
                     n = 21,
                     outcome = NULL,
                     type = NULL,
                     eps = 1e-5,
                     verbose = interactive(),
                     cl = NULL,
                     ...) {

  check_sim_apply_wrapper_ready(sim)

  if (missing(var)) {
    arg::err("{.arg var} must be supplied, identifying the focal variable")
  }

  arg::arg_string(var,
                  .msg = "{.arg var} must be the name of the desired focal variable")

  contrast <- arg::match_arg(contrast, c("adrf", "amef"))

  arg::arg_flag(verbose)
  is_misim <- inherits(sim, "clarify_misim")

  dat <- {
    if (is_misim)
      do.call("rbind", lapply(sim$fit, insight::get_predictors, verbose = FALSE))
    else
      insight::get_predictors(sim$fit, verbose = FALSE)
  }

  if (!hasName(dat, var)) {
    arg::err("the variable {.var {var}} named in {.arg var} is not present in the original model")
  }

  arg::when_not_null(
    by,
    arg::arg_or(
      arg::arg_character,
      arg::arg_formula(one_sided = TRUE)
    )
  )

  if (is_not_null(by) && is.character(by)) {
    by <- reformulate(by)
  }

  var_val <- dat[[var]]
  rm(dat)

  if (is_char_or_factor(var_val) ||
      is.logical(var_val) || length(unique(var_val)) <= 2L) {
    arg::err("the variable named in {.arg var} must be a numeric variable taking on more than two values. Use {.fun sim_ame} instead")
  }

  index.sub <- substitute(subset)
  sim$fit <- .attach_pred_data_to_fit(sim$fit, by = by, index.sub = index.sub,
                                      is_fitlist = is_misim)

  #Test to make sure compatible
  if (is_misim) {
    test_dat <- .get_pred_data_from_fit(sim$fit[[1L]])
    test_predict <- clarify_predict(sim$fit[[1L]], newdata = test_dat,
                                    group = NULL, type = type, ...)
  }
  else {
    test_dat <- .get_pred_data_from_fit(sim$fit)
    test_predict <- clarify_predict(sim$fit, newdata = test_dat,
                                    group = NULL, type = type, ...)
  }

  if (hasName(test_predict, "group") && length(unique_group <- unique(test_predict$group)) > 1L) {
    if (is_null(outcome)) {
      arg::err("{.arg outcome} must be supplied with multivariate models and models with multi-category outcomes")
    }

    arg::arg_string(outcome)

    if (!outcome %in% unique_group) {
      arg::err("only the following values of {.arg outcome} are allowed: {.val {unique_group}}")
    }

    test_predict <- .subset_group(test_predict, outcome)
  }
  else {
    if (is_not_null(outcome)) {
      arg::wrn("{.arg outcome} is ignored for univariate models")
    }

    outcome <- NULL
  }

  if (nrow(test_predict) != nrow(test_dat)) {
    arg::err("not all units received a predicted value, suggesting a bug")
  }

  arg::when_not_null(
    at,
    arg::arg_numeric
  )

  min_var <- min(var_val)
  max_var <- max(var_val)
  if (is_null(at)) {
    arg::arg_count(n)
    # lims <- c(min_var - .01 * (max_var - min_var),
    #           max_var + .01 * (max_var - min_var))
    lims <- c(min_var, max_var)
    at <- seq(lims[1L], lims[2L], length.out = n)
  }
  else {
    if (min(at) > max_var || max(at) < min_var) {
      arg::wrn("the values supplied to {.arg at} are outside the range of {.var {var}}; proceed with caution")
    }
    at <- sort(at)
  }

  if (contrast == "adrf") {
    if (is_null(by)) {
      FUN <- function(fit) {
        dat <- .get_pred_data_from_fit(fit)
        vapply(at, function(x) {
          dat[[var]][] <- x

          clarify_predict(fit, newdata = dat, group = outcome, type = type, ...) |>
            .get_p() |>
            mean()
        }, numeric(1L))
      }

      out <- sim_apply(sim, FUN = FUN, verbose = verbose, cl = cl)
      names(out) <- sprintf("E[Y(%s)]", at)
      attr(out, "at") <- at
    }
    else {
      FUN <- function(fit) {
        dat <- .get_pred_data_from_fit(fit)
        by_var <- .get_by_from_fit(fit)

        unlist(lapply(levels(by_var), function(b) {
          in_b <- by_var == b

          vapply(at, function(x) {
            dat[[var]][] <- x
            clarify_predict(fit, newdata = dat[in_b,, drop = FALSE],
                            group = outcome, type = type, ...) |>
              .get_p() |>
              mean()
          }, numeric(1L))
        }))
      }

      out <- sim_apply(sim, FUN = FUN, verbose = verbose, cl = cl)

      by_levels <- levels(.get_by_from_fit(sim$fit))

      names(out) <- unlist(lapply(by_levels, function(b) sprintf("E[Y(%s)|%s]", at, b)))

      attr(out, "by") <- .attr(sim$fit, "by_name")
      attr(out, "at") <- rep.int(at, length(by_levels))
    }
  }
  else if (contrast == "amef") {
    arg::arg_number(eps)
    arg::arg_gt(eps, 0)
    eps <- eps * sd(var_val)

    if (is_null(by)) {
      FUN <- function(fit) {
        dat <- .get_pred_data_from_fit(fit)
        ind <- seq_len(nrow(dat))
        dat2 <- dat[c(ind, ind), , drop = FALSE]

        vapply(at, function(x) {
          dat2[[var]][ind] <- x - eps / 2
          dat2[[var]][-ind] <- x + eps / 2

          p <- clarify_predict(fit, newdata = dat2, group = outcome, type = type, ...) |>
            .get_p()

          m0 <- mean(p[ind])
          m1 <- mean(p[-ind])

          (m1 - m0) / eps
        }, numeric(1L))
      }

      out <- sim_apply(sim, FUN = FUN, verbose = verbose, cl = cl)
      names(out) <- sprintf("E[dY/d(%s)|%s]", var, at)

      attr(out, "at") <- at
    }
    else {
      FUN <- function(fit) {
        dat <- .get_pred_data_from_fit(fit)
        by_var <- .get_by_from_fit(fit)
        ind <- seq_len(nrow(dat))
        dat2 <- dat[c(ind, ind), , drop = FALSE]

        unlist(lapply(levels(by_var), function(b) {
          in_b <- by_var == b

          vapply(at, function(x) {
            dat2[[var]][ind] <- x - eps / 2
            dat2[[var]][-ind] <- x + eps / 2

            p <- clarify_predict(fit, newdata = dat2, group = outcome, type = type, ...) |>
              .get_p()

            m0 <- mean(p[ind][in_b])
            m1 <- mean(p[-ind][in_b])

            (m1 - m0) / eps
          }, numeric(1L))
        }))

      }

      out <- sim_apply(sim, FUN = FUN, verbose = verbose, cl = cl)

      by_levels <- levels(.get_by_from_fit(sim$fit))

      names(out) <- unlist(lapply(by_levels, function(b) sprintf("E[dY/d(%s)|%s,%s]", var, at, b)))

      attr(out, "by") <- .attr(sim$fit, "by_name")
      attr(out, "at") <- rep.int(at, length(by_levels))
    }
  }

  attr(out, "var") <- var
  attr(out, "contrast") <- contrast
  class(out) <- c("clarify_adrf", class(out))

  out
}

#' @exportS3Method print clarify_adrf
#' @rdname sim_adrf
print.clarify_adrf <- function(x, digits = 4L, max.ests = 6L, ...) {
  arg::arg_whole_number(digits)
  arg::arg_count(max.ests)

  n.ests <- length(coef(x))
  max.ests <- min(max.ests, n.ests)

  cli::format_inline("A {.cls clarify_est} object (from {.fun sim_adrf})") |>
    cli::cat_line()

  if (is_not_null(.attr(x, "contrast")) && is_not_null(.attr(x, "var"))) {
    cn <- switch(.attr(x, "contrast"),
                 adrf = "Average dose-response function",
                 amef = "Average marginal effect function")

    cli::format_inline(" - {cn} of {.var {(.attr(x, 'var'))}}") |>
      cli::cat_line()
  }

  if (is_not_null(.attr(x, "by"))) {
    cli::format_inline("   - within levels of {.var {(.attr(x, 'by'))}}") |>
      cli::cat_line()
  }

  cli::format_inline(" - {nrow(x)} simulated value{?s}") |>
    cli::cat_line()

  cli::format_inline(" - {n.ests} quantit{?y/ies} estimated") |>
    cli::cat_line()

  data.frame(names(coef(x)),
             coef(x),
             fix.empty.names = FALSE) |>
    .print_estimate_table(digits = digits,
                          topn = floor(max.ests / 2))

  invisible(x)
}
