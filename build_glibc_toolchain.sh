#! /bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will download packages for, configure, build and install a GCC cross-compiler.
# Customize the variables (INSTALL_PATH, TARGET, etc.) to your liking before running.
# If you get an error and need to resume the script from some point in the middle,
# just delete/comment the preceding lines before running it again.
#
# See: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
#-------------------------------------------------------------------------------------------

TARGET=arc-snps-linux-gnu
INSTALL_PATH=${INSTALL_DIR}
LINUX_ARCH=arc
PARALLEL_MAKE=-j8
#BINUTILS_VERSION=binutils-2.24
BINUTILS_VERSION=source/binutils
#GCC_VERSION=gcc-4.9.2
GCC_VERSION=source/gcc_6.0
#LINUX_KERNEL_VERSION=linux-3.17.2
LINUX_KERNEL_VERSION=source/linux
#GLIBC_VERSION=glibc-2.20
GLIBC_VERSION=source/glibc
#MPFR_VERSION=mpfr-3.1.2
#GMP_VERSION=gmp-6.0.0a
#MPC_VERSION=mpc-1.0.2
#ISL_VERSION=isl-0.12.2
#CLOOG_VERSION=cloog-0.18.1
export PATH=$INSTALL_PATH/bin:$PATH

# Step 1. Binutils
if true; then
mkdir -p ${BUILD_DIR}/binutils
cd ${BUILD_DIR}/binutils
${SOURCE_DIR}/binutils/configure --prefix=$INSTALL_PATH --target=$TARGET --with-cpu=${ARC_MULTILIB_OPTIONS} $CONFIGURATION_OPTIONS --disable-gdb
make $PARALLEL_MAKE
make install
cd -

# Step 2. Linux Kernel Headers
if [ $USE_NEWLIB -eq 0 ]; then
    cd ${SOURCE_DIR}/linux
    make distclean
    make ARCH=$LINUX_ARCH INSTALL_HDR_PATH=$INSTALL_PATH/$TARGET/usr headers_install
    cd -
fi

# Step 3. C/C++ Compilers
mkdir -p ${BUILD_DIR}/gcc
cd ${BUILD_DIR}/gcc
if [ $USE_NEWLIB -ne 0 ]; then
    NEWLIB_OPTION=--with-newlib
fi
${SOURCE_DIR}/gcc_6.0/configure --prefix=$INSTALL_PATH --target=$TARGET --with-cpu=${ARC_MULTILIB_OPTIONS} --with-headers=$INSTALL_PATH/$TARGET/usr/include --enable-languages=c,c++ $CONFIGURATION_OPTIONS $NEWLIB_OPTION
make $PARALLEL_MAKE all-gcc
make install-gcc
cd -

fi

if [ $USE_NEWLIB -ne 0 ]; then
    # Steps 4-6: Newlib
    mkdir -p ${BUILD_DIR}/newlib
    cd ${BUILD_DIR}/newlib
    ${SOURCE_DIR}/newlib/configure --prefix=$INSTALL_PATH --target=$TARGET --with-cpu=${ARC_MULTILIB_OPTIONS} $CONFIGURATION_OPTIONS
    make $PARALLEL_MAKE
    make install
    cd -
else
    # Step 4. Standard C Library Headers and Startup Files
    mkdir -p ${BUILD_DIR}/glibc
    cd ${BUILD_DIR}/glibc
    ${SOURCE_DIR}/glibc/configure --prefix=$INSTALL_PATH/$TARGET --build=$MACHTYPE --host=$TARGET --target=$TARGET --with-headers=$INSTALL_PATH/$TARGET/usr/include $CONFIGURATION_OPTIONS --disable-werror --enable-obsolete-rpc libc_cv_forced_unwind=yes libc_cv_ssp=no --enable-static-nns --enable-debug #LDFLAGS='-Wl,-q'
    #${SOURCE_DIR}/glibc/configure --prefix=/usr --build=$MACHTYPE --host=$TARGET --with-headers=$INSTALL_PATH/$TARGET/usr/include $CONFIGURATION_OPTIONS --disable-werror --enable-obsolete-rpc libc_cv_forced_unwind=yes libc_cv_ssp=no --enable-static-nns --enable-debug --disable-sanity-checks
    make install-bootstrap-headers=yes install-headers #DESTDIR=$INSTALL_PATH/$TARGET
    make $PARALLEL_MAKE csu/subdir_lib
    install csu/crt1.o csu/crti.o csu/crtn.o $INSTALL_PATH/$TARGET/lib
    $TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $INSTALL_PATH/$TARGET/lib/libc.so
    touch $INSTALL_PATH/$TARGET/include/gnu/stubs.h
    cd -

    # Step 5. Compiler Support Library
    cd ${BUILD_DIR}/gcc
    make $PARALLEL_MAKE all-target-libgcc
    make install-target-libgcc
    cd -

    # Step 6. Standard C Library & the rest of Glibc
    cd ${BUILD_DIR}/glibc
    rm -f $INSTALL_PATH/$TARGET/lib/csu/crt1.o 
    rm -f $INSTALL_PATH/$TARGET/lib/csu/crti.o 
    rm -f $INSTALL_PATH/$TARGET/lib/csu/crtn.o 
    rm -f $INSTALL_PATH/$TARGET/lib/libc.so
    rm -f $INSTALL_PATH/$TARGET/include/gnu/stubs.h
    make $PARALLEL_MAKE
    make install #DESTDIR=$INSTALL_PATH/$TARGET
    cd -
fi

# Step 7. Standard C++ Library & the rest of GCC
cd ${BUILD_DIR}/gcc
make $PARALLEL_MAKE all
make install
cd -

trap - EXIT
echo 'Success!'
