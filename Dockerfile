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
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# General dev tools.
RUN rustup component add rustfmt
RUN rustup component add clippy

# Used for dependency license and security checks.
# Disabling default features lets it use the system ssl library,
# which should reduce overall size of the docker image.
RUN cargo install --version="0.10.1" --no-default-features cargo-deny \
  && rm -rf "$CARGO_HOME/registry"

# Configure cross-compilation support for AWS Graviton2 processors.
# We use musl to help produce smaller docker images.
RUN rustup target add aarch64-unknown-linux-musl
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-gnu-gcc

# Extra stuff required for cross-compiling the `ring` crate.
ENV CC_aarch64_unknown_linux_musl=aarch64-linux-gnu-gcc
ENV AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar

# An easy way to run our standard suite of CI checks.
COPY ./scripts/cargo-hai-all-checks /usr/local/cargo/bin
