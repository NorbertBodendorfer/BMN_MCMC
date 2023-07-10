
  integer nbc !boundary condition for fermions; 0 -> pbc, 1 -> apbc
  integer nbmn ! 0 -> BFSS, 1 -> BMN
  integer init !initial condition; 0 -> continue, 1 -> new
  integer isave !0 -> save intermediate config, 1 -> do not save
  integer nsave!saved every nsave trajectories
!matrices
  double complex xmat(1:nmat,1:nmat,1:ndim,-(nmargin-1):nsite+nmargin)
  double complex xmat_mom(1:nmat,1:nmat,1:ndim,1:nsite)
!gauge field
double precision alpha(1:nmat)
!remez coefficients
double precision acoeff_md(0:nremez_md),bcoeff_md(1:nremez_md)!molecular evolution
double precision acoeff_pf(0:nremez_pf),bcoeff_pf(1:nremez_pf)!pseudo fermion
double precision upper_approx!the largest eigenvalue of (M^¥dagger M)must be smaller than this. 

!CG solver
integer max_iteration, iteration,n_bad_CG
double precision max_err
!For Mersenne Twister
integer mersenne_seed
!Fourier acceleration
double precision acceleration(1:nsite)
double precision fluctuation(1:nsite)
integer iaccelerate,imeasure
integer imetropolis

!number of CG iteration for calculating the largest and smallest eigenvalues of D=(M^dag*M)
integer neig_max,neig_min
!number of fuzzy sphere, when init=2.
integer nfuzzy
!Gamma matrices
double complex Gamma10d(1:ndim,1:nspin,1:nspin)

  integer iremez
  integer ncv!ncv=number of constraint[max(alpha_i-alpha_j)<2*pi] violation

 double precision temperature
 double precision flux
  !parameters for molecular evolution
  integer ntau,nratio
  double precision dtau_xmat,dtau_alpha

  !number of trajectories
  integer ntraj     !total number of trajectories at the end of the run
  integer itraj

  double precision ham_init,ham_fin

  !measurements
  integer nskip !measurement is performed every nskiptrajectories
  integer nacceptance !number of acceptance
  integer ntrial !number of trial
  character(1000) input_config,data_output,output_config,acc_input,acc_output,intermediate_config,CG_log


! For MPI
!integer IERR,NPROCS,MYRANK




!coefficient for potential for alpha
double precision g_alpha
!coefficient for potential for Tr(x^2)
double precision g_R,RCUT
