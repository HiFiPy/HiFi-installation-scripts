#!/bin/bash

# HiFi installation script using gfortran

#DEST_DIR="/media/Backscratch/Users/namurphy/Projects/HiFi2D_gfortran/TestInstallScript/"

DEST_DIR=`pwd`"/"

# Specify what to install

INST_MPICH=0
INST_HDF5=0
INST_PETSC=0
INST_HIFI_SOLVER=1
INST_HIFI_POST=0
INST_HIFI_CODE=0

# To install the HiFi code, we need to set a PHYSICS environment
# variable.

export PHYSICS=pn_ext

# To install the HiFi solver directory, specify your username on 

export HIFI_USERNAME="namurphy"

# Specify which compilers to use.  The GCC compilers are gcc, g++, and
# gfortran.  The Intel compilers are icc, icpc, and ifort.

export CC="gcc"
export CXX="g++"
export CPP="gcc -E"
export FC="gfortran"
export F9X="gfortran"
export F77="gfortran"
export FCFLAGS=""
export CFLAGS=""
export CXXFLAGS=""

# Set the number of processes to use during compilation.  

MAKE_PROCS="12" 

# Select which versions of the different libraries to use.  Note that 

MPI_VERSION="3.2"
HDF5_VERSION="1.8.18"
PETSC_VERSION="3.5.4"
PETSC_ARCH="arch-linux2-c-opt"
HIFI_SOLVER_VERSION="3.5"

########################################################################
# Installing MPICH
########################################################################

if [ ${INST_MPICH} -eq 1 ]; then
    cd ${DEST_DIR}
    wget -q http://www.mpich.org/static/downloads/${MPI_VERSION}/mpich-${MPI_VERSION}.tar.gz \
	-O ${DEST_DIR}/mpich-${MPI_VERSION}.tar.gz
    tar xzf mpich-${MPI_VERSION}.tar.gz
    cd ${DEST_DIR}/mpich-${MPI_VERSION}/
    ./configure --prefix=${DEST_DIR}/mpich-${MPI_VERSION}-install \
	CC=${CC} CXX=${CXX} FC=${FC} F77=${F77} 
    make -j${MAKE_PROCS} 
    make install
    cd ${DEST_DIR}
fi

export PATH=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/:$PATH
export LD_LIBRARY_PATH=${DEST_DIR}/mpich-${MPI_VERSION}-install/lib/:$LD_LIBRARY_PATH
export CC=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpicc
export FC=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpifort
export F77=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpifort
export F90=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpifort

########################################################################
# Installing HDF5
########################################################################

if [ ${INST_HDF5} -eq 1 ]; then
    cd ${DEST_DIR}
    wget -q wget https://support.hdfgroup.org/ftp/HDF5/current18/src/hdf5-${HDF5_VERSION}.tar.gz \
	-O ${DEST_DIR}/hdf5-${HDF5_VERSION}.tar.gz
    tar xzf hdf5-${HDF5_VERSION}.tar.gz
    cd ${DEST_DIR}/hdf5-${HDF5_VERSION}/
    ./configure --prefix=${DEST_DIR}/hdf5-${HDF5_VERSION}-install \
	--enable-parallel --enable-fortran --enable-fortran2003 \
	--with-zlib --with-szlib
    make -j${MAKE_PROCS}
    make install
fi

########################################################################
# Installing PETSc
########################################################################

if [ ${INST_PETSC} -eq 1 ]; then
    cd ${DEST_DIR}
    wget -q http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-${PETSC_VERSION}.tar.gz \
	-O ./petsc-${PETSC_VERSION}.tar.gz
    tar xzf petsc-${PETSC_VERSION}.tar.gz
    cd petsc-${PETSC_VERSION}
    ./configure --with-debugging=0 \
	--with-shared-libraries=0 \
	--download-fblaslapack=1 \
	--download-superlu_dist=1 \
	--download-parmetis=1 \
	--download-superlu=1 \
	--download-hypre=1 \
	--download-scalapack=1 \
	--download-mumps=1 \
	--download-blacs=1 \
	--download-metis=1 \
	--with-mpi-dir=${DEST_DIR}/mpich-${MPI_VERSION}-install/lib/ \
	--prefix=${DEST_DIR}/petsc-${PETSC_VERSION}-install \
	--with-cc=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpicc \
	--with-cxx=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpic++ \
	--with-fc=${DEST_DIR}/mpich-${MPI_VERSION}-install/bin/mpifort
    make MAKE_NP=${MAKE_PROCS} $PETSC_DIR=${DEST_DIR}/petsc-${PETSC_VERSION} all
    make PETSC_DIR=${DEST_DIR}/petsc-${PETSC_VERSION} PETSC_ARCH=${PETSC_ARCH} install
