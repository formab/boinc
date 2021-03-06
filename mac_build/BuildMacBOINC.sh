#!/bin/sh

# This file is part of BOINC.
# http://boinc.berkeley.edu
# Copyright (C) 2015 University of California
#
# BOINC is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# BOINC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with BOINC.  If not, see <http://www.gnu.org/licenses/>.
#
#
##
# Script for building Macintosh BOINC Manager, Core Client and libraries
# by Charlie Fenton 3/27/08
# with thanks to Reinhard Prix for his assistance
#
# Updated for OS 10.7 Lion and XCode 4.2 on 10/19/11
# Updated 7/9/12 for Xcode 4.3 and later which are not at a fixed address
# Updated 2/7/14 to also build libboinc_zip.a
# Updated 11/28/15 to build ScreenSaver with ARC under Xcode 6 or later
# Updated 2/3/16 to allow optional use of libc++ and C++11 dialect
#
## This script requires OS 10.8 or later
#
## If you drag-install Xcode 4.3 or later, you must have opened Xcode 
## and clicked the Install button on the dialog which appears to 
## complete the Xcode installation before running this script.
##

## Usage:
## cd to the mac_build directory of the boinc tree, for example:
##     cd [path]/boinc/mac_build
##
## then invoke this script as follows:
##      source BuildMacBOINC.sh [-dev] [-noclean] [-all] [-lib] [-client] [-help]
## or
##      chmod +x BuildMacBOINC.sh
##      ./BuildMacBOINC.sh [-dev] [-noclean] [-all] [-lib] [-client] [-help]
##
## optional arguments
## -dev         build the development (debug) version. 
##              default is deployment (release) version.
##
## -noclean     don't do a "clean" of each target before building.
##              default is to clean all first.
##
## -libc++      build using libc++ instead of libstdc++ (requires OS 10.7)
##
## -c++11       build using c++11 language dialect instead of default (requires libc++)
##
##  The following arguments determine which targets to build
##
## -all         build all targets (i.e. target "Build_All" -- this is the default)
##
## -lib         build the six libraries: libboinc_api.a, libboinc_graphics2.a,
##              libboinc.a, libboinc_opencl.a, libboinc_zip.a, jpeglib.a and the
##              utility application MakeAppIcon_h.
##
## -client      build two targets: boinc client and command-line utility boinc_cmd
##              (also builds libboinc.a if needed, since boinc_cmd requires it.)
##
## Both -lib and -client may be specified to build seven targets (no BOINC Manager)
##

targets=""
doclean="clean"
cplusplus11dialect=""
uselibcplusplus=""
buildall=0
buildlibs=0
buildclient=0
style="Deployment"
isXcode6orLater=0

xcodeversion=`xcodebuild -version`
xcodeMajorVersion=`echo $xcodeversion | cut -d ' ' -f 2 | cut -d '.' -f 1`

if [ "$xcodeMajorVersion" -gt "5" ]; then
isXcode6orLater=1
fi

while [ $# -gt 0 ]; do
  case "$1" in 
    -noclean ) doclean="" ; shift 1 ;;
    -dev ) style="Development" ; shift 1 ;;
    -libc++ ) uselibcplusplus="CLANG_CXX_LIBRARY=libc++ MACOSX_DEPLOYMENT_TARGET=10.7" ; shift 1 ;;
    -c++11 ) cplusplus11dialect="CLANG_CXX_LANGUAGE_STANDARD=c++11" ; shift 1 ;;
    -all ) buildall=1 ; shift 1 ;;
    -lib ) buildlibs=1 ; shift 1 ;;
    -client ) buildclient=1 ; shift 1 ;;
    * ) echo "usage:" ; echo "cd {path}/mac_build/" ; echo "source BuildMacBOINC.sh [-dev] [-noclean] [-all] [-lib] [-client] [-help]" ; return 1 ;;
  esac
done

if [ "${doclean}" = "clean" ]; then
    echo "Clean each target before building"
fi

if [ "${buildlibs}" = "1" ]; then
    targets="$targets -target libboinc -target gfx2libboinc -target api_libboinc -target boinc_opencl -target jpeg -target MakeAppIcon_h"
