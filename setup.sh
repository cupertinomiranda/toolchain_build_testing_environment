export CURRENT_PATH=`pwd`
export WORKSPACE_DIR=${CURRENT_PATH}/workspace
export SOURCE_DIR=${CURRENT_PATH}/source
export BUILD_DIR=${WORKSPACE_DIR}/build
export INSTALL_DIR=${CURRENT_PATH}/install

export PATH=${INSTALL_DIR}/bin:${PATH}

export TARGET=arc-default-elf32
export ARC_VERSION=hs #700

export DEJAGNU=${SOURCE_DIR}/toolchain/site.exp
#export DEJAGNU=/home/cmiranda/toolchain/original_uclibc1/source/toolchain/site.exp
export ARC_MULTILIB_OPTIONS=archs
export ARC_NSIM_OPTS="-p nsim_isa_code_density_option=2"

export NSIM_HOME=/home/cmiranda/projects/nsim/r527271/nSIM_64
export PATH=/home/cmiranda/projects/nsim/r527271/nSIM_64/bin:$PATH

export ARC_TEST_ADDR_UCLIBC=192.168.218.2

export JOBS=8

export ELF_TOOLCHAIN=n
export UCLIBC_TOOLCHAIN=y

#export BUILDROOT_DEFCONFIG=snps_axs10x_defconfig
export BUILDROOT_DEFCONFIG=snps_nsimosci_${ARC_VERSION}_defconfig

