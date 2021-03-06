#include "ADMMEnet.h"
#include "DataStd.h"

using Eigen::MatrixXd;
using Eigen::VectorXd;
using Eigen::ArrayXd;
using Eigen::ArrayXXd;

using Rcpp::wrap;
using Rcpp::as;
using Rcpp::List;
using Rcpp::IntegerVector;
using Rcpp::NumericVector;
using Rcpp::NumericMatrix;
using Rcpp::Environment;
using Rcpp::Function;
using Rcpp::Named;

typedef Eigen::Map<MatrixXd> MapMat;
typedef Eigen::Map<VectorXd> MapVec;
typedef Eigen::Map<ArrayXd>  MapArray;
typedef Eigen::SparseVector<double> SpVec;
typedef Eigen::SparseMatrix<double> SpMat;

inline void write_beta_matrix(SpMat &betas, int col, double beta0, SpVec &coef)
{
    betas.insert(0, col) = beta0;

    for(SpVec::InnerIterator iter(coef); iter; ++iter)
    {
        betas.insert(iter.index() + 1, col) = iter.value();
    }
}

RcppExport SEXP admm_enet(SEXP x_, SEXP y_, SEXP lambda_,
                          SEXP nlambda_, SEXP lmin_ratio_,
                          SEXP standardize_, SEXP intercept_,
                          SEXP alpha_, SEXP opts_)
{
BEGIN_RCPP

#if ADMM_PROFILE > 0
    clock_t t1, t2;
    t1 = clock();
#endif

    MatrixXd datX(as<MatrixXd>(x_));
    VectorXd datY(as<VectorXd>(y_));

    // In glmnet, we minimize
    //   1/(2n) * ||y - X * beta||^2 + lambda * ||beta||_1
    // which is equivalent to minimizing
    //   1/2 * ||y - X * beta||^2 + n * lambda * ||beta||_1
    int n = datX.rows();
    int p = datX.cols();
    ArrayXd lambda(as<ArrayXd>(lambda_));
    int nlambda = lambda.size();

    List opts(opts_);
    int maxit = as<int>(opts["maxit"]);
    double eps_abs = as<double>(opts["eps_abs"]);
    double eps_rel = as<double>(opts["eps_rel"]);
    double rho_ratio = as<double>(opts["rho_ratio"]);

    double alpha = as<double>(alpha_);

    bool standardize = as<bool>(standardize_);
    bool intercept = as<bool>(intercept_);

#if ADMM_PROFILE > 0
    t2 = clock();
    Rcpp::Rcout << "part1: " << double(t2 - t1) / CLOCKS_PER_SEC << " secs.\n";
#endif

    DataStd datstd(n, p, standardize, intercept);
    datstd.standardize(datX, datY);

#if ADMM_PROFILE > 0
    t1 = clock();
    Rcpp::Rcout << "part2: " << double(t1 - t2) / CLOCKS_PER_SEC << " secs.\n";
#endif

    ADMMEnet solver(datX, datY, alpha, eps_abs, eps_rel);

#if ADMM_PROFILE > 0
    t2 = clock();
    Rcpp::Rcout << "part3: " << double(t2 - t1) / CLOCKS_PER_SEC << " secs.\n";
#endif

    if(nlambda < 1)
    {
        double lmax = solver.get_lambda_zero() / n * datstd.get_scaleY();
        double lmin = as<double>(lmin_ratio_) * lmax;
        lambda.setLinSpaced(as<int>(nlambda_), log(lmax), log(lmin));
        lambda = lambda.exp();
        nlambda = lambda.size();
    }

    SpMat beta(p + 1, nlambda);
    beta.reserve(Eigen::VectorXi::Constant(nlambda, std::min(n, p)));

    IntegerVector niter(nlambda);
    double ilambda = 0.0;

    for(int i = 0; i < nlambda; i++)
    {
        ilambda = lambda[i] * n / datstd.get_scaleY();
        if(i == 0)
            solver.init(ilambda, rho_ratio);
        else
            solver.init_warm(ilambda);

        niter[i] = solver.solve(maxit);
        SpVec res = solver.get_x();
        double beta0 = 0.0;
        datstd.recover(beta0, res);
        write_beta_matrix(beta, i, beta0, res);
    }

#if ADMM_PROFILE > 0
    t1 = clock();
    Rcpp::Rcout << "part4: " << double(t1 - t2) / CLOCKS_PER_SEC << " secs.\n";
#endif

    beta.makeCompressed();

    return List::create(Named("lambda") = lambda,
                        Named("beta") = beta,
                        Named("niter") = niter);

END_RCPP
}
