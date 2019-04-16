export TARGET=arc-snps-linux-gnu

export ARC_VERSION=hs
#export ARC_VERSION=700

export ELF_TOOLCHAIN=n
export UCLIBC_TOOLCHAIN=n
export GLIBC_TOOLCHAIN=y
export ENDIANESS=little #big

# ------------- DONT CHANGE BELOW THIS LINE -------------------

export CURRENT_PATH=`pwd`
export WORKSPACE_DIR=/workspace
export SOURCE_DIR=/source
export BUILD_DIR=${WORKSPACE_DIR}/build
export INSTALL_DIR=/usr/local/

export PATH=${INSTALL_DIR}/bin:${PATH}

export DEJAGNU=${SOURCE_DIR}/toolchain/site.exp
export ARC_MULTILIB_OPTIONS=archs

export SYSROOT_DIR=${INSTALL_DIR}/arc-snps-linux-gnu/sysroot

export USE_NEWLIB=0
export CONFIGURATION_OPTIONS="--disable-multilib --disable-threads"
