#Utilities

#Turn a vector into a string with "," and "and" or "or" for clean messages.

#Add quotes to a string
add_quotes <- function(x, quotes = 2L) {
  if (isFALSE(quotes)) {
    return(x)
  }

  if (isTRUE(quotes)) {
    quotes <- '"'
  }

  if (rlang::is_string(quotes)) {
    return(paste0(quotes, x, str_rev(quotes)))
  }

  if (length(quotes) != 1L || !is.numeric(quotes) || !(quotes %in% c(1, 2))) {
    stop("`quotes` must be boolean, 1, 2, or a string.")
  }

  if (quotes == 0L) {
    return(x)
  }

  x <- {
    if (quotes == 1L) sprintf("'%s'", x)
    else sprintf('"%s"', x)
  }

  x
}

#Reverse a string
str_rev <- function(x) {
  vapply(lapply(strsplit(x, NULL), rev), paste, character(1L), collapse = "")
}

#More informative and cleaner version of base::match.arg(). Uses arg, rlang, and cli.
match_arg <- function(arg, choices, several.ok = FALSE, context = NULL,
                      arg.name = rlang::caller_arg(arg)) {
  #Replaces match.arg() but gives cleaner error message and processing of arg.
  if (missing(arg)) {
    .err("no argument was supplied to match_arg() (this is a bug)")
  }

  # arg.name <- deparse1(substitute(arg), width.cutoff = 500L)

  if (missing(choices)) {
    sysP <- sys.parent()
    formal.args <- formals(sys.function(sysP))
    choices <- eval(formal.args[[as.character(substitute(arg))]],
                    envir = sys.frame(sysP))
  }

  if (is_null(arg)) {
    return(choices[1L])
  }

  if (several.ok) {
    arg_character(arg, arg.name)
  }
  else {
    arg_string(arg, arg.name)

    if (identical(arg, choices)) {
      return(arg[1L])
    }
  }

  i <- pmatch(arg, choices, nomatch = 0L, duplicates.ok = TRUE)

  if (all(i == 0L)) {
    one_of <- {
      if (length(choices) <= 1L) NULL
      else if (several.ok) "at least one of"
      else "one of"
    }

    if (is_null(context)) {
      .err("the argument to {.arg {arg.name}} should be {one_of} {.or {.val {choices}}}")
    }
    else {
      .err(sprintf("%s the argument to {.arg {arg.name}} should be {one_of} {.or {.val {choices}}}",
                   context))
    }
  }

  i <- i[i > 0L]

  choices[i]
}

#Format percentage for CI labels
fmt.prc <- function(probs, digits = 3L) {
  paste(format(100 * probs, trim = TRUE, scientific = FALSE, digits = digits), "%")
}

#Check if all values are the same
all_the_same <- function(x, na.rm = TRUE) {
  if (anyNA(x)) {
    x <- x[!is.na(x)]

    if (!na.rm) {
      return(is_null(x))
    }
  }

  if (is.numeric(x)) check_if_zero(max(x) - min(x))
  else all(x == x[1L])
}

#Tidy tryCatching
try_catch <- function(expr) {
  tryCatch({
    withCallingHandlers({
      expr
    },
    warning = function(w) {
      .wrn("{conditionMessage(w)}")
      invokeRestart("muffleWarning")
    })},
    error = function(e) {
      .err("{conditionMessage(e)}")
    })
}

#mode
Mode <- function(v, na.rm = TRUE) {
  if (is_null(v)) {
    return(v)
  }

  if (anyNA(v)) {
    if (!na.rm) {
      #Return NA, keeping type of `v`
      v <- v[1L]
      is.na(v) <- TRUE
      return(v)
    }

    v <- v[!is.na(v)]
  }

  if (is.factor(v)) {
    if (nlevels(v) == 1L) {
      return(levels(v)[1L])
    }

    mode <- levels(v)[which.max(tabulate(v, nbins = nlevels(v)))]

    return(factor(mode, levels = levels(v)))
  }

  uv <- unique(v)

  if (length(uv) == 1L) {
    return(uv)
  }

  uv[which.max(tabulate(match(v, uv)))]
}

# Same as attr() but with exact = TRUE
.attr <- function(x, which, exact = TRUE) {
  attr(x, which, exact = exact)
}

#Checks if input is "try-error", i.e., failure of try()
is_error <- function(x) {
  inherits(x, "try-error")
}

is_null <- function(x) {length(x) == 0L}
is_not_null <- function(x) {!is_null(x)}

is_char_or_factor <- function(x) {
  is.character(x) || is.factor(x)
}

check_if_zero <- function(x, tolerance = sqrt(.Machine$double.eps)) {
  # this is the default tolerance used in all.equal
  abs(x) < tolerance
}

