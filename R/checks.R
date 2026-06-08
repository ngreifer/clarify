process_FUN <- function(FUN, use_fit = TRUE) {
  arg::arg_function(FUN)

  FUN_arg_names <- names(formals(FUN))

  if (is_null(FUN_arg_names)) {
    arg::err("{.arg FUN} must accept one or more arguments")
  }

  attr(FUN, "use_coefs") <- any(FUN_arg_names == "coefs")

  if (!use_fit && !.attr(FUN, "use_coefs")) {
    arg::err('{.arg FUN} must accept a {.arg coefs} argument. See {.fun sim_apply} for details')
  }

  attr(FUN, "use_fit") <- any(FUN_arg_names == "fit")

  if (!use_fit && .attr(FUN, "use_fit")) {
    arg::wrn('the {.arg fit} argument to {.arg FUN} will be ignored. See {.fun sim_apply} for details')
    attr(FUN, "use_fit") <- FALSE
  }

  FUN
}

check_transform <- function(transform = NULL) {
  if (is_null(transform)) {
    return(NULL)
  }

  transform_name <- {
    if (is.character(transform)) transform
    else "fn"
  }

  transform <- try(match.fun(transform))
  arg::arg_function(transform)
  attr(transform, "transform_name") <- transform_name

  transform
}

check_valid_coef <- function(coef) {
  is_not_null(coef) &&
    is.numeric(coef) &&
    (is_null(dim(coef)) || (length(dim(coef)) == 2L && any(dim(coef) == 1L)))
}

check_valid_vcov <- function(vcov) {
  is_not_null(vcov) &&
    is.numeric(vcov) &&
    is.matrix(vcov) &&
    length(dim(vcov)) == 2L &&
    all(diag(vcov) > 0) &&
    check_symmetric_cov(vcov)
}

check_symmetric_cov <- function(x) {
  if (length(dim(x)) != 2L ||
      !identical(dim(x)[1L], dim(x)[2L])) {
    return(FALSE)
  }

  r <- cov2cor(x)

  check <- abs(r - t(r)) < sqrt(.Machine$double.eps)

  !anyNA(check) && all(check)
}

check_coefs_vcov_length <- function(vcov, coefs, vcov_supplied, coef_supplied) {
  if (!all(dim(vcov) == length(coefs))) {
    if (coef_supplied == "null") {
      if (vcov_supplied == "null") {
        arg::err("the covariance matrix extracted from the model has dimensions different from the number of coefficients extracted from the model. You may need to supply your own function to extract one or both of these")
      }
      if (vcov_supplied == "fun") {
        arg::err("the output of the function supplied to {.arg vcov} must have dimensions equal to the number of coefficients extracted from the model ({length(coefs)})")
      }
      if (vcov_supplied == "num") {
        arg::err("when supplied as a matrix, {.arg vcov} must have dimensions equal to the number of coefficients extracted from the model ({length(coefs)})")
      }
    }
    else if (coef_supplied == "fun") {
      if (vcov_supplied == "null") {
        arg::err("the output of the function supplied to {.arg coefs} must have length equal to the dimensions of the covariance matrix extracted from the model ({nrow(vcov)})")
      }
      if (vcov_supplied == "fun") {
        arg::err("the output of the function supplied to {.arg vcov} must have dimensions equal to the length of the output of the function supplied to {.arg coefs} ({length(coefs)})")
      }
      if (vcov_supplied == "num") {
        arg::err("when supplied as a matrix, {.arg vcov} must have dimensions equal to the length of the output of the function supplied to {.arg coefs} ({length(coefs)})")
      }
    }
    else if (coef_supplied == "num") {
      if (vcov_supplied == "null") {
        arg::err("the coefficient vector supplied to {.arg coefs} must have length equal to the dimensions of the covariance matrix extracted from the model ({nrow(vcov)})")
      }
      if (vcov_supplied == "fun") {
        arg::err("the output of the function supplied to {.arg vcov} must have dimensions equal to the length of the coefficient vector supplied to {.arg coefs} ({length(coefs)})")
      }
      if (vcov_supplied == "num") {
        arg::err("when supplied as a matrix, {.arg vcov} must have dimensions equal to the length of the coefficient vector supplied to {.arg coefs} ({length(coefs)})")
      }
    }
  }
}

