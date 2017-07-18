#!/bin/bash

########################################################################
# Experimental HiFi installation script for gfortran on Linux that
# might also work on Macs.
#
# Run this script with the following command:
#
#    bash install.sh | tee -a install.log
#
# The screen output will be appended to: install.log
#
# This script has only been tested on a limited number of platforms,
# and thus some part of it may fail.  Some troubleshooting options
# include:
#
#  - If the wget commands don't work, you may need to update the link
#    to the gzipped tar file containing the library.  The websites
#    change over time.
#
#  - If the PETSc configure script doesn't work, then you may need to
#    set PYTHON to the path for a version of Python 2.
#
#  - The PETSC_ARCH variable must be consistent between this script and
#    the makefiles in the solver and code directories.
#
#  - You may need to install or update the GCC family of compilers,
#    and possibly link their full path.  These compilers include
#    gfortran, gcc, and g++.  This script and associated makefiles are
#    unlikely to work with Intel compilers.
#
#  - If you have more than one family of compilers installed on your
#    system, it is possible that not all libraries will be compiled
#    with the same compilers.  Removing other compilers from your PATH
#    and LD_LIBRARY_PATH system variables may be necessary.
#
#  - The configuration options may change for newer versions of
#    different libraries.
#
#  - This script is not intended for supercomputers.
#
# This script was written by Nick Murphy, who is bad at responding to
# emails but can ideally be reached at namurphy@cfa.harvard.edu if you
# happen to run into problems.
########################################################################

########################################################################
# Specify what libraries to install.  Set the variable to 1 to install
# the corresponding library, and 0 to skip it.
########################################################################

INST_MPICH=1
INST_HDF5=1
INST_PETSC=1
INST_LAPACK=1
INST_HIFI_SOLVER=1
INST_HIFI_PHYSICS=1
INST_HIFI_POST=1

########################################################################
# Specify physics module
########################################################################

export PHYSICS=pn_ext

########################################################################
# Specify which compilers to use.  The GCC compilers are gcc, g++, and
# gfortran.  The Intel compilers are icc, icpc, and ifort but are
# untested with the script and need different makefiles.
########################################################################

export CC="gcc"
export CXX="g++"
export CPP="gcc -E"
export FC="gfortran"
export F9X="gfortran"
export F77="gfortran"
export FCFLAGS=""
export CFLAGS=""
export CXXFLAGS=""

########################################################################
# Select which versions of the different libraries to use.  
#
# PETSC_VERSION must be consistent with HIFI_SOLVER_VERSION (e.g., use
# PETSC_VERSION 3.5.4 with solver_3.5).
#
# The two options for HDF5_VERSION are "1.8.18" (which is older) and
# "1.10.1" (current as of mid-2017).
#
# The LAPACK installation might not work on Ubuntu 16.04.  However,
# LAPACK might be able to be installed with apt-get instead in which
# case it would be necessary to change the post makefile.
########################################################################

MPI_VERSION="3.2"
HDF5_VERSION="1.10.1"
PETSC_VERSION="3.5.4"
PETSC_ARCH="linux-gnu"
LAPACK_VERSION="3.7.0"
HIFI_SOLVER_VERSION="3.5"

########################################################################
# Set MAKE_PROCS to the number of processors to be used during the
# compilation process.
########################################################################

if [ -e /proc/cpuinfo ]; then
    MAKE_PROCS=`grep -c ^processor /proc/cpuinfo`
else
    MAKE_PROCS=4
fi

########################################################################
# Attempt to find the path to Python 2 which is required in some PETSc
# compile scripts (including PETSc 3.5.4).  This variable may also be
# set manually.
########################################################################

if [ -n $(which python2) ] ; then
    PYTHON=$(which python2)
elif [ -n $(which python2.7) ] ; then
    PYTHON=$(which python2.7)
elif [ -n $(which python2.6) ] ; then
    PYTHON=$(which python2.6)
elif [ -n $(which python) ] ; then
    PYTHON=$(which python)
fi

########################################################################
# Specify the location where the libraries should be installed
########################################################################

TOP_DIR=`pwd`
DEST_DIR=${TOP_DIR}"/lib"

########################################################################
# Screen output
########################################################################

