ReadMe for BMN_MCMC repository. 

Overview:
This repository cotains a Fortran code (see folder "code") for Markov Chain Monte Carlo simulations of the BFSS and BMN matrix models. 
The code was originally written by Masanori Hanada https://github.com/MCSMC/SYM1DMMMT and has been maintained and extended recently by Georg Bergner https://github.com/gbergner/SYM1DMMMT
The codes here are forks of the code from Georg Bergner's repository (status Jun 3, 2019, or earlier for "thermalize"). It cotains small changes in the file main_parallel.f90 that were made to adapt the code to the local HPC environments (Athene, QPACE4) in Regensburg. 
The repository also contains scripts to efficienlty run the code in large scale projects, where many long-running simulations for many different simulations parameters need to be performed. 