check_coefs_vcov_length_mi <- function(vcov, coefs, vcov_supplied, coef_supplied) {

  if (!all_the_same(lengths(coefs))) {
    switch(
      coef_supplied,
      "null" = arg::err("the coefficient vectors extracted from the models must all have the same length"),
      "fun" = arg::err("the coefficient vectors returned by the function supplied to {.arg coefs} must all have the same length"),
      "num" = arg::err("the coefficient vectors supplied to {.arg coefs} must all have the same length")
    )
  }

  if (length(unique(lapply(vcov, dim))) > 1L) {
    switch(
      coef_supplied,
      "null" = arg::err("the covariance matrices extracted from the models must all have the same dimensions"),
      "fun" = arg::err("the covariance matrices returned by the function supplied to {.arg vcov} must all have the same dimensions"),
      "num" = arg::err("the covariance matrices supplied to {.arg vcov} must all have the same dimensions")
    )
  }

  bad_imps <- which(vapply(seq_along(vcov), function(i) {
    !all(dim(vcov[[i]]) == length(coefs[[i]]))
  }, logical(1L)))

  in.imps <- {
    if (length(bad_imps) == length(vcov))
      "all imputations"
    else
      cli::format_inline("{cli::qty(length(bad_imps))}imputation{?s} {bad_imps}")
  }

  if (is_not_null(bad_imps)) {
    if (coef_supplied == "null") {
      if (vcov_supplied == "null") {
        arg::err("in {in.imps}, the covariance matrix extracted from the model has dimensions different from the number of coefficients extracted from the model. You may need to supply your own function to extract one or both of these")
      }
      else if (vcov_supplied == "fun") {
        arg::err("in {in.imps}, the output of the function supplied to {.arg vcov} must have dimensions equal to the number of coefficients extracted from the model ({length(coefs[[1L]])})")
      }
      else if (vcov_supplied == "num") {
        arg::err("in {in.imps}, {.arg vcov} must have dimensions equal to the number of coefficients extracted from the model ({length(coefs[[1L]])}) when supplied as a matrix or list of matrices")
      }
    }
    else if (coef_supplied == "fun") {
      if (vcov_supplied == "null") {
        arg::err("in {in.imps}, the output of the function supplied to {.arg coefs} must have length equal to the dimensions of the covariance matrix extracted from the model ({nrow(vcov[[1L]])})")
      }
      else if (vcov_supplied == "fun") {
        arg::err("in {in.imps}, the output of the function supplied to {.arg vcov} must have dimensions equal to the length of the output of the function supplied to {.arg coefs} ({length(coefs[[1L]])})")
      }
      else if (vcov_supplied == "num") {
        arg::err("in {in.imps}, {.arg vcov} must have dimensions equal to the length of the output of the function supplied to {.arg coefs} ({length(coefs[[1L]])}) when supplied as a matrix or list of matrices")
      }
    }
    else if (coef_supplied == "num") {
      if (vcov_supplied == "null") {
        arg::err("in {in.imps}, the coefficient vector supplied to {.arg coefs} must have length equal to the dimensions of the covariance matrix extracted from the model ({nrow(vcov[[1L]])})")
      }
      else if (vcov_supplied == "fun") {
        arg::err("in {in.imps}, the output of the function supplied to {.arg vcov} must have dimensions equal to the length of the coefficient vector supplied to {.arg coefs} ({length(coefs[[1L]])})")
      }
      else if (vcov_supplied == "num") {
        arg::err("in {in.imps}, {.arg vcov} must have dimensions equal to the length of the coefficient vector supplied to {.arg coefs} ({length(coefs[[1L]])}) when supplied as a matrix or list of matrices")
      }
    }
  }
}

check_fitlist <- function(fitlist) {
  if (!is.list(fitlist) ||
      any_apply(fitlist, function(f) {
        b <- try(coef(f), silent = TRUE)
        is_error(b) || is_null(b) || all(is.na(b))
      })) {
    arg::err("{.arg fitlist} must be a list of model fits or a {.cls mira} object")
  }
}

check_ests.list <- function(est, test) {
  l <- lengths(est)
  l0 <- which(l == 0L)

  if (is_not_null(l0)) {
    arg::wrn("some simulations produced no estimates; these estimates have been replaced by {.val {NA}}",
             immediate = FALSE)

    est[l0] <- lapply(l0, function(i) {
      rep.int(NA_real_, length(test))
    })
  }

  if (!all(l == length(test))) {
    arg::err("not all simulations produced estimates with the same length as the number of estimates computed from the original coefficients, indicating a problem in {.arg FUN}")
  }
}

