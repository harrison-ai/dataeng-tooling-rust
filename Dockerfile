########
#
# Docker image for a Rust and Cargo dev environment at harrison.ai.
#
# This Dockerfile builds on the standard `rust` Docker image, providing
# extra configuration and tools that we use when working on Rust projects
# at harrison.ai and partner ventures.
#
# We are specifically targetting a kind of 4-way matrix of host and target
# achitectures with this toolchain:
#
#  - We want to be able to produce statically-compiled binaries for both
#    `x86_64` targets (for deployment to generic Linux machines) and `aarch64`
#    targets (for deployment to AWS Graviton in the cloud)
#
#  - We want to be able to do it from either an `x86_64` host (typical Windows
#    or Linux dev machine) or an `aarch64` host (newer Mac dev machines)
#
# The image uses musl and Rust's support for musl-based cross-compilation
# to support all four scenarios from a single Dockerfile, and uses the builder
# pattern described at [1] for efficiently building the images.
#
# [1] https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/
#
########

####
#
# Builder image.
#
# This runs on the native architecture of the build platform, and is where
# we want to do all the compute-heavy compilation tasks like installing rust
# tools from source, or compiling binary system dependencies. Such artifacts
# are cross-compiled for inclusion in the runtime image.
#
####

FROM --platform=$BUILDPLATFORM rust:1.82.0-slim AS builder

WORKDIR /build

## First, we're going to do all the build tasks that do not depend on $TARGETPLATFORM.
##
## This will allow the docker build cache to share the resulting artifacts between
## different $TARGETPLATFORM builds.

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update  && \
  apt-get install -y --no-install-recommends \
    curl \
    make \
    pkg-config \
    gcc-aarch64-linux-gnu \
    linux-libc-dev-amd64-cross \
    gcc-x86-64-linux-gnu \
    linux-libc-dev-arm64-cross \
    libfindbin-libs-perl

# Build musl, for both target architectures.
#
# Rust ships with its own pre-compiled musl libs for each target platform, but crates that
# compile C code need a more complete musl compiler environment. Using the existing `musl-tools`
# package would work for native builds, but doesn't help us when cross-compiling. For simplicity
# and consistency, we ship a build of musl for both of the target architectures.
#
# This will produce `/musl/x86_64/` and `/musl/aarch64/` respectively.

ENV MUSL_VER="1.2.5" \
    MUSL_PREFIX=/musl

RUN curl -sSL  https://musl.libc.org/releases/musl-${MUSL_VER}.tar.gz > musl-${MUSL_VER}.tar.gz && \
    echo "a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4" \
    musl-${MUSL_VER}.tar.gz | sha256sum --check

RUN tar -xzf musl-${MUSL_VER}.tar.gz && \
    cd musl-${MUSL_VER} && \
    CC=x86_64-linux-gnu-gcc ./configure --prefix=${MUSL_PREFIX}/amd64 --enable-wrapper=gcc --disable-shared && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf musl-${MUSL_VER}

RUN tar -xzf musl-${MUSL_VER}.tar.gz && \
    cd musl-${MUSL_VER} && \
    CC=aarch64-linux-gnu-gcc ./configure --prefix=${MUSL_PREFIX}/arm64 --enable-wrapper=gcc --disble-shared && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf musl-${MUSL_VER}

# Add some helper tools for compiling with those versions of musl.
# This is mostly about providing tools with standard names, to avoid having to configure
# various buildscripts with custom tools.

ENV PATH=${MUSL_PREFIX}/bin:$PATH

COPY ./scripts/x86_64-linux-musl-gcc ${MUSL_PREFIX}/bin/x86_64-linux-musl-gcc
RUN ln -s /usr/bin/x86_64-linux-gnu-ar ${MUSL_PREFIX}/bin/x86-64-linux-musl-ar

COPY ./scripts/aarch64-linux-musl-gcc ${MUSL_PREFIX}/bin/aarch64-linux-musl-gcc
RUN ln -s /usr/bin/aarch64-linux-gnu-ar ${MUSL_PREFIX}/bin/aarch64-linux-musl-ar

# Build OpenSSL with our musl toolchain.
#
# OpenSSL is unfortunately a common dependency in the Rust ecosystem, and it's fiddly to use
# with cross-compiled static targets, so we provide it as a pre-built dependency. As with musl itself,
# for simplicity and consistency, we ship a build for both of the target architectures.

ENV SSL_VER="3.3.1"

RUN curl -sSL https://www.openssl.org/source/openssl-${SSL_VER}.tar.gz > openssl-${SSL_VER}.tar.gz && \
    echo "777cd596284c883375a2a7a11bf5d2786fc5413255efab20c50d6ffe6d020b7e" \
    openssl-${SSL_VER}.tar.gz | sha256sum --check

RUN tar -xzf openssl-${SSL_VER}.tar.gz && \
    cd openssl-${SSL_VER} && \
    CC="x86_64-linux-musl-gcc -static" ./Configure no-shared -fPIC -I/usr/x86_64-linux-gnu/include --prefix=${MUSL_PREFIX}/amd64 --openssldir=${MUSL_PREFIX}/amd64/ssl linux-x86_64 && \
    make depend && \
    make -j$(nproc) && make install_sw && \
    cd .. && rm -rf openssl-${SSL_VER}

