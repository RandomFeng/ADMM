% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/30_admm_lasso.R
\name{admm_lasso}
\alias{admm_lasso}
\title{Fitting A Lasso Model Using ADMM Algorithm}
\usage{
admm_lasso(x, y, intercept = TRUE, standardize = TRUE, ...)
}
\arguments{
\item{x}{The data matrix}

\item{y}{The response vector}

\item{intercept}{Whether to fit an intercept in the model. Default is \code{TRUE}.}

\item{standardize}{Whether to standardize the explanatory variables before
fitting the model. Default is \code{TRUE}. Fitted coefficients
are always returned on the original scale.}
}
\description{
Lasso is a popular variable selection technique in high
dimensional regression analysis, which tries to find the coefficient vector
\eqn{\beta} that minimizes
\deqn{\frac{1}{2n}\Vert y-X\beta\Vert_2^2+\lambda\Vert\beta\Vert_1}{
1/(2n) * ||y - X * \beta||_2^2 + \lambda * ||\beta||_1}

Here \eqn{n} is the sample size and \eqn{\lambda} is a regularization
parameter that controls the sparseness of \eqn{\beta}.

This function will not directly conduct the computation,
but rather returns an object of class "\code{ADMM_Lasso}" that contains
several memeber functions to actually constructs and fits the model.

Member functions that are callable from this object are listed below:

\tabular{ll}{
  \code{$penalty()}  \tab Specify the penalty parameter. See section
                          \strong{Setting Penalty Parameter} for details.\cr
  \code{$parallel()} \tab Specify the number of threads for parallel computing.
                          See section \strong{Parallel Computing} for details.\cr
  \code{$opts()}     \tab Setting additional options. See section
                          \strong{Additional Options} for details.\cr
  \code{$fit()}      \tab Fit the model and do the actual computation.
                          See section \strong{Model Fitting} for details.
}
}
\section{Setting Penalty Parameter}{

The penalty parameter \eqn{\lambda} can be set through the member function
\code{$penalty()}, with the usage and parameters given below:

\preformatted{    model$penalty(lambda = NULL, nlambda = 100, lambda_min_ratio, ...)
}

\describe{
\item{\code{lambda}}{A user provided sequence of \eqn{\lambda}. If set to
                     \code{NULL}, the program will calculate its own sequence
                     according to \code{nlambda} and \code{lambda_min_ratio},
                     which starts from \eqn{\lambda_0} (with this
                     \eqn{\lambda} all coefficients will be zero) and ends at
                     \code{lambda0 * lambda_min_ratio}, containing
                     \code{nlambda} values equally spaced in the log scale.
                     It is recommended to set this parameter to be \code{NULL}
                     (the default).}
\item{\code{nlambda}}{Number of values in the \eqn{\lambda} sequence. Only used
                      when the program calculates its own \eqn{\lambda}
                      (by setting \code{lambda = NULL}).}
\item{\code{lambda_min_ratio}}{Smallest value in the \eqn{\lambda} sequence
                               as a fraction of \eqn{\lambda_0}. See
                               the explanation of the \code{lambda}
                               argument. This parameter is only used when
                               the program calculates its own \eqn{\lambda}
                               (by setting \code{lambda = NULL}). The default
                               value is the same as \pkg{glmnet}: 0.0001 if
                               \code{nrow(x) >= ncol(x)} and 0.01 otherwise.}
}

This member function will implicitly return the "\code{ADMM_Lasso}" object itself.
}

\section{Parallel Computing}{

The Lasso model can be fitted with parallel computing by setting the number
of threads in the \code{$parallel()} member function. The usage of this method
is

\preformatted{    model$parallel(nthread = 2, ...)
}

Here \code{model} is the object returned by \code{admm_lasso()}, and
\code{nthread} is the number of threads to be used. \code{nthread} must be
less than \code{ncol(x) / 5}.

\strong{NOTE:} Even in serial version of \code{admm_lasso()}, most matrix
operations are implicitly parallelized when proper compiler options are
turned on. Hence the parallel version of \code{admm_lasso()} is not
necessarily faster than the serial one.

This member function will implicitly return the "\code{ADMM_Lasso}" object itself.
}

\section{Additional Options}{

Additional options related to ADMM algorithm can be set through the
\code{$opts()} member function of an "\code{ADMM_Lasso}" object. The usage of
this method is

\preformatted{    model$opts(maxit = 10000, eps_abs = 1e-5, eps_rel = 1e-5,
               rho_ratio = 0.1)
}

Here \code{model} is the object returned by \code{admm_lasso()}.
Explanation of the arguments is given below:

\describe{
\item{\code{maxit}}{Maximum number of iterations.}
\item{\code{eps_abs}}{Absolute tolerance parameter.}
\item{\code{eps_rel}}{Relative tolerance parameter.}
\item{\code{rho_ratio}}{ADMM step size parameter.}
}

This member function will implicitly return the "\code{ADMM_Lasso}" object itself.
}

\section{Model Fitting}{

Model will be fit after calling the \code{$fit()} member function. This is no
argument that needs to be set. The function will return an object of class
"\code{ADMM_Lasso_fit}", which contains the following fields:

\describe{
\item{\code{lambda}}{The sequence of \eqn{\lambda} to build the solution path.}
\item{\code{beta}}{A sparse matrix containing the estimated coefficient vectors,
                   each column for one \eqn{\lambda}. Intercepts are in the
                   first row.}
\item{\code{niter}}{Number of ADMM iterations.}
}

Class "\code{ADMM_Lasso_fit}" also contains a \code{$plot()} member function,
which plots the coefficient paths with the sequence of \eqn{\lambda}.
See the examples below.
}
\examples{
set.seed(123)
n = 100
p = 20
b = runif(p)
x = matrix(rnorm(n * p, mean = 1.2, sd = 2), n, p)
y = 5 + c(x \%*\% b) + rnorm(n)

## Directly fit the model
admm_lasso(x, y)$fit()

## Or, if you want to have more customization:
model = admm_lasso(x, y)
print(model)

## Specify the lambda sequence
model$penalty(nlambda = 20, lambda_min_ratio = 0.01)

## Lower down precision for faster computation
model$opts(maxit = 100, eps_rel = 0.001)

## Use parallel computing (not necessary for this small dataset here)
# model$parallel(nthread = 2)

## Inspect the updated model setting
print(model)

## Fit the model and do the actual computation
res = model$fit()
res$beta

## Create a solution path plot
res$plot()
}
\author{
Yixuan Qiu <\url{http://statr.me}>
}

