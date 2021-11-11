#
# Configures a Rust and Cargo dev environment with the
# specific tools needed for working in this repo.
#
FROM rust:1.56.1

# General dev tools.
RUN rustup component add rustfmt
RUN rustup component add clippy

# Used for dependency license and security checks.
RUN cargo install --version="0.10.1" cargo-deny

# Cross-compilation support for AWS Graviton2 processors.
RUN apt-get update && apt-get install -y gcc-aarch64-linux-gnu && apt-get clean
RUN rustup target add aarch64-unknown-linux-musl
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-gnu-gcc

# Extra stuff required for cross-compiling the `ring` crate.
ENV CC_aarch64_unknown_linux_musl=aarch64-linux-gnu-gcc
ENV AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar

# An easy way to run our standard suite of CI checks.
COPY ./scripts/cargo-hai-all-checks /usr/local/cargo/bin