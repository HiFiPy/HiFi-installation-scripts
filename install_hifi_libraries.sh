#!/bin/bash

# HiFi installation script using gfortran
#
# To run this script, run the following command in a terminal:
#
#    bash install_hifi_libraries.sh

# First set the destination directory.  The default is to install in
# the current directory.  Another option is: DEST_DIR="~/lib/"

DEST_DIR=`pwd`"/"

# Specify what prerequisite libraries to install, and whether or not
# you want to check out HiFi using your login from SourceRepo

INST_MPICH=1
INST_HDF5=1
INST_PETSC=1
CHECKOUT_HIFI=1

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

MAKE_PROCS="4" 

# Select which versions of the different libraries to use.  Note that 

MPI_VERSION="3.2"
HDF5_VERSION="1.8.18"
PETSC_VERSION="3.5.4"
PETSC_ARCH="build"

# If you wish to check out HiFi, please enter your username.  You may
# need to input your password later in this script.

HIFI_USERNAME="namurphy"

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

if [ ${CHECKOUT_HIFI} -eq 1 ]; then
    cd ${DEST_DIR}
    echo "You may need to enter your SourceRepo password at this point."
    svn co --username ${HIFI_USERNAME} https://hifi.sourcerepo.com/hifi/SEL/trunk ${DEST_DIR}/HiFi
fi

echo 'It would be worthwhile to prepend your path variable to include MPICH.'
echo 'In csh/tsch you may do this with:'
echo ''
echo '   setenv '${DEST_DIR}'/mpich-'${MPI_VERSION}'-install/bin/:$PATH'
echo
cd ${DEST_DIR}
echo 'Installation script completed.'