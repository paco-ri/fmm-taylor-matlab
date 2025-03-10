# for experts, location of mwrap executable
MWRAP_INSTALL = ${HOME}/mwrap/mwrap

###########################################
# you should not have to edit anything else
###########################################
FMM3DBIE_STATIC_INSTALL = ${HOME}/fmm3dbie/lib-static/libfmm3dbie_matlab.a
MAGNETOSTATICS = fortran/magneto-static-routs.o
MAGNETODYNAMICS = fortran/magneto-dynamic-routs.o
HELPER = fortran/fmm-helper-routs.o

install:
	$(FC) -c $(FFLAGS) fortran/magneto-static-routs.f90 -o fortran/magneto-static-routs.o
	$(FC) -c $(FFLAGS) fortran/magneto-dynamic-routs.f90 -o fortran/magneto-dynamic-routs.o
	$(FC) -c $(FFLAGS) fortran/fmm-helper-routs.f90 -o fortran/fmm-helper-routs.o
	$(FC) -c $(FFLAGS) fortran/surf_routs.f90 -o fortran/surf_routs.o
	mkdir -p lib
	mkdir -p lib-static
	cd lib && rm -rf *
	cd lib-static && rm -rf * && ar -x $(FMM3DBIE_STATIC_INSTALL) && cp ../fortran/magneto-static-routs.o . && cp ../fortran/magneto-dynamic-routs.o . && cp ../fortran/surf_routs.o surf_routs2.o && ar rcs libvirtualcasing.a *.o && rm -f *.o
	$(FC) -shared $(FFLAGS) -Wl,--whole-archive lib-static/libvirtualcasing.a -Wl,--no-whole-archive -o libvirtualcasing.so -lm -lstdc++ -lgomp -lblas -llapack
	mv libvirtualcasing.so lib/

mex:
	$(MWRAP_INSTALL) -c99complex -list -mex gradcurlS0 -mb gradcurlS0.mw
	$(MWRAP_INSTALL) -c99complex -mex gradcurlS0 -c gradcurlS0.c gradcurlS0.mw
	$(MWRAP_INSTALL) -c99complex -list -mex gradcurlSk -mb gradcurlSk.mw
	$(MWRAP_INSTALL) -c99complex -mex gradcurlSk -c gradcurlSk.c gradcurlSk.mw
	$(MWRAP_INSTALL) -c99complex -list -mex helper -mb helper.mw
	$(MWRAP_INSTALL) -c99complex -mex helper -c helper.c helper.mw

matlab:
	mkdir -p +taylor/+static/
	mex gradcurlS0.c $(FMM3DBIE_STATIC_INSTALL) $(MAGNETOSTATICS) -compatibleArrayDims -DMWF77_UNDERSCORE1 "CFLAGS=-std=gnu17 -Wno-implicit-function-declaration -fPIC" -output gradcurlS0 -lm -lstdc++ -ldl -lgfortran -lgomp -lmwblas -lmwlapack
	mkdir -p +taylor/+dynamic/
	mex gradcurlSk.c $(FMM3DBIE_STATIC_INSTALL) $(MAGNETODYNAMICS) -compatibleArrayDims -DMWF77_UNDERSCORE1 "CFLAGS=-std=gnu17 -Wno-implicit-function-declaration -fPIC" -output gradcurlSk -lm -lstdc++ -ldl -lgfortran -lgomp -lmwblas -lmwlapack
	mkdir -p +taylor/+helper/
	mex helper.c $(FMM3DBIE_STATIC_INSTALL) $(HELPER) $(MAGNETODYNAMICS) -compatibleArrayDims -DMWF77_UNDERSCORE1 "CFLAGS=-std=gnu17 -Wno-implicit-function-declaration -fPIC" -output helper -lm -lstdc++ -ldl -lgfortran -lgomp -lmwblas -lmwlapack

FC = gfortran
FFLAGS = -fPIC -O3 -march=native -funroll-loops -std=legacy -w
OMPFLAGS = -fopenmp
FFLAGS += $(OMPFLAGS)
FFLAGS += -J .mod/
