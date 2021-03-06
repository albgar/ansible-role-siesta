#
SIESTA_ARCH=gfortran-full-options
#
# NOTE: This template is prepared to support versions
#       of Siesta with more features (e.g., the Max-1.0.X releases)
#       The functionalities not needed for 4.1 are commented out.
#       
#
# Machine specific settings might be:
#
# 1. Inherited from environmental variables
#    (paths, libraries, etc)
# 2. Set from a 'fortran.mk' file that is
#    included below (compiler names, flags, etc) (Uncomment first)
#
# NOTE: To be used with the "last" libgridxc of the 0.8 series,
#       without auto-tools support
#
#--------------------------------------------------------
# Use these symbols to request particular features
# To turn on, set '=1'.
#
WITH_FLOOK=
WITH_ELSI=
WITH_EXTERNAL_ELPA_IN_ELSI=
WITH_MPI=1
WITH_NETCDF={{ siesta_enable_netcdf }}
WITH_NCDF={{ siesta_enable_ncdf }}
# This will not work until libgridxc 0.9.X
WITH_GRID_SP=
#
#--------------------------------------------------------
# Make sure you have the appropriate symbols
# (Either explicitly here, or through shell variables, perhaps
#  set by a module system)
#
#--------------------------------------------------------
#XMLF90_ROOT={{ siesta_xmlf90_root }}
#PSML_ROOT={{ siesta_psml_root }}
#GRIDXC_ROOT={{ siesta_gridxc_root }}
#LIBXC_ROOT={{ siesta_libxc_root }}
#ELSI_ROOT=
#ELPA_ROOT=
#ELPA_INCLUDE_DIRECTORY=
#FLOOK_ROOT=
#--------------------------------------------------------
#NETCDF_ROOT=
NETCDF_INCFLAGS={{ siesta_netcdf_incflags }}
NETCDF_LIBS={{ siesta_netcdf_libs }}
SCALAPACK_LIBS={{ siesta_scalapack_libs }}
LAPACK_LIBS={{ siesta_lapack_libs }}
#FFTW_ROOT=
# Needed for PEXSI (ELSI) support
#LIBS_CPLUS=-lstdc++ 
#--------------------------------------------------------
#
# Define compiler names and flags
#
FC_PARALLEL=mpif90
FC_SERIAL=gfortran
FPP = $(FC_SERIAL) -E -P -x c
FFLAGS = -O2 
FFLAGS_DEBUG= -g -O0
RANLIB=echo
#
# Alternatively, prepare a fortran.mk file with compiler definitions,
# put it in this same directory, and uncomment the two lines below
#
### SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
### include $(SELF_DIR)fortran.mk
#
#-----------------------------------------
# Possible section on specific recipes for troublesome files, using
# a lower optimization level.
#
#atom.o: atom.F
#	$(FC) -c $(FFLAGS_DEBUG) $(INCFLAGS) $(FPPFLAGS) $< 
#
# Note that simply using target-specific variables, such as:
#atom.o: FFLAGS=$(FFLAGS_DEBUG)
# would compile *all* dependencies of atom.o with that setting...
#
#--------------------------------------------------------
# Nothing should need to be changed below
#--------------------------------------------------------
#
FC_ASIS=$(FC_SERIAL)
COMP_LIBS=
#
ifdef WITH_GRID_SP
   $(error GRID_SP option does not work with libgridxc < 0.9.X)
endif
#

FPPFLAGS= -DF2003 

LIBS=

