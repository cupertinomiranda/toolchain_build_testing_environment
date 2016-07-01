#!/bin/bash

if [ -z "${WORKSPACE_DIR}" ]; then
  echo "You should configure setup.sh and exec 'source setup.sh'."
  exit 0
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory was not created at $(SOURCE_DIR)."
  exit 0
fi

mkdir -p ${WORKSPACE_DIR}
cd ${WORKSPACE_DIR}

cp -aHf ${SOURCE_DIR}/toolchain ${WORKSPACE_DIR}/toolchain
ln -sf ${SOURCE_DIR}/binutils ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/gdb ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/gcc ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/newlib ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/uClibc ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/linux ${WORKSPACE_DIR}/.

cd ${WORKSPACE_DIR}/toolchain
mkdir -p ${BUILD_DIR}

./build-all.sh --strip --rel-rpaths --config-extra --with-python=no \
	       --no-auto-pull --no-auto-checkout --no-native-gdb --no-optsize-newlib \
	       --no-optsize-libstdc++ --no-external-download --jobs ${JOBS} --load 8 --no-elf32 \
	       --uclibc --no-multilib --cpu ${DEFAULT_ARC_VERSION}  \
	       --build-dir ${BUILD_DIR} \
	       --target-cflags '-O2 -g -mcpu=archs' --release-name 'tino build' \
	       --install-dir ${INSTALL_DIR} \
	       --no-pdf

cd ${CURRENT_PATH}
