# HiFi-installation-scripts

This repository contains scripts that can be used to install HiFi's
prerequisite libraries, and then HiFi.  The first script that is
included is designed to compile and link everything using GCC
compilers on a Linux workstation.  The script takes the approach of
building everything we need from scratch so it is all contained
together.  This compiles the MPICH, HDF5, and PETSc libraries.

## Instructions

In a terminal, run the following command:

```ShellSession
bash install.sh
```

## Disclaimer

These scripts might not work!
