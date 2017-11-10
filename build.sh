#!/bin/bash

set -e

sudo yum -y update
sudo yum -y groupinstall "Development Tools"

##################################
# Dependecy tree
#
# poppler
# ├── CMake
# │   ├── cURL
# │   └── libarchive
# ├── Fontconfig
# │   └── FreeType
# │       └── libpng
# ├── Cairo
# │   ├── libpng
# │   └── Pixman
# ├── libjpeg-turbo
# │   └── NASM
# ├── libpng
# ├── NSS
# │   └── NSPR
# └── OpenJPEG
#     └── CMake
##################################

# Install libarchive
wget http://www.libarchive.org/downloads/libarchive-3.3.2.tar.gz
tar xf libarchive-3.3.2.tar.gz
cd libarchive-3.3.2
./configure --prefix=/usr --disable-static && make
sudo make install
cd ..
rm -rf libarchive-3.3.2.tar.gz libarchive-3.3.2
sudo ldconfig

# Install CMake
sudo yum install -y zlib-devel libcurl-devel expat-devel
wget https://cmake.org/files/v3.9/cmake-3.9.4.tar.gz
tar xf cmake-3.9.4.tar.gz
cd cmake-3.9.4
sed -i '/CMAKE_USE_LIBUV 1/s/1/0/' CMakeLists.txt     &&
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&

./bootstrap --prefix=/usr        \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.9.4 &&
make
sudo make install
cd ..
rm -rf cmake-3.9.4.tar.gz cmake-3.9.4
sudo ldconfig

# Install libpng
wget https://downloads.sourceforge.net/libpng/libpng-1.6.32.tar.xz
wget https://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.32-apng.patch.gz
tar xf libpng-1.6.32.tar.xz
cd libpng-1.6.32
gzip -cd ../libpng-1.6.32-apng.patch.gz | patch -p1
./configure --prefix=/usr --disable-static &&
make
sudo make install
cd ..
rm -rf libpng-1.6.32.tar.xz libpng-1.6.32-apng.patch.gz libpng-1.6.32 
sudo ldconfig

# Install FreeType2
wget https://downloads.sourceforge.net/freetype/freetype-2.8.1.tar.bz2
tar jxf freetype-2.8.1.tar.bz2
cd freetype-2.8.1
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&
sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&
./configure --prefix=/usr --disable-static &&
make
sudo make install
cd ..
rm -rf freetype-2.8.1.tar.bz2 freetype-2.8.1
sudo ldconfig

# Install Fontconfig
sudo yum install -y gperf
sudo ldconfig
wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.6.tar.bz2
tar jxf fontconfig-2.12.6.tar.bz2
cd fontconfig-2.12.6
rm -f src/fcobjshash.h
FREETYPE_CFLAGS='-I/usr/include/freetype2'             \
FREETYPE_LIBS='-L/usr/lib -lfreetype'                  \
./configure --prefix=/usr                              \
            --sysconfdir=/etc                          \
            --localstatedir=/var                       \
            --disable-docs                             \
            --docdir=/usr/share/doc/fontconfig-2.12.6 &&
make
sudo make install
cd ..
rm -rf fontconfig-2.12.6.tar.bz2 fontconfig-2.12.6
sudo ldconfig

# Install Pixman
wget https://www.cairographics.org/releases/pixman-0.34.0.tar.gz
tar xf pixman-0.34.0.tar.gz
cd pixman-0.34.0
./configure --prefix=/usr --disable-static &&
make
sudo make install
cd ..
rm -rf pixman-0.34.0.tar.gz pixman-0.34.0
sudo ldconfig

# Install Cairo
wget https://www.cairographics.org/releases/cairo-1.14.10.tar.xz
tar xf cairo-1.14.10.tar.xz
cd cairo-1.14.10
PKG_CONFIG_PATH="/usr/lib/pkgconfig/:$PKG_CONFIG_PATH" \
./configure --prefix=/usr                              \
            --disable-static                           \
            --enable-tee                              &&
make
sudo make install
cd ..
rm -rf cairo-1.14.10.tar.xz cairo-1.14.10
sudo ldconfig

# Install NASM
wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.xz
tar xf nasm-2.13.01.tar.xz
cd nasm-2.13.01
./configure --prefix=/usr &&
make
sudo make install
cd ..
rm -rf nasm-2.13.01.tar.xz nasm-2.13.01
sudo ldconfig