RUN tar -xzf openssl-${SSL_VER}.tar.gz && \
    cd openssl-${SSL_VER} && \
    CC="aarch64-linux-musl-gcc -static" ./Configure no-shared -fPIC -I/usr/aarch64-linux-gnu/include --prefix=${MUSL_PREFIX}/arm64 --openssldir=${MUSL_PREFIX}/arm64/ssl linux-aarch64 && \
    make depend && \
    make -j$(nproc) && make install_sw && \
    cd .. && rm -rf openssl-${SSL_VER}

# Configure cargo to use the right musl bits and pieces.
# The runtime image also needs these, so make sure any changes are applied in both places.

ENV CC_x86_64_unknown_linux_musl=x86_64-linux-musl-gcc \
    CC_aarch64_unknown_linux_musl=aarch64-linux-musl-gcc \
    AR_x86_64_unknown_linux_musl=x86_64-linux-gnu-ar \
    AR_aarch64_unknown_linux_musl=aarch64-linux-gnu-ar \
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=rust-lld \
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=rust-lld \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=${MUSL_PREFIX}/amd64 \
    AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=${MUSL_PREFIX}/arm64


## From here, we can start doing things that depend on $TARGETPLATFORM.
##
## We won't be able to re-use the resulting artifacts across docker build runs for
## different platforms, but at least they'll build quickly because they're running
## in the native builder image.

ARG TARGETPLATFORM
ARG TARGETARCH

# We build with a shared target-dir so that cargo can share intermediate compile artifacts
# rather than aving to build everything from scratch, which saves a lot of compile time
# in release mode.

COPY ./scripts/docker-target-triple ./

RUN rustup target add `./docker-target-triple`

ENV CARGO_TARGET_DIR=/build/target

# Default to building for the appropriate musl target on this platform.
# This ensures that e.g. running tests without specifying an explicit target,
# will use all the musl stuff that we configured above.

RUN echo "[build]\ntarget=\"`./docker-target-triple`\"" > ${CARGO_HOME}/config.toml

# Build some helpful extra Rust utilities.
#
# The use of `sharing=locked` here is to prevent two instances of the install from updating
# the local registry cache at the same time, which can cause one to fail. Ideally we would
# only hold the lock while updating the registry cache, rather than while doing the whole
# build...but cargo doesn't seem to have a separate "update the registry cache" operation.

RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
  --mount=type=cache,target=/build/target \
  export CARGO_BUILD_TARGET=`./docker-target-triple` && \
  # cargo-deny: used for dependency license and security checks.
  cargo install --version="0.16.1" cargo-deny && \
  # cargo-about: used for generating license files for distribution to consumers,
  #              which may be required for compliance with some open-source licenses.
  cargo install --version="0.6.4" cargo-about && \
  # cargo-make: used for defining dev & build tasks.
  cargo install --version="0.37.16" cargo-make && \
  # cargo-release: used for cutting releases.
  cargo install --version="0.25.11" cargo-release && \
  # cargo-machete: used for finding unused dependencies.
  cargo install --version="0.6.2" cargo-machete && \
  # cargo-sort: used for formatting dependencies in Cargo.toml files.
  cargo install --version="1.0.9" cargo-sort


####
#
# Runtime image
#
# This is the image that actually gets published and used, and we build a version of
# it for each target platform.
#
# The instructions here are very likely to be executed under an emulator for at least
# one of our target platforms, so you should be careful to avoid any CPU-intensive tasks.
# Such work should be done in the builder image above, cross-compiling for $TARGETPLATFORM.
#
####

FROM rust:1.82.0-slim

# Install extra system dependencies not included in the slim base image.
RUN  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update  && \
  apt-get install -y --no-install-recommends \
    jq \
    curl \
    make \
    git \
    ca-certificates \
    gcc-aarch64-linux-gnu \
    linux-libc-dev-amd64-cross \
    gcc-x86-64-linux-gnu \
    linux-libc-dev-arm64-cross

# General dev tools.
RUN rustup component add rustfmt
RUN rustup component add clippy

# Our two main compilation targets.
RUN rustup target add \
  aarch64-unknown-linux-musl \
  x86_64-unknown-linux-musl

# Copy the built musl system-level dependencies and associated config.
ENV MUSL_PREFIX=/musl

COPY --from=builder ${MUSL_PREFIX} ${MUSL_PREFIX}

ENV PATH=${MUSL_PREFIX}/bin:$PATH

# Configure cargo to use the right musl bits and pieces.
# The builder image also needs these, so make sure any changes are applied in both places.
ENV CC_x86_64_unknown_linux_musl=x86_64-linux-musl-gcc \
    CC_aarch64_unknown_linux_musl=aarch64-linux-musl-gcc \
    AR_x86_64_unknown_linux_musl=x86_64-linux-gnu-ar \
    AR_aarch64_unknown_linux_musl=aarch64-linux-gnu-ar \
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=rust-lld \
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=rust-lld \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=${MUSL_PREFIX}/amd64 \
    AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=${MUSL_PREFIX}/arm64

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs

COPY --from=builder ${CARGO_HOME}/config.toml ${CARGO_HOME}/config.toml

# Copy the built additional cargo tooling.
COPY --from=builder \
  ${CARGO_HOME}/bin/cargo-deny \
  ${CARGO_HOME}/bin/cargo-about \
  ${CARGO_HOME}/bin/cargo-make \
  ${CARGO_HOME}/bin/cargo-release \
  ${CARGO_HOME}/bin/cargo-machete \
  ${CARGO_HOME}/bin/cargo-sort \
  ${CARGO_HOME}/bin/

# Add additional not-natively-compiled cargo tooling.
COPY ./scripts/cargo-hai-all-checks ${CARGO_HOME}/bin/