#chk utilities
# pkg_caller_call <- function() {
#   pn <- utils::packageName()
#   package.funs <- c(getNamespaceExports(pn),
#                     .getNamespaceInfo(asNamespace(pn), "S3methods")[, 3L])
#
#   for (i in seq_len(sys.nframe())) {
#     e <- sys.call(i)
#
#     n <- rlang::call_name(e)
#
#     if (is_not_null(n) && n %in% package.funs) {
#       return(e)
#     }
#   }
#
#   NULL
# }
#
# .err <- function(..., n = NULL, tidy = TRUE) {
#   m <- chk::message_chk(..., n = n, tidy = tidy)
#   rlang::abort(paste(strwrap(m), collapse = "\n"),
#                call = pkg_caller_call())
# }
# .wrn <- function(..., n = NULL, tidy = TRUE, immediate = TRUE) {
#   m <- chk::message_chk(..., n = n, tidy = tidy)
#
#   if (immediate && isTRUE(all.equal(0, getOption("warn")))) {
#     rlang::with_options({
#       rlang::warn(paste(strwrap(m), collapse = "\n"))
#     }, warn = 1)
#   }
#   else {
#     rlang::warn(paste(strwrap(m), collapse = "\n"))
#   }
# }
# .msg <- function(..., n = NULL, tidy = TRUE) {
#   m <- chk::message_chk(..., n = n, tidy = tidy)
#   rlang::inform(paste(strwrap(m), collapse = "\n"), tidy = FALSE)
# }

drop_sim_class <- function(x) {
  class(x) <- class(x)[!startsWith(class(x), "clarify_")]
  x
}

# Works even for nearly singular (posdef) Sigma; df = Inf is mvrnorm
rmvt <- function(n, mu, Sigma, df = Inf, tol = 1e-7) {
  p <- length(mu)

  if (!all(dim(Sigma) == c(p, p))) {
    .err("incompatible arguments")
  }

  eS <- eigen(Sigma, symmetric = TRUE)
  ev <- eS$values

  if (any(ev < -tol * abs(ev[1L]))) {
    .err("{.arg Sigma} is not positive definite")
  }

  mu <- drop(mu)

  scale_mat <- tcrossprod(eS$vectors %*% diag(sqrt(pmax(ev, 0)), p),
                          eS$vectors)

  if (is.finite(df)) {
    X <- matrix(rnorm(p * n), nrow = n, ncol = p, byrow = TRUE) |>
      tcrossprod(scale_mat) |>
      sweep(1L, sqrt(rchisq(n, df) / df), "/") |>
      sweep(2L, mu, "+")
  }
  else {
    X <- matrix(rnorm(p * n), nrow = n, ncol = p, byrow = TRUE) |>
      tcrossprod(scale_mat) |>
      sweep(2L, mu, "+")
  }

  colnames(X) <- colnames(Sigma)

  X
}

any_apply <- function(X, FUN, ...) {
  FUN <- match.fun(FUN)
  if (!is.vector(X) || is.object(X)) {
    X <- as.list(X)
  }

  for (x in X) {
    if (isTRUE(FUN(x, ...))) {
      return(TRUE)
    }
  }

  FALSE
}
all_apply <- function(X, FUN, ...) {
  FUN <- match.fun(FUN)
  if (!is.vector(X) || is.object(X)) {
    X <- as.list(X)
  }

  for (x in X) {
    if (isFALSE(FUN(x, ...))) {
      return(FALSE)
    }
  }

  TRUE
}

.print_estimate_table <- function(x, digits, topn, ...) {
  if (nrow(x) > 2L * topn + 1) {
    head_ind <- seq_len(topn)
    tail_ind <- nrow(x) - rev(head_ind) + 1L
  }
  else {
    head_ind <- seq_len(nrow(x))
    tail_ind <- integer()
  }

  if (is_not_null(head_ind)) {
    for (i in which(vapply(x, is.numeric, logical(1L)))) {
      x[[i]][c(head_ind, tail_ind)] <- zapsmall(x[[i]][c(head_ind, tail_ind)], digits = digits)
    }

    tmp <- utils::capture.output({
      print.data.frame(x[c(head_ind, tail_ind), , drop = FALSE],
                       digits = digits, row.names = FALSE, right = FALSE, ...)
    })

    out <- tmp[seq_along(c(1L, head_ind))]
  }
  else {
    tmp <- utils::capture.output({
      print.data.frame(x[1L, , drop = FALSE],
                       digits = digits, row.names = FALSE, right = FALSE, ...)
    })

    out <- character(0L)
  }

  to_it <- NULL

  if (nrow(x) > 2L * topn + 1L) {
    msg <- sprintf("--- %s rows omitted. ---",
                nrow(x) - 2L * topn)

    to_it <- length(out) + 1L

    out <- c(out, center_just(msg, wrt = tmp))

    if (is_not_null(tail_ind)) {
      out <- c(out, tmp[-seq_along(c(1L, head_ind))])
    }
  }

  cat(out, sep = "\n")
}

center_just <- function(x, wrt = NULL) {
  if (is_null(wrt)) {
    n <- getOption("width")
  }
  else {
    n <- max(nchar(as.character(wrt)))
  }

  paste0(space(max(0, floor((n - nchar(x)) / 2))), x)
}

space <- function(n) {
  strrep(" ", n)
}
