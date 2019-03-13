
#Set desired versions of seafile components
LIBSEARPC_VERSION=3.1.0
SEAFILE_VERSION=6.2.11
SEAFILE_CLIENT_VERSION=6.2.11

#Full path to Qt5 installation
QT5_ROOT=/c/Qt/Qt5.5.1/5.5/mingw492_32

#Full path to WinSparkle installation
EXTRA_LIBS_DIR=/c/WinSparkle-0.6.0/Release

#Base URL of Git repository. Put your own repo URL 
#here if you want to customize components
GIT_REPO_BASE=https://github.com/haiwen/

TARBALLS_DIR=$(readlink --canonicalize ~/seafile/tarballs)
BUILD_DIR=$(readlink --canonicalize ~/seafile/build)
OUTPUT_DIR=$(readlink --canonicalize ~/seafile/output)
EXTRA_TOOLS_DIR=$(readlink --canonicalize ~/seafile/bintools)

mkdir -p {${TARBALLS_DIR},${BUILD_DIR},${OUTPUT_DIR}}

#Do a housekeeping before build
rm -rf ${BUILD_DIR}/*
rm -rf ${OUTPUT_DIR}/*

#Add extra tools(Wix and paraffin) to our PATH so build script can pick up them
#Also add mingw64 tools to PATH as we need them for explorer extensions
#Qt binaries should also be in path for msi build scripts
export PATH=$PATH:/mingw64/bin:${QT5_ROOT}:${EXTRA_TOOLS_DIR}

ln -s /mingw64/bin/windres.exe /mingw64/bin/x86_64-w64-mingw32-windres.exe

#Replace the aclocal environment variable to set 
#right paths that recognizable by autogen.sh
export ACLOCAL_PATH="/c/msys64/mingw32/share/aclocal;/c/msys64/usr/share/aclocal"      

alias wget="wget --content-disposition -nc -P ${TARBALLS_DIR}"

if [ "$1" != "-skip-download" ]
then
    echo "Downloading seafile components"
    wget ${GIT_REPO_BASE}libsearpc/archive/v${LIBSEARPC_VERSION}.tar.gz
    wget ${GIT_REPO_BASE}seafile/archive/v${SEAFILE_VERSION}.tar.gz
    wget ${GIT_REPO_BASE}seafile-client/archive/v${SEAFILE_CLIENT_VERSION}.tar.gz
    wget ${GIT_REPO_BASE}seafile-shell-ext/archive/seafile-${SEAFILE_CLIENT_VERSION}.tar.gz
fi

#Patch msi build scripts for MSYS2
cd ${TARBALLS_DIR}
tar -xzvf seafile-${SEAFILE_VERSION}.tar.gz
cd seafile-${SEAFILE_VERSION}
cp -v ../../patch/tools.patch .

patch -p1 -N --dry-run --silent < tools.patch 2>/dev/null
#If the patch has not been applied then the $? which is the exit status 
#for last command would have a success status code = 0
if [ $? -eq 0 ];
then
    #apply the patch
    patch -p1 -N < tools.patch
fi

cd ../
tar -czvf seafile-${SEAFILE_VERSION}.tar.gz seafile-${SEAFILE_VERSION}
rm -rf seafile-${SEAFILE_VERSION}
cd ../

#Run main build script
python scripts/build/build-msi.py \
    --version=${SEAFILE_VERSION} \
    --libsearpc_version=${LIBSEARPC_VERSION} \
    --seafile_version=${SEAFILE_VERSION} \
    --seafile_client_version=${SEAFILE_CLIENT_VERSION} \
    --builddir=${BUILD_DIR} \
    --outputdir=${OUTPUT_DIR} \
    --srcdir=${TARBALLS_DIR} \
    --keep --qt5 --qt_root=${QT5_ROOT} \
    --extra_libs_dir=${EXTRA_LIBS_DIR}
