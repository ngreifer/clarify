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
  rlang::try_fetch({
    expr
  },
  warning = function(w) {
    arg::wrn("{conditionMessage(w)}")
    invokeRestart("muffleWarning")
  },
  error = function(e) {
    arg::err("{conditionMessage(e)}")
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

is_null <- function(x) {identical(length(x), 0L)}
is_not_null <- function(x) {!is_null(x)}

is_char_or_factor <- function(x) {
  is.character(x) || is.factor(x)
}

check_if_zero <- function(x, tolerance = sqrt(.Machine$double.eps)) {
  # this is the default tolerance used in all.equal
  abs(x) < tolerance
}

drop_sim_class <- function(x) {
  class(x) <- class(x)[!startsWith(class(x), "clarify_")]
  x
}

# Works even for nearly singular (posdef) Sigma; df = Inf is mvrnorm
rmvt <- function(n, mu, Sigma, df = Inf, tol = 1e-7) {
  p <- length(mu)

  if (!all(dim(Sigma) == c(p, p))) {
    arg::err("incompatible arguments")
  }

  eS <- eigen(Sigma, symmetric = TRUE)
  ev <- eS$values

  if (any(ev < -tol * abs(ev[1L]))) {
    arg::err("{.arg Sigma} is not positive definite")
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
