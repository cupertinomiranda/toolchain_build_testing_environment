#!/bin/bash

if [ -z $1 ]; then
  echo "Provide one of the defconfigs in buildroot_directory:"
  echo "$(cd ${SOURCE_DIR}/buildroot/configs; ls snps_*)"
  exit 0
fi
BUILDROOT_DEFCONFIG=$1

if [ -z "${WORKSPACE_DIR}/buildroot" ]; then
  echo "You should configure setup.sh and exec 'source setup.sh'."
  exit 0
fi

if [ ! -d "$SOURCE_DIR/buildroot" ]; then
  echo "Buildroot is not available in source dir."
  exit 0
fi

BUILD_BUILDROOT_PATH=${BUILD_DIR}/buildroot_${BUILDROOT_DEFCONFIG}

cd ${SOURCE_DIR}/buildroot
make O=${BUILD_BUILDROOT_PATH} ${BUILDROOT_DEFCONFIG}

cd ${BUILD_BUILDROOT_PATH}
make menuconfig

make

cd ${CURRENT_PATH}