fi

if [ "${buildclient}" = "1" ]; then
    targets="$targets -target BOINC_Client -target cmd_boinc"
fi

## "-all" overrides "-lib" and "-client" since it includes those targets
if [ "${buildall}" = "1" ] || [ "${targets}" = "" ]; then
    if [ $isXcode6orLater = 0 ]; then
        ## We can build the screensaver using our standard settings (with Garbage Collection)
        targets="-target Build_All"
    else
        ## We must modify the build settings for the screensaver only, to build it with ARC
        targets="-target SetVersion -target libboinc -target gfx2libboinc -target api_libboinc -target boinc_opencl -target jpeg -target MakeAppIcon_h -target BOINC_Client -target switcher -target setprojectgrp -target cmd_boinc -target mgr_boinc -target Install_BOINC -target PostInstall -target Uninstaller -target SetUpSecurity -target AddRemoveUser -target WaitPermissions -target ss_app -target gfx_switcher"
    fi
fi

version=`uname -r`;

major=`echo $version | sed 's/\([0-9]*\)[.].*/\1/' `;
# minor=`echo $version | sed 's/[0-9]*[.]\([0-9]*\).*/\1/' `;

# echo "major = $major"
# echo "minor = $minor"
#
# Darwin version 12.x.y corresponds to OS 10.8.x
# Darwin version 11.x.y corresponds to OS 10.7.x
# Darwin version 10.x.y corresponds to OS 10.6.x
# Darwin version 9.x.y corresponds to OS 10.5.x
# Darwin version 8.x.y corresponds to OS 10.4.x
# Darwin version 7.x.y corresponds to OS 10.3.x
# Darwin version 6.x corresponds to OS 10.2.x

if [ "$major" -lt "10" ]; then
    echo "ERROR: Building BOINC requires System 10.6 or later.  For details, see build instructions at"
    echo "boinc/mac_build/HowToBuildBOINC_XCode.rtf or http://boinc.berkeley.edu/trac/wiki/MacBuild"
    return 1
fi

if [ "${style}" = "Development" ]; then
    echo "Development (debug) build"
else
    style="Deployment"
    echo "Deployment (release) build for architectures: i386, x86_64"
fi

echo ""

SDKPATH=`xcodebuild -version -sdk macosx Path`

if [ $isXcode6orLater = 0 ]; then
    ## echo "Xcode version < 6"
    ## Build the screensaver using our standard settings (with Garbage Collection)
    xcodebuild -project boinc.xcodeproj ${targets} -configuration ${style} -sdk "${SDKPATH}" ${doclean} build ${uselibcplusplus} ${cplusplus11dialect}
else
    ## echo "Xcode version > 5"
    ## We must modify the build settings for the screensaver only, to build it with ARC
    xcodebuild -project boinc.xcodeproj ${targets} -configuration ${style} -sdk "${SDKPATH}" ${doclean}  build ${uselibcplusplus} ${cplusplus11dialect}

    result=$?

    if [ "${buildall}" = "1" ] || [ "${targets}" = "" ]; then
        if [ $result -eq 0 ]; then
            xcodebuild -project boinc.xcodeproj -target ScreenSaver -configuration ${style} -sdk "${SDKPATH}" ${doclean} build ARCHS=x86_64 GCC_ENABLE_OBJC_GC=unsupported ${uselibcplusplus} ${cplusplus11dialect}
        fi
    fi
fi

result=$?

if [ $result -eq 0 ]; then
    # build ibboinc_zip.a for -all or -lib or default, where
    # default is none of { -all, -lib, -client }
    if [ "${buildall}" = "1" ] || [ "${buildlibs}" = "1" ] || [ "${buildclient}" = "0" ]; then
        xcodebuild -project ../zip/boinc_zip.xcodeproj -target boinc_zip -configuration ${style} -sdk "${SDKPATH}" ${doclean} build  ${uselibcplusplus} ${cplusplus11dialect}

        result=$?
    fi
fi

return $result
