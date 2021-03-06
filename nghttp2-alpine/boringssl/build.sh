#!/bin/sh

# BoringSSL
cd /build
git clone --depth 1 --single-branch https://boringssl.googlesource.com/boringssl
cd boringssl
git log --format="%H" -n 1 > /boringssl-commit-id.txt

mkdir build
cd build
export LIBEVENT_OPENSSL_LIBS="-I/build/boringssl/include"
export OPENSSL_CFLAGS="-I/build/boringssl/include"
export OPENSSL_LIBS="-lcrypto -lssl"  
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=1 .. 
make -j $(getconf _NPROCESSORS_ONLN)
cp /build/boringssl/build/ssl/libssl* /usr/lib
cp /build/boringssl/build/crypto/libcrypto* /usr/lib

# spdylay
if test "$SPDYLAY_VERSION" != "DISABLED"; then

  cd /build
  
  if test -n "$SPDYLAY_VERSION"; then
    curl -fSL https://github.com/tatsuhiro-t/spdylay/releases/download/v${SPDYLAY_VERSION}/spdylay-${SPDYLAY_VERSION}.tar.xz -o spdylay.tar.xz
    if [ 0 -ne $? ]; then
	exit 1
    fi
    ls -l spdylay.tar.xz
    tar xJf spdylay.tar.xz
    if [ 0 -ne $? ]; then
	exit 1
    fi
    mv spdylay-${SPDYLAY_VERSION} spdylay
  else
    git clone https://github.com/tatsuhiro-t/spdylay.git
  fi

  cd /build/spdylay

  autoreconf -i
  automake
  autoconf
  ./configure --disable-dependency-tracking\
              --disable-examples --disable-src --disable-static\
              --prefix=/usr

  make -j $(getconf _NPROCESSORS_ONLN)
  make install
fi

# Download nghttp2
cd /build
if test -n "$NGHTTP2_VERSION"; then
  curl -fSL https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.xz -o nghttp2.tar.xz
  if [ 0 -ne $? ]; then
      exit 1
  fi
  ls -l nghttp2.tar.xz
  tar xJf nghttp2.tar.xz
  if [ 0 -ne $? ]; then
      exit 1
  fi
  mv nghttp2-${NGHTTP2_VERSION} nghttp2
else
  git clone https://github.com/nghttp2/nghttp2
fi

# Compile / Install nghttp2
cd /build/nghttp2

autoreconf -i
automake
autoconf

./configure --enable-app --with-spdylay\
            --disable-dependency-tracking\
            --disable-examples --disable-static\
	    --prefix=/usr

make -j $(getconf _NPROCESSORS_ONLN)
make install-strip

# Remove /build
rm -rf /build
