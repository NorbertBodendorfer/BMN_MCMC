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
- this version of the code does not have contrains in P and Myers implemented, so the input file takes 6 parameters less.

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

Batch_Production_con_m0.5_T0.2_S36N16_F16.sh
- Creates input file (regular code) and execution scripts for the folder structure outlined in the document above. See inside script for what options to change. 

Batch_Thermalization.sh
- Creates input files and execution scripts for the thermalization code. 

G_L36N16T0.2M0.5D9_F11_7.pbs
- Example pbs script to run the simulation code

auto_submit.sh
- checks if a job beloning to certain set of runtime paramters (define in submit_list.txt) is still active. If inactive, a new job is generated and submitted that continues at the last checkpoint.

functions_...
- contains functions used in the Batch... scripts

prod_Run_New_Jobs.sh
- runs new jobs created with Batch_Production_...



Files in scripts folder:

G_L36N16T0.2M0.5D9_F11_7.dat
- Example input file containing runtime paramters for regualar code

th_G_L12N36T0.26M1.0D9_F1_1.dat
- Example input file for a thermalization run

IP_Files/
- contains files that define which ntau and dtau are used in the Batch_Production script above. 

memory_requirements.txt
- contains memory requirements for specific compile time paramters



QPACE4 specific:

Changes from Athene (pbs) to QPACE4 (slurm) are documented here:
https://docs.google.com/document/d/1ZR6rRv87PFG1humlIN43VEtbGuYVBppP4xIvL9zgwfM/edit?usp=sharing

Scritps for QPACE4:

qp4_auto_submit_via_ssh.sh
- runs on Athene and does autosubmit on QP4 due to a lack of screen / cronjob there. 