echo "************************************************************************"
echo "Beginning HiFi installation script at "`date`
echo "************************************************************************"

if [ -n $(which ifort) ] ; then
    echo "Warning: An Intel compiler is included in your path at:"
    echo "  "$(which ifort)
    echo "Errors may arise if some libraries are compiled with gfortran/gcc/g++"
    echo "and other libraries are compiled with ifort/icc/icpc.  If you run into"
    echo "problems, try removing the directories containing Intel compiers from"
    echo "your PATH system variable (and possibly also from LD_LIBRARY_PATH)."
    echo "************************************************************************"
fi

echo "Base Directory: "${TOP_DIR}
echo "Lib directory:  "${DEST_DIR}
echo "************************************************************************"
echo "INST_MPICH  = "${INST_MPICH}
echo "INST_HDF5   = "${INST_HDF5}
echo "INST_PETSC  = "${INST_MPICH}
echo "INST_LAPACK = "${INST_MPICH}
echo "INST_HIFI_SOLVER  ="${INST_HIFI_SOLVER}
echo "INST_HIFI_PHYSICS ="${INST_HIFI_PHYSICS}
echo "INST_HIFI_POST    ="${INST_HIFI_POST}
echo "************************************************************************"
echo "MPI_VERSION = "${MPI_VERSION}
echo "HDF5_VERSION = "${HDF5_VERSION}
echo "PETSC_VERSION = "${PETSC_VERSION}
echo "PETSC_ARCH = "${PETSC_ARCH}
echo "LAPACK_VERSION = "${LAPACK_VERSION}
echo "************************************************************************"
echo "CC = "${CC}
echo "CXX = "${CXX}
echo "CPP = "${CPP}
echo "FC = "${FC}
echo "F9X = "${F9X}
echo "F77 = "${F77}
echo "FCFLAGS = "${FCFLAGS}
echo "CFLAGS = "${CFLAGS}
echo "CXXFLAGS = "${CXXFLAGS}
echo "************************************************************************"
echo "The PETSc install requires Python 2.  The Python excecutable is"
echo "PYTHON = "${PYTHON}
echo "The Python version is:"
${PYTHON} --version
echo "If this is not Python 2 (preferably Python 2.7) then the PYTHON variable"
echo "may need to be set manually in the install script."
echo "************************************************************************"


if [ ! -d "$DEST_DIR" ]; then
    echo "Creating "${DEST_DIR}
    mkdir ${DEST_DIR}
else
    echo "Using existing library destination directory:"
    echo ${DEST_DIR}
fi
echo "************************************************************************"

if [ ! -e install.sh ]; then
    cat install.sh
fi

########################################################################
# Specify library locations
########################################################################

MPI_DIR=${DEST_DIR}/mpich-${MPI_VERSION}-install
HDF5_DIR=${DEST_DIR}/hdf5-${HDF5_VERSION}
PETSC_DIR=${DEST_DIR}/petsc-${PETSC_VERSION}
LAPACK_DIR=${DEST_DIR}/lapack-${LAPACK_VERSION}

########################################################################
# Installing MPICH
########################################################################

if [ ${INST_MPICH} -eq 1 ]; then
    echo "************************************************************************"
    echo "Beginning MPICH installation"
    echo "************************************************************************"
    cd ${DEST_DIR}
    echo "Downloading MPICH tarball"
    if [ ! -e mpich-${MPI_VERSION}.tar.gz ]; then
	wget -q http://www.mpich.org/static/downloads/${MPI_VERSION}/mpich-${MPI_VERSION}.tar.gz \
	    -O ${DEST_DIR}/mpich-${MPI_VERSION}.tar.gz
    fi
    tar xzf mpich-${MPI_VERSION}.tar.gz
    cd ${DEST_DIR}/mpich-${MPI_VERSION}
    echo "************************************************************************"
    echo "Running configure for MPICH"
    echo "************************************************************************"
    ./configure --prefix=${MPI_DIR} CC=${CC} CXX=${CXX} FC=${FC} F77=${F77} 
    echo "************************************************************************"
    echo "Running make for MPICH"
    echo "************************************************************************"
    make -j${MAKE_PROCS} 
    echo "************************************************************************"
    echo "Running make install for MPICH"
    echo "************************************************************************"
    make install
    cd ${DEST_DIR}
    echo "************************************************************************"
    echo "MPICH installation complete"
    echo "************************************************************************"