# Install libjpeg-turbo
wget https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.5.2.tar.gz
tar xf libjpeg-turbo-1.5.2.tar.gz
cd libjpeg-turbo-1.5.2
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-jpeg8            \
            --disable-static        \
            --docdir=/usr/share/doc/libjpeg-turbo-1.5.2 &&
make
sudo make install
cd ..
rm -rf libjpeg-turbo-1.5.2.tar.gz libjpeg-turbo-1.5.2
sudo ldconfig

# Install NSPR
wget https://archive.mozilla.org/pub/nspr/releases/v4.17/src/nspr-4.17.tar.gz
tar xf nspr-4.17.tar.gz
pushd .
cd nspr-4.17
cd nspr                                                     &&
sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
sed -i 's#$(LIBRARY) ##'            config/rules.mk         &&

./configure --prefix=/usr \
            --with-mozilla \
            --with-pthreads \
            $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
make
sudo make install
popd
rm -rf nspr-4.17.tar.gz nspr-4.17
sudo ldconfig

# Install NSS
wget https://archive.mozilla.org/pub/security/nss/releases/NSS_3_33_RTM/src/nss-3.33.tar.gz
wget http://www.linuxfromscratch.org/patches/blfs/svn/nss-3.33-standalone-1.patch
tar xf nss-3.33.tar.gz
pushd .
cd nss-3.33
patch -Np1 -i ../nss-3.33-standalone-1.patch &&
cd nss &&
make -j1 BUILD_OPT=1                  \
  NSPR_INCLUDE_DIR=/usr/include/nspr  \
  USE_SYSTEM_ZLIB=1                   \
  ZLIB_LIBS=-lz                       \
  NSS_ENABLE_WERROR=0                 \
  $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
  $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1)
cd ../dist                                                          &&

install -v -m755 Linux*/lib/*.so              /usr/lib              &&
install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib              &&

install -v -m755 -d                           /usr/include/nss      &&
cp -v -RL {public,private}/nss/*              /usr/include/nss      &&
chmod -v 644                                  /usr/include/nss/*    &&

install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin &&

install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib/pkgconfig
popd
rm -rf nss-3.33.tar.gz nss-3.33 nss-3.33-standalone-1.patch
sudo ldconfig

# Install OpenJPEG
wget https://github.com/uclouvain/openjpeg/archive/v2.3.0/openjpeg-2.3.0.tar.gz
tar xf openjpeg-2.3.0.tar.gz
cd openjpeg-2.3.0
mkdir -v build &&
cd       build &&

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. &&
make
sudo make install
cd ../..
rm -rf openjpeg-2.3.0.tar.gz openjpeg-2.3.0
sudo ldconfig

# Install poppler
wget https://poppler.freedesktop.org/poppler-0.60.1.tar.xz
tar xf poppler-0.60.1.tar.xz
cd poppler-0.60.1
mkdir build                         &&
cd    build                         &&

PKG_CONFIG_PATH="/usr/lib/pkgconfig/:$PKG_CONFIG_PATH" \
cmake  -DCMAKE_BUILD_TYPE=Release                      \
       -DCMAKE_INSTALL_PREFIX=""                       \
       -DPOPPLER_DATADIR=/var/task/share/poppler       \
       -DTESTDATADIR=$PWD/testfiles                    \
       -DENABLE_XPDF_HEADERS=ON                        \
       ..                                             &&
make
sudo make install DESTDIR="$HOME/poppler"
cd ../..

# Install poppler-data
wget https://poppler.freedesktop.org/poppler-data-0.4.8.tar.gz
tar xf poppler-data-0.4.8.tar.gz
cd poppler-data-0.4.8
sudo make prefix=/ install DESTDIR="$HOME/poppler"
cd ..
rm -rf poppler-data-0.4.8.tar.gz poppler-data-0.4.8

# Prepare package
cd "$HOME"
sudo rm -rf "$HOME/poppler/lib/pkgconfig"
sudo rm -rf "$HOME/poppler/include"
sudo rm -rf "$HOME/poppler/share/man"
sudo rm -rf "$HOME/poppler/share/pkgconfig"
sudo cp -P /usr/lib/libjpeg.* "$HOME/poppler/lib"
sudo cp -P /usr/lib/libopenjp2.* "$HOME/poppler/lib"
sudo cp -P /usr/lib/libpng* "$HOME/poppler/lib"
sudo cp -P /usr/lib/libcairo* "$HOME/poppler/lib"
sudo cp -P /usr/lib/libpixman* "$HOME/poppler/lib"
tar zcvf poppler.tgz poppler/
