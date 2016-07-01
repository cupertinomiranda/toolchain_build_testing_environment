export CURRENT_PATH=`pwd`
export WORKSPACE_DIR=${CURRENT_PATH}/workspace
export SOURCE_DIR=${CURRENT_PATH}/source
export BUILD_DIR=${WORKSPACE_DIR}/build
export INSTALL_DIR=${CURRENT_PATH}/install

export PATH=${INSTALL_DIR}/bin:${PATH}

export TARGET=arc-default-elf32
export DEFAULT_ARC_VERSION=archs
export ARC_VERSION=arcem


export DEJAGNU=${SOURCE_DIR}/toolchain/site.exp
#export DEJAGNU=/home/cmiranda/toolchain/original_uclibc1/source/toolchain/site.exp
export ARC_MULTILIB_OPTIONS=archs
export ARC_NSIM_OPTS="-p nsim_isa_code_density_option=2"

module add nsim/r527271 
export NSIM_HOME=/home/cmiranda/projects/nsim/r527271/nSIM_64
export PATH=/home/cmiranda/projects/nsim/r527271/nSIM_64/bin:$PATH

export ARC_TEST_ADDR_UCLIBC=192.168.218.2

export JOBS=8