else
    echo "Skipping MPICH installation"
fi

echo "************************************************************************"
echo "Prepending following directory to PATH:"
export MPI_BIN_DIR=${MPI_DIR}/bin
export PATH=${MPI_BIN_DIR}:$PATH
echo ${MPI_BIN_DIR}
echo "************************************************************************"
echo "Prepending following directory to LD_LIBRARY_PATH:"
export MPI_LDLIBPATH_DIR=${MPI_DIR}/lib
export LD_LIBRARY_PATH=${MPI_LDLIBPATH_DIR}:$LD_LIBRARY_PATH
echo ${MPI_LDLIBPATH_DIR}
echo "************************************************************************"
echo "Updating compiler system variables to compiled version of MPICH:"
export CC=${MPI_BIN_DIR}/mpicc
export FC=${MPI_BIN_DIR}/mpifort
export F77=${MPI_BIN_DIR}/mpifort
export F90=${MPI_BIN_DIR}/mpifort
echo "CC = "${CC}
echo "FC = "${FC}
echo "F77 = "${F77}
echo "F90 = "${F90}
echo "************************************************************************"

########################################################################
# Installing HDF5
########################################################################

if [ ${INST_HDF5} -eq 1 ]; then
    cd ${DEST_DIR}
    echo "Beginning HDF5 installation"

    if [ ! -e hdf5-${HDF5_VERSION}.tar.gz ]; then
	echo "Downloading and extracting HDF5 tarball"
	if [ ${HDF5_VERSION} = 1.8.18 ]; then
	    wget -q https://support.hdfgroup.org/ftp/HDF5/current18/src/hdf5-${HDF5_VERSION}.tar.gz \
		-O ${DEST_DIR}/hdf5-${HDF5_VERSION}.tar.gz
	else
	    wget -q https://support.hdfgroup.org/ftp/HDF5/current/src/hdf5-${HDF5_VERSION}.tar.gz \
		-O ${DEST_DIR}/hdf5-${HDF5_VERSION}.tar.gz	    
	fi
	tar xzf hdf5-${HDF5_VERSION}.tar.gz
    else
	echo "Using existing HDF5 tarball"
    fi

    cd ${DEST_DIR}/hdf5-${HDF5_VERSION}
    pwd
    echo "************************************************************************"
    echo "Running configure for HDF5"
    echo "************************************************************************"
    ./configure --prefix=${HDF5_DIR} \
	--enable-parallel --enable-fortran --enable-fortran2003 \
	--with-zlib --with-szlib
    echo "************************************************************************"
    echo "Running make for HDF5"
    echo "************************************************************************"
    make -j${MAKE_PROCS}
    echo "************************************************************************"
    echo "Running make install for HDF5"
    echo "************************************************************************"
    make install
    echo "HDF5 installation complete"
else
    echo "Skipping HDF5 installation"
fi

echo "************************************************************************"

########################################################################
# Installing PETSc
########################################################################

if [ ${INST_PETSC} -eq 1 ]; then
    cd ${DEST_DIR}
    echo "Beginning PETSc installation"
    echo "Downloading and extracting PETSc tarball"
    echo "************************************************************************"
    if [ ! -e petsc-${PETSC_VERSION}.tar.gz ]; then
	wget -q http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-${PETSC_VERSION}.tar.gz \
	    -O ./petsc-${PETSC_VERSION}.tar.gz
    fi
    tar xzf petsc-${PETSC_VERSION}.tar.gz
    cd petsc-${PETSC_VERSION}
    echo "************************************************************************"
    echo "Running configure for PETSc"
    echo "************************************************************************"
    ${PYTHON} ./configure \
	PETSC_ARCH=${PETSC_ARCH} \
	--with-debugging=0 \
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
	--with-mpi-dir=${MPI_DIR}/lib \
	--with-cc=${MPI_DIR}/bin/mpicc \
	--with-cxx=${MPI_DIR}/bin/mpic++ \
	--with-fc=${MPI_DIR}/bin/mpifort
    echo "************************************************************************"
    echo "Running make all for PETSc" 
    echo "************************************************************************"
    make MAKE_NP=${MAKE_PROCS} PETSC_DIR=${PETSC_DIR} PETSC_ARCH=${PETSC_ARCH} all
    # Running make install is not necessary if PETSC_ARCH is set.
    echo "************************************************************************"
    echo "End of PETSc installation"