fi

export PETSC_DIR=${DEST_DIR}/petsc-${PETSC_VERSION}-install/

########################################################################
# Compiling the HiFi solver directory, and creating a makefile that
# might or might not work.
########################################################################

if [ ${INST_HIFI_SOLVER} -eq 1 ]; then
    cd ${DEST_DIR}
    echo "You may need to enter your SourceRepo password at this point."
    svn co --username ${HIFI_USERNAME} https://hifi.sourcerepo.com/hifi/SEL/trunk ${DEST_DIR}/HiFi
    cd ${DEST_DIR}/HiFi/solver_${HIFI_SOLVER_VERSION}/
    
# Create a makefile with (hopefully) the correct links at the top.

    echo '# This makefile is automatically generated' > makefile_from_script
    echo '' >> makefile_from_script
    echo 'BUILD_DIR = ../../' 
    echo 'MPICH_DIR = $(BUILD_DIR)/mpich-'${MPI_VERSION}'-install/' >> makefile_from_script
    echo 'HDF5_DIR  = $(BUILD_DIR)/hdf5-'${HDF5_VERSION}'-install/' >> makefile_from_script
    echo 'PETSC_DIR = $(BUILD_DIR)/petsc-'${PETSC5_VERSION}'-install/' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# Set Fortran compiler flags' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'FFLAGS = -O3 \ ' >> makefile_from_script 
    echo '         -I$(PETSC_DIR)/include \ ' >> makefile_from_script
    echo '         -I$(PETSC_DIR)/$(PETSC_ARCH)/include \ ' >> makefile_from_script
    echo '         -I$(HDF5_DIR)/include \ ' >> makefile_from_script
    echo '         -I$(HDF5_DIR)/lib \ ' >> makefile_from_script
    echo '	   -I$(MPICH_DIR)/include \ '  >> makefile_from_script
    echo '         -L$(MPICH_DIR)/lib ' >> makefile_from_script
