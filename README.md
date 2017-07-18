# HiFi-installation-scripts

This repository contains scripts that can be used to install HiFi's
prerequisite libraries, and then HiFi.  The script `install.sh` was
originally designed to compile and link everything using GCC compilers
on a Linux workstation, and may also work on a Mac.  This script takes
the approach of compiling everything from scratch so it is all
contained together.  The MPICH, HDF5, and PETSc libraries are compiled
for the code and solver builds in HiFi, and LAPACK is additionally
compiled for the post build in HiFi.

## Instructions

In a terminal, run the following command:

```ShellSession
bash install.sh
```

## Disclaimer

This script is experimental and therefore may break!
