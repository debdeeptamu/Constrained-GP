#########################################################
# Input: x: Covariate, a n*1 vector. 
#        y: Response, a n*1 vector.  
#        nu: Smoothness parameter in matern kernel. 
#        l: Length-scale parameter in matern kernel.
#        niter: Iteration numvers of MC. 
#        u: Knots of basis functions.
#        Phi: Basis function evaluation, a n*(N+2) matrix.
#        trans_mat: tansformation matrix used in the constrained GP methods
#
# Output: [f, tau, sigma] 
#         f: mcmc samples of weights parameter  
#         tau: mcmc samples of signal-to-noise level in matern kernel 
#         sigma: mcmc samples of noise level
##########################################################


c1GP = function(x, y, nu, l, niter, u, Phi, trans_mat){
  
  n=length(x)
  
  # covariance matrix #
  mcov = maternCov(u, l, nu = nu)
  D = eigen(mcov)$values
  U = eigen(mcov)$vectors
  for(i in 1:length(D)){ if(D[i] < 0) D[i] = -D[i]}
  mcov = U%*%diag(D)%*%t(U)
  mcov_inv = chol2inv(chol(mcov))
  
  # initial values of mcmc #
  f = matrix(nrow = N+2, ncol = niter)
  f[,1] = t(chol(mcov))%*%rnorm(N+2, 0, 1)*sqrt(tau[1])
  tau = c()
  tau[1] = 0.01
  sigma = c()
  sigma[1] = 0.01
  
  L = c(-Inf,rep(0, N+1)) 
  U = rep(Inf, N+2)
  re = list()
  
  # mcmc runs #
  for(i in 2:niter){
    
    if(i%%10 == 0) print(i)
    Sig = tau[i-1]*t(Phi) %*% Phi + sigma[i-1]*mcov_inv
    Siginv = tau[i-1]*sigma[i-1]*chol2inv(chol(Sig))
    postmean = Siginv%*%t(Phi)%*%y/sigma[i-1]
    
    tran_Sig = trans_mat%*%Siginv%*%t(trans_mat) 
    f_trans = trans_mat %*% postmean + mvrandn(L-trans_mat%*%postmean, U, tran_Sig, 1)
    f_cond = solve(trans_mat, f_trans)
    f[,i] = as.matrix(f_cond, ncol = 1)
    sigma[i] = rinvgamma(1, shape = n/2, rate = t(y-Phi%*%f[,i])%*%(y-Phi%*%f[,i])/2)
    tau[i] = rinvgamma(1,shape = (N+2)/2, rate = t(f[,i])%*%mcov_inv%*%f[,i]/2)
  }
  
  re = list(f, tau, sigma)
  
  return(re)
  
}


