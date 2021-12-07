#
# Configures a Rust and Cargo dev environment with the specific
# tools needed for working on harrison.ai Rust projects.
#
FROM rust:1.56.1-slim

# Install extra system dependencies not included in the slim base image.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # For helping to build some Rust crates.
    libssl-dev \
    pkg-config \
    # For cross-compilation to AWS Graviton2.
    gcc-aarch64-linux-gnu \
    libc-dev-arm64-cross \
    musl-tools \
    curl \
    make \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# General dev tools.
RUN rustup component add rustfmt
RUN rustup component add clippy

# Used for dependency license and security checks.
# Disabling default features lets it use the system ssl library,
# which should reduce overall size of the docker image.
RUN cargo install --version="0.11.0" --no-default-features cargo-deny \
  && rm -rf "$CARGO_HOME/registry"

# Used for generating license files for distribution to consumers,
# which may be required to compliance with some open-source licenses.
RUN cargo install --version="0.4.3" cargo-about \
  && rm -rf "$CARGO_HOME/registry"

# Configure cross-compilation support for AWS Graviton2 processors,
# and x86_64 linux static binary.
# We use musl to help produce smaller docker images.
RUN rustup target add aarch64-unknown-linux-musl x86_64-unknown-linux-musl
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-gnu-gcc

# Extra stuff required for cross-compiling the `ring` crate.
ENV CC_aarch64_unknown_linux_musl=aarch64-linux-gnu-gcc
ENV AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar

# Extra stuff required for x86_64 musl
# openssl crate supports OpenSSL 1.0.1 to 1.1.1 (not 3.0.0)
ENV SSL_VER="1.1.1l" \
    ZLIB_VER="1.2.11" \
    CC=musl-gcc \
    PREFIX=/musl \
    PATH=/usr/local/bin:/root/.cargo/bin:$PATH \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    LD_LIBRARY_PATH=$PREFIX

# Set up a prefix for musl build libraries, make the linker's job of finding them easier
# Primarily for the benefit of postgres.
# Lastly, link some linux-headers for openssl 1.1 (not used herein)
RUN mkdir $PREFIX && \
    echo "$PREFIX/lib" >> /etc/ld-musl-x86_64.path && \
    ln -s /usr/include/x86_64-linux-gnu/asm /usr/include/x86_64-linux-musl/asm && \
    ln -s /usr/include/asm-generic /usr/include/x86_64-linux-musl/asm-generic && \
    ln -s /usr/include/linux /usr/include/x86_64-linux-musl/linux

# Build zlib used in openssl
RUN curl -sSL https://zlib.net/zlib-$ZLIB_VER.tar.gz > zlib-${ZLIB_VER}.tar.gz && \
    echo "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1" \
    zlib-${ZLIB_VER}.tar.gz | sha256sum --check && \
    tar -xzf zlib-${ZLIB_VER}.tar.gz && \
    rm zlib-${ZLIB_VER}.tar.gz && \
    cd zlib-$ZLIB_VER && \
    CC="musl-gcc -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" ./configure --static --prefix=$PREFIX && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf zlib-$ZLIB_VER

# Build openssl 
RUN curl -sSL https://www.openssl.org/source/openssl-${SSL_VER}.tar.gz > openssl-${SSL_VER}.tar.gz && \
    echo "0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1" \
    openssl-${SSL_VER}.tar.gz | sha256sum --check && \
    tar -xzf openssl-${SSL_VER}.tar.gz && \
    rm openssl-${SSL_VER}.tar.gz && \
    cd openssl-$SSL_VER && \
    ./Configure no-shared -fPIC --prefix=$PREFIX --openssldir=$PREFIX/ssl linux-x86_64 && \
    env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
    make -j$(nproc) && make install_sw && \
    cd .. && rm -rf openssl-$SSL_VER

ENV PATH=$PREFIX/bin:$PATH \
    PKG_CONFIG_ALLOW_CROSS=true \
    PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
    OPENSSL_STATIC=true \
    OPENSSL_DIR=$PREFIX \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs \
    LIBZ_SYS_STATIC=1

# An easy way to run our standard suite of CI checks.
COPY ./scripts/cargo-hai-all-checks /usr/local/cargo/bin
