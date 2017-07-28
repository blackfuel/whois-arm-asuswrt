#!/bin/bash
#############################################################################
# Whois for AsusWRT
#
# This script downloads and compiles all packages needed for adding 
# intelligent whois client capability to Asus ARM routers.
#
# Before running this script, you must first compile your router firmware so
# that it generates the AsusWRT libraries.  Do not "make clean" as this will
# remove the libraries needed by this script.
#############################################################################
PATH_CMD="$(readlink -f $0)"

set -e
set -x

#REBUILD_ALL=1
PACKAGE_ROOT="$HOME/asuswrt-merlin-addon/asuswrt"
SRC="$PACKAGE_ROOT/src"
ASUSWRT_MERLIN="$HOME/asuswrt-merlin"
TOP="$ASUSWRT_MERLIN/release/src/router"
BRCMARM_TOOLCHAIN="$ASUSWRT_MERLIN/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3"
SYSROOT="$BRCMARM_TOOLCHAIN/arm-brcm-linux-uclibcgnueabi/sysroot"
echo $PATH | grep -qF /opt/brcm-arm || export PATH=$PATH:/opt/brcm-arm/bin:/opt/brcm-arm/arm-brcm-linux-uclibcgnueabi/bin:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin
[ ! -d /opt ] && sudo mkdir -p /opt
[ ! -h /opt/brcm ] && sudo ln -sf $HOME/asuswrt-merlin/tools/brcm /opt/brcm
[ ! -h /opt/brcm-arm ] && sudo ln -sf $BRCMARM_TOOLCHAIN /opt/brcm-arm
[ ! -d /projects/hnd/tools/linux ] && sudo mkdir -p /projects/hnd/tools/linux
[ ! -h /projects/hnd/tools/linux/hndtools-arm-linux-2.6.36-uclibc-4.5.3 ] && sudo ln -sf /opt/brcm-arm /projects/hnd/tools/linux/hndtools-arm-linux-2.6.36-uclibc-4.5.3
#MAKE="make -j`nproc`"
MAKE="make -j1"
INSTALL="install"

######### ###################################################################
# WHOIS # ###################################################################
######### ###################################################################

DL="whois_5.2.16.tar.xz"
URL="http://ftp.debian.org/debian/pool/main/w/whois/$DL"
mkdir -p $SRC/whois && cd $SRC/whois
FOLDER="${DL%.tar.xz*}"
FOLDER="${FOLDER/_/-}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xJvf $DL
cd $FOLDER

# utils.h:38:22: fatal error: libintl.h: No such file or directory
PATCH_NAME="${PATH_CMD%/*}/001-disable-nls.patch"
patch --dry-run --silent -p1 -i "$PATCH_NAME" >/dev/null 2>&1 && \
  patch -p1 -i "$PATCH_NAME" || \
  echo "The patch was not applied."

# runtime error: getaddrinfo(whois.arin.net): Bad value for ai_flags
PATCH_NAME="${PATH_CMD%/*}/002-disable-idn.patch"
patch --dry-run --silent -p1 -i "$PATCH_NAME" >/dev/null 2>&1 && \
  patch -p1 -i "$PATCH_NAME" || \
  echo "The patch was not applied."

CC="arm-brcm-linux-uclibcgnueabi-gcc" \
OPTS="-ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$PACKAGE_ROOT/include" \
CFLAGS="$OPTS" CPPFLAGS="$OPTS" \
LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -L$PACKAGE_ROOT/lib" \
LIBS="" \
BASEDIR="$PACKAGE_ROOT" \
$MAKE whois

$INSTALL -d $PACKAGE_ROOT/bin/
$INSTALL -d $PACKAGE_ROOT/share/man/man1/
$INSTALL -d $PACKAGE_ROOT/share/man/man5/
$INSTALL -m 0755 whois $PACKAGE_ROOT/bin/
$INSTALL -m 0644 whois.1 $PACKAGE_ROOT/share/man/man1/
$INSTALL -m 0644 whois.conf.5 $PACKAGE_ROOT/share/man/man5/

touch __package_installed
fi