else
    echo "Skipping PETSc installation"
fi

echo "************************************************************************"

export PETSC_DIR=${PETSC_DIR}

########################################################################
# Installing LAPACK
########################################################################

if [ ${INST_LAPACK} -eq 1 ]; then
    echo "Installing PETSc"
    cd ${DEST_DIR}
    echo "************************************************************************"
    echo "Downloading and extracting LAPACK tarball"
    echo "************************************************************************"
    if [ ! -e lapack-${LAPACK_VERSION}.tgz ]; then
	wget -q http://www.netlib.org/lapack/lapack-${LAPACK_VERSION}.tgz \
	    -O ./lapack-${LAPACK_VERSION}.tgz
    fi
    tar xzf lapack-${LAPACK_VERSION}.tgz
    echo "************************************************************************"
    echo "Running make blaslib for LAPACK installation"
    echo "************************************************************************"
    cd lapack-${LAPACK_VERSION}
    cp make.inc.example make.inc
    make blaslib -j${MAKE_PROCS}
    echo "************************************************************************"
    echo "Running make for LAPACK installation"
    echo "************************************************************************"
    make -j${MAKE_PROCS}
    echo "************************************************************************"
    echo "End of LAPACK installation"
else
    echo "Skipping LAPACK installation"
fi

echo "************************************************************************"
export LAPACK_DIR=${LAPACK_DIR}

########################################################################
# Installing HiFi solver directory
########################################################################

if [ ${INST_HIFI_SOLVER} -eq 1 ]; then
    echo "Compiling HiFi solver library"
    echo "************************************************************************"
    cd ${TOP_DIR}/solver_${HIFI_SOLVER_VERSION}
    if [ ! -e Makefile ]; then
	ln -s makefile_gfortran_solver Makefile
    fi
    make -j${MAKE_PROCS}
    echo "************************************************************************"
    echo "End of HiFi solver library compilation"
    echo "************************************************************************"
else
    echo "Skipping compilation of HiFi solver library"
    echo "*******************************************************************"
fi

if [ ${INST_HIFI_POST} -eq 1 ]; then
    echo "Compiling HiFi post"
    echo "************************************************************************"
    cd ${TOP_DIR}/post
    if [ ! -e Makefile ]; then
	ln -s makefile_gfortran_post Makefile
    fi
    make -j${MAKE_PROCS}
    echo "************************************************************************"
    echo "End of HiFi post compilation"
    echo "************************************************************************"
else
    echo "Skipping compilation of post"
    echo "*******************************************************************"
fi

if [ ${INST_HIFI_PHYSICS} -eq 1 ]; then
    echo "Compiling HiFi physics module: "${PHYSICS}
    echo "************************************************************************"
    cd ${TOP_DIR}/code_3.1
    if [ ! -e Makefile ]; then
        ln -s makefile_gfortran_code Makefile
    fi
    make -j${MAKE_PROCS}
    echo "************************************************************************"
    echo "End of HiFi physics compilation"
    echo "************************************************************************"
fi

echo 'The mpifort and mpicc compilers from this version of MPICH may be added'
echo 'to your path with the following command (in csh/tsch):'
echo ''
echo '   setenv ${PATH} '${DEST_DIR}'/mpich-'${MPI_VERSION}'-install/bin/:$PATH'
echo "************************************************************************"
echo "HiFi library installation script completed at "`date`

if [ ! -e ${TOP_DIR}/solver_${HIFI_SOLVER_VERSION}/libsel.a ]; then
    echo "warning: libsel.a does not exist in solver directory" 
fi

if [ ! -e ${TOP_DIR}/code_3.1 ]; then
    echo "warning: "${PHYSICS}" does not exist in solver directory" 
fi

if [ ! -e ${TOP_DIR}/post/post ]; then
    echo "warning: post does not exist in post directory" 
fi

echo "************************************************************************"
echo "Ending install script at "`date`
echo "************************************************************************"