#-lmpichcxx -ldl -lpmpich -lmpich' >> makefile_from_script
    echo ' ' >> makefile_from_script
    echo ' # Next set variables for the Fortran compilers'  >> makefile_from_script
    echo 'FC = $(MPICH_DIR)/bin/mpifort $(FFLAGS)' >> makefile_from_script
    echo 'F90 = $(MPICH_DIR)/bin/mpifort $(FFLAGS)' >> makefile_from_script
    echo '' >> makefile_from_script
    echo ''
    echo '# Set whether of not to compile with Cubit capability using NetCDF' >> makefile_from_script
    echo '# Setting of CUBIT = true triggers compilation with Cubit capability' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'CUBIT = false' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'ifeq ($(CUBIT),true)' >> makefile_from_script
    echo '  job_objects = cubit.o job2_wcubit.o' >> makefile_from_script
    echo 'else' >> makefile_from_script
    echo '  job_objects = job2.o' >> makefile_from_script
    echo 'endif' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'OBJECTS = \ ' >> makefile_from_script
    echo '	io.o \ ' >> makefile_from_script
    echo '	local.o \ ' >> makefile_from_script
    echo '	debug.o \ ' >> makefile_from_script
    echo '	spline.o \ ' >> makefile_from_script
    echo '	bicube.o \ ' >> makefile_from_script
    echo '	jacobi.o \ ' >> makefile_from_script
    echo '	beltrami.o \ ' >> makefile_from_script
    echo '	extra.o \ ' >> makefile_from_script
    echo '	transport.o \ ' >> makefile_from_script
    echo '	$(job_objects) \ ' >> makefile_from_script
    echo '	p2_sel.o \ ' >> makefile_from_script
    echo '	p2_ct.o \ ' >> makefile_from_script
    echo '	p2_condense.o \ ' >> makefile_from_script
    echo '	p2_schur.o \ ' >> makefile_from_script
    echo '	p2_interior.o \ ' >> makefile_from_script
    echo '	p2_edge.o \ ' >> makefile_from_script
    echo '	p2_rj.o \ ' >> makefile_from_script
    echo '	fd.o \ ' >> makefile_from_script
    echo '	p2_diagnose.o \ ' >> makefile_from_script
    echo '	p2_snes.o \ ' >> makefile_from_script
    echo '	p2_grid.o \ ' >> makefile_from_script
    echo '	p2_advance.o \ ' >> makefile_from_script
    echo '	driver.o \ ' >> makefile_from_script
    echo ' ' >> makefile_from_script
    echo 'libsel: $(OBJECTS) chkopts' >> makefile_from_script
    echo '	ar -r libsel.a $(OBJECTS)' >> makefile_from_script
    echo '	rm -f *.cpp *.i ' >> makefile_from_script
    echo ' ' >> makefile_from_script
    echo 'include $(PETSC_DIR)/conf/variables' >> makefile_from_script
    echo 'include $(PETSC_DIR)/conf/rules' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# dependencies' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'local.o: io.o' >> makefile_from_script
    echo 'debug.o: local.o' >> makefile_from_script
    echo 'spline.o: local.o' >> makefile_from_script
    echo 'bicube.o: spline.o' >> makefile_from_script
    echo 'jacobi.o: local.o' >> makefile_from_script
    echo 'cubit.o: local.o' >> makefile_from_script
    echo 'beltrami.o: jacobi.o bicube.o' >> makefile_from_script
    echo 'extra.o: bicube.o' >> makefile_from_script
    echo 'transport.o: local.o' >> makefile_from_script
    echo 'job2_wcubit.o: cubit.o beltrami.o' >> makefile_from_script
    echo 'job2.o: beltrami.o' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'ifeq ($(CUBIT),true)' >> makefile_from_script
    echo '   p2_sel.o: job2_wcubit.o debug.o' >> makefile_from_script
    echo 'else ' >> makefile_from_script
    echo '   p2_sel.o: job2.o debug.o' >> makefile_from_script
    echo 'endif ' >> makefile_from_script
    echo ' ' >> makefile_from_script
    echo 'p2_diagnose.o: p2_sel.o' >> makefile_from_script
    echo 'p2_ct.o: p2_diagnose.o' >> makefile_from_script
    echo 'fd.o: p2_sel.o' >> makefile_from_script
    echo 'p2_condense.o: p2_sel.o' >> makefile_from_script
    echo 'p2_schur.o: p2_ct.o p2_condense.o' >> makefile_from_script
    echo 'p2_interior.o: p2_ct.o' >> makefile_from_script
    echo 'p2_edge.o: p2_ct.o' >> makefile_from_script
    echo 'p2_rj.o: p2_interior.o p2_edge.o p2_schur.o' >> makefile_from_script
    echo 'p2_snes.o: p2_rj.o' >> makefile_from_script
    echo 'p2_grid.o: p2_snes.o' >> makefile_from_script
    echo 'p2_advance.o: fd.o p2_grid.o' >> makefile_from_script
    echo 'driver.o: p2_advance.o' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'realclean: clean' >> makefile_from_script
    echo '	rm -f *.o *.mod *.diff *~ libsel.a' >> makefile_from_script
    echo '' >> makefile_from_script
  
    ln -s makefile_from_script makefile    
    
    make clean
    make -j${MAKE_NUM}
    
fi

########################################################################
# Compiling a HiFi executable
# Installing the HiFi solver directory, after creating a makefile that
# might or might not work.
########################################################################