ifdef WITH_ELSI
 ifndef ELSI_ROOT
   $(error you need to define ELSI_ROOT in your arch.make)
 endif
 #  Add the second symbol for MAGMA and EigenExa support
 FPPFLAGS_ELSI=-DSIESTA__ELSI # -DSIESTA__ELSI_2_4_SOLVERS

 ELSI_INCFLAGS = -I$(ELSI_ROOT)/include

 ifdef WITH_EXTERNAL_ELPA_IN_ELSI
   ifndef ELPA_ROOT
     $(error you need to define ELPA_ROOT in your arch.make)
   endif
   ifndef ELPA_INCLUDE_DIRECTORY
     # It cannot be generated directly from ELPA_ROOT...
     $(error you need to define ELPA_INCLUDE_DIRECTORY in your arch.make)
   endif
   ELSI_INCFLAGS += -I$(ELPA_INCLUDE_DIRECTORY)
   #ELPA_ROOT=/path/to/external/elpa/installation
 else
   ELPA_ROOT=$(ELSI_ROOT)
 endif
  ELSI_LIB = -L$(ELSI_ROOT)/lib -lelsi \
               -lfortjson -lOMM -lMatrixSwitch \
               -lNTPoly -lpexsi -lsuperlu_dist \
               -lptscotchparmetis -lptscotch -lptscotcherr \
               -lscotchmetis -lscotch -lscotcherr \
               -L$(ELPA_ROOT)/lib -lelpa

  INCFLAGS += $(ELSI_INCFLAGS)
  FPPFLAGS += $(FPPFLAGS_ELSI)
  LIBS +=$(ELSI_LIB) $(LIBS_CPLUS)
endif

ifdef WITH_NETCDF
 ifndef NETCDF_INCFLAGS
   $(error you need to define NETCDF_INCFLAGS in your arch.make)
 endif
 ifndef NETCDF_LIBS
   $(error you need to define NETCDF_LIBS in your arch.make)
 endif
# NETCDF_INCFLAGS=-I$(NETCDF_ROOT)/include
# NETCDF_LIBS= -L$(NETCDF_ROOT)/lib -lnetcdff
 FPPFLAGS_CDF= -DCDF
 INCFLAGS += $(NETCDF_INCFLAGS)
 LIBS += $(NETCDF_LIBS)
endif
#
ifdef WITH_NCDF
 ifndef WITH_NETCDF
   $(error For NCDF you need to define also WITH_NETCDF in your arch.make)
 endif
 FPPFLAGS += -DNCDF -DNCDF_4
 COMP_LIBS += libncdf.a libfdict.a
endif
#
ifdef WITH_FLOOK
 ifndef FLOOK_ROOT
   $(error you need to define FLOOK_ROOT in your arch.make)
 endif
 FLOOK_INCFLAGS=-I$(FLOOK_ROOT)/include
 INCFLAGS += $(FLOOK_INCFLAGS)
 FLOOK_LIBS= -L$(FLOOK_ROOT)/lib -lflookall -ldl
 FPPFLAGS_FLOOK= -DSIESTA__FLOOK
 LIBS +=$(FLOOK_LIBS)
 COMP_LIBS+= libfdict.a
endif
#
ifdef WITH_MPI
 FC=$(FC_PARALLEL)
 MPI_INTERFACE=libmpi_f90.a
 MPI_INCLUDE=.      # Note . for no-op
 FPPFLAGS_MPI=-DMPI -DMPI_TIMING
 LIBS +=$(SCALAPACK_LIBS)
 LIBS +=$(LAPACK_LIBS)
else
 FC=$(FC_SERIAL)
 LIBS += $(LAPACK_LIBS) $(COMP_LIBS)
endif

SYS=nag
FPPFLAGS += $(FPPFLAGS_CDF) $(FPPFLAGS_GRID) $(FPPFLAGS_MPI) $(FPPFLAGS_FLOOK)
#
# These lines make use of a custom mechanism to generate library lists and
# include-file management. The mechanism is not implemented in all libraries.
#---------------------------------------------
#include $(XMLF90_ROOT)/share/org.siesta-project/xmlf90.mk
#include $(PSML_ROOT)/share/org.siesta-project/psml.mk
#include $(GRIDXC_ROOT)/gridxc.mk
#
# We assume that libgridxc
# includes libxc. If not, delete '-lxc90 -lxc' from GRIDXC_LIBS above.
#---------------------------------------------
.c.o:
	$(CC) -c $(CFLAGS) $(INCFLAGS) $(CPPFLAGS) $< 
.F.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS) $(FPPFLAGS) $(FPPFLAGS_fixed_F)  $< 
.F90.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS) $(FPPFLAGS) $(FPPFLAGS_free_F90) $< 
.f.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS) $(FCFLAGS_fixed_f)  $<
.f90.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS) $(FCFLAGS_free_f90)  $<

