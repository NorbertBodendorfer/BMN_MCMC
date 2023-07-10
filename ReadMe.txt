ReadMe for BMN_MCMC repository. 


Overview:
This repository cotains a Fortran code (see folder "code") for Markov Chain Monte Carlo simulations of the BFSS and BMN matrix models. 
The code was originally written by Masanori Hanada https://github.com/MCSMC/SYM1DMMMT and has been maintained and extended recently by Georg Bergner https://github.com/gbergner/SYM1DMMMT
The codes here are forks of the code from Georg Bergner's repository (status Jun 3, 2019, or earlier for "thermalize"). It cotains small changes in the file main_parallel.f90 that were made to adapt the code to the local HPC environments (Athene, QPACE4) in Regensburg. 
The repository also contains scripts to efficienlty run the code in large scale projects, where many long-running simulations for many different simulations parameters need to be performed. 


Codes:

All codes contain the following changes as opposed to original version. They take two arguments:
  1) input_file_name, being the path+name of the file that contains the run-time simulation parameters. This allows for better handling of a large amount of parallel simulations. 
  2) wall_time, being the time in seconds after which the code terminates automatically and writes out a checkpoint to continue from. This allows to avoid forced terminations of the code due to runtime restrictions on the clusters. 

Additionally, the there are the folling changes:

SYM1DMMMT_adapted_srng:
- instead of reading the current state of the random number generator from the configuration file, a new random seed is set which is read from the input file. This is useful if one wants to fork a Monte Carlo stream from a given configuration to increase parallelization. 

SYM1DMMMT_adapted_thermalize:
- this code is useful to determine a good choice of integration parameters (ntau, dtau). It changes ntau while keeping the step size ntau * dtau for Hamiltonian MCMC fixed until an acceptance rate of 80% is reached. It writes the resutls into a file that is passed as the third argument to the program.


Compiling the code:
1) in the file matrix_parallel/size_parallel.h change the compile time parameters such as lattice size, N, and parallelization to the desired quantities. For supersymmetric simulations, one needs ndim=9. nsublat and nblock need to be at least 2. 
2) make clean 
3) make
4) the compiled file is called bfss_mparallel. It is useful to rename it so it contains the compile time parameters that are typically varied.


Running the code:
We deal here only with the parallel code for CPU clusters (GPU and single CPU is also available.)
Detailed instructions to run the code on Athene are given in the following document:

https://docs.google.com/document/d/1ggaWb8e31lq2lda0xxr0w_SEg810zQXNu3jFqZzSTRU/edit?usp=sharing

Some data analysis scripts there are outdated, current scripts and instructions are in the repository https://github.com/NorbertBodendorfer/BFSS_BMN_Data_Analysis



Scripts:


