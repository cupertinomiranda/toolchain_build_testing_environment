#!/bin/bash

if [ -z "${WORKSPACE_DIR}/buildroot" ]; then
  echo "You should configure setup.sh and exec 'source setup.sh'."
  exit 0
fi

if [ ! -d "$SOURCE_DIR/buildroot" ]; then
  echo "Buildroot is not available in source dir."
  exit 0
fi

cd ${SOURCE_DIR}/buildroot
make O=${BUILD_DIR}/buildroot ${BUILDROOT_DEFCONFIG}

cd ${BUILD_DIR}/buildroot
make menuconfig

make

cd ${CURRENT_PATH}