if [ ${INST_HIFI_CODE} -eq 1 ]; then
    cd ${DEST_DIR}/HiFi/code_3.1/
    
    echo '# This is the makefile for HiFi with PETSc 3.5 on a workstation.' > makefile_from_script
    echo '#' >> makefile_from_script
    echo '# Before compiling SEL, export PHYSICS environment variable to be the' >> makefile_from_script
    echo '# name of the [physics_templ].f application file you would like to' >> makefile_from_script
    echo '# compile with the following command:' >> makefile_from_script
    echo '#' >> makefile_from_script
    echo '# export PHYSICS=physics_templ' >> makefile_from_script
    echo '#' >> makefile_from_script
    echo '# where 'physics_templ' should be replaced with the name of your' >> makefile_from_script
    echo '# physics application file.' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# environment variables' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'BUILD_DIR = ../../' >> makefile_from_script
    echo 'MPICH_DIR  = $(BUILD_DIR)/mpich-3.2-install/' >> makefile_from_script
    echo 'HDF5_DIR   = $(BUILD_DIR)/hdf5-1.8.18-install/' >> makefile_from_script
    echo 'PETSC_DIR  = $(BUILD_DIR)/petsc-3.5.4-install/' >> makefile_from_script
    echo 'HIFI_SOLVER_VERSION = 3.5' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'FFLAGS = -O3 \ ' >> makefile_from_script
    echo '         -I../solver_$(HIFI_SOLVER_VERSION) \ ' >> makefile_from_script
    echo '         -I$(HDF5_DIR)/include -I$(HDF5_DIR)/lib \ ' >> makefile_from_script
    echo '         -I$(PETSC_DIR)/include -I$(PETSC_DIR)/lib \ ' >> makefile_from_script
    echo '         -I$(MPICH_DIR)/include -I$(MPICH_DIR)/lib' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'LIBS = \ ' >> makefile_from_script
    echo '	-L../solver_${HIFI_SOLVER_VERSION} -lsel \ ' >> makefile_from_script
    echo '	$(PETSC_FORTRAN_LIB) \ ' >> makefile_from_script
    echo '	$(PETSC_LIB) \ ' >> makefile_from_script
    echo '	-L$(HDF5_DIR)/lib -lhdf5 -lhdf5_fortran \ ' >> makefile_from_script
    echo '	-Wl,-rpath,$(HDF5_DIR)/lib -lhdf5 -lhdf5_fortran' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# objects' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'OBJECTS = \ ' >> makefile_from_script
    echo '	$(PHYSICS).o' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# targets' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'all: libsel $(PHYSICS)' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'libsel:' >> makefile_from_script
    echo '	cd ../solver_$(HIFI_SOLVER_VERSION); make' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '$(PHYSICS): $(OBJECTS) chkopts' >> makefile_from_script
    echo '	$(FLINKER) -o $(PHYSICS) $(OBJECTS) $(LIBS)' >> makefile_from_script
    echo '	rm -f *.cpp *.i' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# includes' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'include $(PETSC_DIR)/conf/variables' >> makefile_from_script
    echo 'include $(PETSC_DIR)/conf/rules' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '# dependencies' >> makefile_from_script
    echo '' >> makefile_from_script
    echo '$(OBJECTS): ../solver_$(HIFI_SOLVER_VERSION)/libsel.a' >> makefile_from_script
    echo '' >> makefile_from_script
    echo 'realclean: clean' >> makefile_from_script
    echo '	rm -f *.o *.mod *.out *.bin *.dat *.fld *.diff *.err *~ temp* \ ' >> makefile_from_script
    echo '	sel.o* $(PHYSICS)' >> makefile_from_script
    echo '' >> makefile_from_script

    ln -s makefile_from_script makefile    
    make

    echo ''
    echo 'The HiFi physics module '${PHYSICS}' has been compiled.'
    echo 'A sample run with twenty processes would be:'
    echo ''
    echo '    mpiexec -np 20 '${DEST_DIR}${PHYSICS}' \ '
    echo '      -ksp_type gmres -pc_type asm -pc_asm_overlap 1 -sub_pc_type lu \ '
    echo '      -sub_pc_factor_mat_solver_package superlu_dist -ksp_rtol 1.e-10'
    echo ''
    echo 'It is important that you use mpiexec from the version of MPICH compiled'
    echo 'with this script.  It would be worthwhile to prepend the following '
    echo 'directory to your path:'
    echo ''
fi



echo 'It would be worthwhile to prepend your path variable to include MPICH.'
echo 'In csh/tsch you may do this with:'
echo ''
echo '   setenv '${DEST_DIR}'/mpich-'${MPI_VERSION}'-install/bin/:$PATH'
echo
cd ${DEST_DIR}
echo 'Installation script completed.'