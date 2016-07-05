#!/bin/bash -eu
# Copyright (C) 2015 Synopsys, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Current directory must be a directory for temp files and logs.
# Environment
# TA_TARGET_CONFIG
#   Tool chain to test, including multilib flags
# TA_BOARD
#   Board to test on.
# TA_DEJAGNU_TOOL
# TA_RESULTS_DIR
#   Custom results dir.


# Source dir is different for dejagnu, since we expect that test target config
# might be different from those built.
src_dir=${SOURCE_DIR}
install_dir=${INSTALL_DIR}
prefix=${TOOLCHAIN_PREFIX}
toolchain_dir=${INSTALL_DIR}

target_toolchain=${TARGET_TOOLCHAIN}
target_toolchain=arc-snps-linux-uclibc

target_cflags=""


export TA_DEJAGNU_TOOL=gcc

results_dir=`pwd`/${target_toolchain}/${TA_DEJAGNU_TOOL}/

export TA_BOARD=axs103

get_sdp_ip_address() {
    local ip=$(curl http://${TC_BOARD_SERVER_IP}/get_ip_address)

    if [ -z "$ip" ]; then
        echo ""
    else
        echo "$ip"
    fi
}

platform_init() {
    IMAGE_LOCATION=${BUILD_DIR}/buildroot_snps_axs103_defconfig/images/uImage
    curl -F file=@${IMAGE_LOCATION} http://${TC_BOARD_SERVER_IP}/upload_linux_image

    curl http://${TC_BOARD_SERVER_IP}/reset_board

    sleep 20;

    TA_SDP_IP_ADDRESS=$(get_sdp_ip_address)

    TA_SDP_IP_ADDRESS=$(get_sdp_ip_address)
    ARC_TEST_ADDR_UCLIBC=${TA_SDP_IP_ADDRESS}
    echo "IP_ADDRESS = ${TA_SDP_IP_ADDRESS}"u
}

# Unfortunately toolchain name is not same as name of binaries.
case $target_toolchain in
    arc-*-elf32)
	prefix=arc-elf32
	alias=arc-elf32
	;;
    arceb-*-elf32)
	prefix=arceb-elf32
	alias=arceb-elf32
	;;
    arc-*-linux-*)
	prefix=arc-linux
	alias=arc-linux-uclibc
	;;
    arceb-*-linux-*)
	prefix=arceb-linux
	alias=arceb-linux-uclibc
	;;
    *) error "Unknown toolchain '$target_toolchain'" ;;
esac
exec_dir=$install_dir/bin
exec_prefix=$exec_dir/$prefix

#
# Environemnt variables
#

# We have to add toolchain to PATH to enable testglue - test for testglue
# compilation is done before site.exp will be read, as a results GCC_UNDET_TEST
# will not be used.
export PATH=$exec_dir:$PATH

# Set multilib options for ARC baseboards
# We should skip first -m because it will be auto appended by DejaGNU.
# In other words we should pass 'norm -mmul' to get '-mnorm -mmul'.
# TODO
#export ARC_MULTILIB_OPTIONS="${target_cflags:2}"

# ARC site.exp
export DEJAGNU=$src_dir/toolchain/site.exp

# Enable nSIM JIT
export ARC_NSIM_OPTS="-on nsim_fast"

# Passing --xml to runtest we cause it to generate ${tool}.xml file. However in
# case of GDB we already have gdb.xml directory from the testsuite, hence
# cannot create such file. In theory we can pass --xml=$fname to override file
# name, however for some reasons DejaGNU would still remove file ${tool}.xml
# even if it will write to file with different name. Therefore XML output is
# disabled for GDB, until it will be actually needed for it. Possible
# workaround would be to employ --outdir option of DejaGNU, because file is
# ${outdir}/${tool}.xml, so having $PWD != $outdir might resolve the trouble.

case $TA_DEJAGNU_TOOL in
    gdb) xml_opt= ;;
    # In theory `--xml` is same as `--xml=${tool}.xml`, but in practice at some
    # point DejaGNU started to create files named `${triplet}-${tool}` instead.
    # I'm not sure when and why this strted. Therefore it is better to
    # explicitly set filename.
    *) xml_opt="--xml=${TA_DEJAGNU_TOOL}.xml" ;;
esac

# Compress big XML files
case $TA_DEJAGNU_TOOL in
    gcc|g++|libstdc++|gdb) compress_xml=y ;;
    *) compress_xml=n ;;
esac

# Board
case $TA_BOARD in
    cgen) dejagnu_board=arc-sim ;;
    nsim) dejagnu_board=arc-sim-nsimdrv ;;
    nsim-gdb)
	dejagnu_board=arc-nsim
	fname=$target_cpu_family
	if [ $target_endian = eb ]; then
	    fname=$fname-eb
	fi
	export ARC_NSIM_PROPS="${my_root}/tools/cpu/${fname}.props"
	# /usr/sbin mihgt not be in the PATH, but we need `lsof` from it.
	export PATH=/usr/sbin:$PATH
	;;
    lvp)
	dejagnu_board=arc-linux-aa4
	export ARC_TEST_ADDR_UCLIBC=192.168.218.2
	;;
    axs*)
	dejagnu_board=arc-linux-aa4
	# ARC_TEST_ADDR_UCLIBC can be set only after platform init.
	;;
    tino)
	dejagnu_board=arc-linux-aa4
	#dejagnu_board=arc-sim-nsimdrv ;;
	# ARC_TEST_ADDR_UCLIBC can be set only after platform init.
	;;
    *) error "Unsupported board '$TA_BOARD'." ;;
