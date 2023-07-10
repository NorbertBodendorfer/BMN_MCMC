FC=mpif90
# FC=/software/iNTEL/impi/2018.1.163/bin64/mpiifort

# Add source folder here
#SOURCEDIR=/home/bon39708/BMN/SYM1DMMMT-Sep2018-MatrixParallel
SOURCEDIR=${CURDIR}
#SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
#echo $SELF_DIR
# Default flags, please adapt
# FLAGS for mpif90
FCFLAGS= -I$(SOURCEDIR) -O2 -cpp -DMPI_WTIME_IS_GLOBAL 
# FCFLAGS= -I$(SOURCEDIR)/matrix_parallel/ -O2 -heap-arrays 


AR=ar
RM=rm
ARFLAGS=cr
RANLIB=ranlib
# set this to 1 if you want to use gfortran
# set both to 1 if you want to use mpifortran
NODEVICE=1
MPARALLEL=1

%.o: %.f90 $(DEPENDALL)
	${FC} -c ${FCFLAGS} $<


