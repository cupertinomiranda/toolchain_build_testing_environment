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
cp -aHf ${SOURCE_DIR}/verification-scripts ${WORKSPACE_DIR}/verification-scripts
ln -sf ${SOURCE_DIR}/binutils ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/gdb ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/gcc ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/newlib ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/uClibc ${WORKSPACE_DIR}/.
ln -sf ${SOURCE_DIR}/linux ${WORKSPACE_DIR}/.

cd ${WORKSPACE_DIR}/toolchain
mkdir -p ${BUILD_DIR}

TARGET_CFLAGS="-O2 -g"
if [ "${ARC_VERSION}" = "700" ]; then
  TARGET_CFLAGS="${TARGET_CFLAGS} -mcpu=arc700"
fi
if [ "${ARC_VERSION}" = "hs" ]; then
  TARGET_CFLAGS="${TARGET_CFLAGS} -mcpu=archs"
fi

OPTIONS="--no-multilib"
if [ "${ELF_TOOLCHAIN}" = "y" ]; then
  OPTIONS="${OPTIONS} --elf32"
else
  OPTIONS="${OPTIONS} --no-elf32"
fi
if [ "${UCLIBC_TOOLCHAIN}" = "y" ]; then
  OPTIONS="${OPTIONS} --uclibc"
else
  OPTIONS="${OPTIONS} --no-uclibc"
fi

DEFAULT_ARC_VERSION=arc${ARC_VERSION}

./build-all.sh --rel-rpaths --config-extra --with-python=no \
	       --no-auto-pull --no-auto-checkout --no-native-gdb --no-optsize-newlib \
	       --no-optsize-libstdc++ --no-external-download --jobs ${JOBS} --load 8 \
	       ${OPTIONS} --cpu ${DEFAULT_ARC_VERSION}  \
	       --build-dir ${BUILD_DIR} \
	       --target-cflags "${TARGET_CFLAGS}" --release-name 'tino build' \
	       --install-dir ${INSTALL_DIR} \
	       --no-pdf

cd ${CURRENT_PATH}