esac

#
# Generate site.exp
#

# Check tool
case "${TA_DEJAGNU_TOOL:=}" in
    gcc|g++)
	echo "set srcdir \"$src_dir/gcc/gcc/testsuite\"" > site.exp
	# Some GCC tests depend on timestamps: see GCC pr/28123
	pushd "$src_dir/gcc"
	./contrib/gcc_update --touch
	popd
	;;
    binutils|ld|gas)
	echo "set srcdir \"$src_dir/binutils/$TA_DEJAGNU_TOOL/testsuite\"" > site.exp
	;;
    newlib)
	echo "set srcdir \"$src_dir/newlib/$TA_DEJAGNU_TOOL/testsuite\"" > site.exp
	mkdir -p targ-include
	cp $toolchain_dir/$prefix/include/newlib.h targ-include
	;;
    libstdc++)
	echo "set srcdir \"$src_dir/gcc/libstdc++-v3/testsuite\"" > site.exp
	export CXXFLAGS="-O2 -g"
	;;
    gdb)
	testsuite=$src_dir/gdb/gdb/testsuite
	mkdir $(ls -1d $testsuite/gdb.* | grep -Po '(?<=\/)[^\/]+$')
	echo "set srcdir \"$testsuite\"" > site.exp
	;;
    *) error "Unsupported tool \`$TA_DEJAGNU_TOOL'." ;;
esac

cat >> site.exp <<EOF
set arc_exec_prefix "${exec_prefix}"

set target_alias    "$alias"
set target_triplet  "$target_toolchain"
set rootme	    "."
set tmpdir	    "$(pwd)"
set CFLAGS	    ""
set CXXFLAGS	    ""
set SIM		    "\${arc_exec_prefix}-run"
set GDB		    "\${arc_exec_prefix}-gdb"
# Binutils
set NM		    "\${arc_exec_prefix}-nm"
set SIZE	    "\${arc_exec_prefix}-size"
set OBJDUMP	    "\${arc_exec_prefix}-objdump"
set OBJCOPY	    "\${arc_exec_prefix}-objcopy"
set AR		    "\${arc_exec_prefix}-ar"
set STRIP	    "\${arc_exec_prefix}-strip"
set READELF	    "\${arc_exec_prefix}-readelf"
set ELFEDIT	    "\${arc_exec_prefix}-elfedit"
# ld
set LD		    "\${arc_exec_prefix}-ld"

if { \$tool == "gcc" || \$tool == "g++" } {
    set GCC_UNDER_TEST  "\${arc_exec_prefix}-gcc"
    set GXX_UNDER_TEST  "\${arc_exec_prefix}-g++"
} else {
    set CC_FOR_TARGET   "\${arc_exec_prefix}-gcc"
    set CC		"\${arc_exec_prefix}-gcc"
    set CXX_FOR_TARGET  "\${arc_exec_prefix}-g++"
    set CXX		"\${arc_exec_prefix}-g++"
}

switch \$tool {
    libstdc++ {
	set baseline_subdir_switch "--print-multi-directory"
    }
    gdb {
	# By default GDB is called with -data-directory option. This wreaks
	# havoc when using an installed GDB, because passed -data-directory
	# value is invalid. To fix the problem it is needed to override
	# INTERNAL_GDBFLAGS variable.
	set ::INTERNAL_GDBFLAGS "-nw -nx"
	source \$srcdir/lib/append_gdb_boards_dir.exp
	if {[string match arc*-linux-uclibc \$target_triplet]} {
	    set gdb_server_prog "/usr/bin/gdbserver"
	    set toolchain_sysroot_dir "$sysroot_dir"
	}
    }
}
EOF

# Start Linux
if declare -f -F platform_init ; then
    echo "TODO: Initiate platform"
    platform_init
fi

if [[ "${TA_LINUX_PLATFORM:-}" == axs* ]]; then
    export ARC_TEST_ADDR_UCLIBC=$TA_SDP_IP_ADDRESS
fi

#
# Run
#
# runtest returns non-zero status if there are failed tests. We ignore exit
# value so that Jenkins build will not be marked as failure due to this reason.
runtest $xml_opt --tool $TA_DEJAGNU_TOOL --target_board $dejagnu_board \
    --target=$target_toolchain $* || true

# Halt Linux
if declare -f -F platform_close ; then
    echo "TODO: Close platform"
    #platform_close
fi

#
# Copy results
#
mkdir -p $results_dir
cp -afv $TA_DEJAGNU_TOOL.{log,sum} $results_dir
if [ -f ${TA_DEJAGNU_TOOL}.xml ]; then
    cp -afv ${TA_DEJAGNU_TOOL}.xml $results_dir
fi
# If test has been aborted due to timeout (can happen on Linux) then we don't
# want want numbers from .sum file to make into report, because numbers are not
# representative. However they shouldn't be removed as well, so I just rename
# .sum file, so report script will not find it.
if [ ${TA_ABORTED:-0} == 1 ]; then
    mv $results_dir/$TA_DEJAGNU_TOOL.sum{,-aborted}
fi

# Compress log file
if [ -f $results_dir/$TA_DEJAGNU_TOOL.log ]; then
    xz -f $results_dir/$TA_DEJAGNU_TOOL.log
fi

# Compress XML file
if [ $compress_xml = y -a -f $results_dir/${TA_DEJAGNU_TOOL}.xml ]; then
    xz -f $results_dir/${TA_DEJAGNU_TOOL}.xml
fi