check_ests <- function(ests) {
  non_finites <- which(!is.finite(ests))
  if (length(non_finites) == length(ests)) {
    arg::err("no finite estimates were produced")
  }

  if (is_not_null(non_finites)) {
    arg::wrn("some non-finite values were found among the estimates, which can invalidate inferences",
             immediate = FALSE)
  }
}

process_parm <- function(object, parm) {
  #Returns numeric parm
  if (missing(parm)) {
    parm <- seq_len(ncol(object))
  }

  if (is.character(parm)) {
    ind <- match(parm, names(object))
    if (anyNA(ind)) {
      arg::err("{.val {parm[is.na(ind)]}} {?is/are} not the name{?s} of any estimated quantities")
    }
    parm <- ind
  }
  else if (is.numeric(parm) && rlang::is_integerish(parm)) {
    if (any(parm < 1) || any(parm > ncol(object))) {
      if (ncol(object) != 1L) {
        arg::err("all values in {.arg parm} must be between 1 and {ncol(object)}")
      }

      arg::wrn("ignoring {.arg parm} because only one estimate is available")
      parm <- 1L
    }
  }
  else {
    parm <- NA_integer_
  }

  parm
}

process_null <- function(null, object, parm) {
  if (is_null(null) || (is.atomic(null) && all(is.na(null)))) {
    null <- NA_real_
  }
  else {
    arg::arg_numeric(null[!is.na(null)], .arg = "null")
  }

  if (is_not_null(names(null))) {
    null0 <- rep.int(NA_real_, length(parm)) |>
      setNames(names(object)[parm])

    if (!all(names(null) %in% names(null0))) {
      if (all(seq_len(ncol(object)) %in% parm)) {
        arg::err("if {.arg null} is named, its names must correspond to estimates in the supplied {.cls clarify_est} object")
      }
      else {
        arg::err("if {.arg null} is named, its names must correspond to estimates specified in {.arg parm}")
      }
    }

    null0[names(null)] <- null
  }
  else if (length(null) == 1L) {
    null0 <- rep.int(null, length(parm)) |>
      setNames(names(object)[parm])
  }
  else if (length(null) == length(parm)) {
    null0 <- setNames(null, names(object)[parm])
  }
  else {
    arg::err("{.arg null} must have length 1 or length equal to the number of quantities estimated ({length(parm)})")
  }

  null0
}

#Edits to stats::.checkMFClasses
check_classes <- function(olddata, newdata) {
  new <- vapply(newdata, stats::.MFclass, character(1L))
  old <- vapply(olddata, stats::.MFclass, character(1L))
  new <- new[names(new) %in% names(old)]

  if (is_null(new)) {
    return(invisible(NULL))
  }

  old <- old[names(new)]
  old[old == "ordered"] <- "factor"
  new[new == "ordered"] <- "factor"
  new[old == "factor" & new == "character"] <- "factor"
  new[old == "character" & new == "factor"] <- "character"

  if (!identical(old, new)) {
    wrong <- old != new
    if (sum(wrong) == 1) {
      arg::err("variable {.var {names(old)[wrong]}} was fit with type {.cls {old[wrong]}} but type {.cls {new[wrong]}} was supplied")
    }
    else {
      arg::err("variables {.var {names(old)[wrong]}} were specified with different types from the original model fit")
    }
  }

  invisible(NULL)
}

check_sim_apply_wrapper_ready <- function(sim) {
  # fun <- deparse1(.pkg_caller_call()[[1L]])
  fun <- rlang::caller_call() |>
    rlang::call_name()

  arg::arg_is(sim, "clarify_sim")

  if (!isTRUE(.attr(sim, "use_fit"))) {
    arg::err("{.fun {fun}} can only be used when a model fit was supplied to the original call to {.fun sim}")
  }

  if (inherits(sim, "clarify_misim")) {
    if (!all_apply(sim$fit, insight::is_regression_model)) {
      arg::err("{.fun {fun}} can only be used with regression models")
    }
  }
  else if (!insight::is_regression_model(sim$fit)) {
    arg::err("{.fun {fun}} can only be used with regression models")
  }

  invisible(NULL)
}
