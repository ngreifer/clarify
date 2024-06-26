% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.clarify_est.R, R/summary.clarify_est.R
\name{plot.clarify_est}
\alias{plot.clarify_est}
\alias{summary.clarify_est}
\alias{confint.clarify_est}
\title{Plotting and inference for \code{clarify_est} objects}
\usage{
\method{plot}{clarify_est}(
  x,
  parm,
  ci = TRUE,
  level = 0.95,
  method = "quantile",
  reference = FALSE,
  ncol = 3,
  ...
)

\method{summary}{clarify_est}(object, parm, level = 0.95, method = "quantile", null = NA, ...)

\method{confint}{clarify_est}(object, parm, level = 0.95, method = "quantile", ...)
}
\arguments{
\item{parm}{a vector of the names or indices of the estimates to plot. If unspecified, all estimates will be displayed.}

\item{ci}{\code{logical}; whether to display confidence interval limits for the estimates. Default is \code{TRUE}.}

\item{level}{the confidence level desired. Default is .95 for 95\% confidence intervals.}

\item{method}{the method used to compute p-values and confidence intervals. Can be \code{"wald"} to use a Normal approximation or \code{"quantile"} to use the simulated sampling distribution (default). See Details. Abbreviations allowed.}

\item{reference}{\code{logical}; whether to overlay a normal density reference distribution over the plots. Default is \code{FALSE}.}

\item{ncol}{the number of columns used when wrapping multiple plots; default is 3.}

\item{...}{for \code{plot()}, further arguments passed to \code{\link[ggplot2:geom_density]{ggplot2::geom_density()}}.}

\item{object, x}{a \code{clarify_est} object; the output of a call to \code{\link[=sim_apply]{sim_apply()}} or its wrappers.}

\item{null}{the values of the parameters under the null hypothesis for the p-value calculations. Should have length equal to the number of quantities estimated, or one, in which case it will be recycled, or it can be a named vector with just the names of quantities for which null values are to be set. Set values to \code{NA} to omit p-values for those quantities. When all values are \code{NA}, the default, no p-values are produced.}
}
\value{
For \code{summary()}, a \code{summary.clarify_est} object, which is a matrix containing the coefficient estimates, standard errors, test statistics, p-values, and confidence intervals. Not all columns will be present depending on the arguments supplied to \code{summary()}.

For \code{confint()}, a matrix containing the confidence intervals for the requested quantities.

For \code{plot()}, a \code{ggplot} object.
}
\description{
\code{summary()} tabulates the estimates and confidence intervals and (optionally) p-values from a \code{clarify_est} object. \code{confint()} computes confidence intervals. \code{plot()} plots the "posterior" distribution of estimates.
}
\details{
\code{summary()} uses the estimates computed from the original model as its estimates and uses the simulated parameters for inference only, in line with the recommendations of Rainey (2023).

When \code{method = "wald"}, the standard deviation of the simulation estimates is used as the standard error, which is used in the z-statistics and the confidence intervals. The p-values and confidence intervals are valid only when the sampling distribution of the resulting statistic is normal (which can be assessed using \code{plot()}). When \code{method = "quantile"}, the confidence interval is calculated using the quantiles of the simulation estimates corresponding to \code{level}, and the p-value is calculated as twice the proportion of simulation estimates less than or greater than \code{null}, whichever is smaller; this is equivalent to inverting the confidence interval but is only truly valid when the true sampling distribution is only a location shift from the sampling distribution under the null hypothesis and should therefore be interpreted with caution. Using \verb{"method = "quantile"} (the default) is recommended because the confidence intervals will be valid even if the sampling distribution is not Normally distributed. The precision of the p-values and confidence intervals depends on the number of simulations requested (the value of \code{n} supplied to \code{\link[=sim]{sim()}}).

The plots are produced using \code{\link[ggplot2:geom_density]{ggplot2::geom_density()}} and can be customized with \pkg{ggplot2} functions. When \code{reference = TRUE}, a reference Normal distribution is produced using the empirical mean and standard deviation of the simulated values. A blue references line is plotted at the median of the simulated values. For Wald-based inference to be valid, the reference distribution should overlap with the empirical distribution, in which case the quantile-based and Wald-based intervals should be similar. For quantile-based inference to be valid, the median of the estimates should overlap with the estimated value; this is a necessary but not sufficient condition, though.
}
\examples{
data("lalonde", package = "MatchIt")
fit <- glm(I(re78 > 0) ~ treat + age + race + nodegree + re74,
          data = lalonde)

s <- sim(fit, n = 100)

# Compute average marginal means for `treat`
est <- sim_ame(s, var = "treat", verbose = FALSE)
coef(est)

# Compute average marginal effects on risk difference
# (RD) and risk ratio (RR) scale
est <- transform(est,
                 RD = `E[Y(1)]` - `E[Y(0)]`,
                 RR = `E[Y(1)]` / `E[Y(0)]`)

# Compute confidence intervals and p-values,
# using given null values for computing p-values
summary(est, null = c(`RD` = 0, `RR` = 1))

# Same tests using normal approximation and alternate
# syntax for `null`
summary(est, null = c(NA, NA, 0, 1),
        normal = TRUE)

# Plot the RD and RR with a reference distribution
plot(est, parm = c("RD", "RR"), reference = TRUE,
     ci = FALSE)

# Plot the RD and RR with quantile confidence bounds
plot(est, parm = c("RD", "RR"), ci = TRUE)

}
\references{
Rainey, C. (2023). A careful consideration of CLARIFY: Simulation-induced bias in point estimates of quantities of interest. \emph{Political Science Research and Methods}, 1–10. \doi{10.1017/psrm.2023.8}
}
\seealso{
\itemize{
\item \code{\link[=sim_apply]{sim_apply()}} for applying a function to each set of simulated coefficients
}
}
