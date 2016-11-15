#! /bin/bash

PARALLEL_MAKE=-j8
TARGET=arc-snps-linux-gnu

cd ${BUILD_DIR}/glibc
rm -rf *
${SOURCE_DIR}/glibc/configure --prefix=/usr --build=x86_64-pc-linux-gnu --host=arc-snps-linux-gnu --target=arc-snps-linux-gnu --with-headers=${INSTALL_DIR}/${TARGET}/usr/include --disable-multilib --disable-threads --disable-werror --enable-obsolete-rpc libc_cv_forced_unwind=yes libc_cv_ssp=no --enable-static-nns --enable-debug
make -j${PARALLEL_MAKE}
make install DESTDIR=${INSTALL_DIR}/${TARGET}/
cd -
