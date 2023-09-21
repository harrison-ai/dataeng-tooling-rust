# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
but version numbers for this repo and a little complicated because they track
both the Rust version and our own changes no top; consult [`./README.md`] for details.

Every commit to `main` in this project creates a new release and hence must have
a new version number. Fill in an appropriate changelog entry in this file to
get CI passing and enable the changes to land on `main`.
``

## 1.72-1.1

- Updated Rust version to `1.72.1`
- Updated `cargo-about` to `0.5.7`
- Updated `cargo-deny` to `0.14.2`
- Updated `cargo-make` to `0.37.1`
- Updated `cargo-release` to `0.24.12`

## 1.72-1.0

- Updated Rust version to `1.72.0`

## 1.70-1.1

- Added cargo machete to find unused dependencies.

## 1.70-1.0

- Updated Rust version to `1.70.0`

## 1.67-1.1

- Migrate from Dockerhub to Github Container Registry

## 1.67-1.0

- Updated Rust version to `1.67.1`

## 1.65-1.0

- Updated Rust version to `1.65.0`

## 1.64-1.0

- Updated Rust version to `1.64.0`

## 1.63-1.1

- Added `cargo-make` to the image, for defining dev & build tasks.

## 1.63-1.0

- Updated Rust version to `1.63.0`

## 1.62-1.2

- Fix linker errors when building `[[bin]]` targets, by explicitly setting the
  appropriate linker in environment variables.

## 1.62-1.1

- Updated Rust version to `1.62.1`

## 1.62-1.0

- Publish both `amd64` and `arm64` docker images. This should provide
  for a much faster build experience for users on aarch64 platforms,
  in particular the Mac M1. Several significant breaking changes have
  been introduced to support this changes:
  - Cargo now builds for the `-musl` target of the host platform by default, meaning
    it will produce build artifacts under `/target/[x86_64|aarch64]-unkown-linux-musl/`
    rather than the default `./target/`.
  - The details and layout of musl build tooling in the image was significantly
    refactored. Users depending on the availability of e.g. `musl-gcc` will need
    to review what tools are available in the new image and adjust their usage
    accordingly.
  - Docker image building is now performed using `docker buildx`, which in addition
    to simplifying support for multi-platform images, brings a number of efficiency
    and cachability benefits.
- Updated Rust version to `1.62.0`.
- Updated OpenSSL to `1.1.1q`.
- Updated `cargo-deny` to `0.12.1`.
- Updated `cargo-release` to `0.21.0`.
- Removed zlib as a pre-built system dependency, as it doesn't seem to be
  needed in practice.

## 1.60-0.2

- Bump GitHub Actions docker digest

## 1.60-0.1

- Updated Rust version to `1.60.0`
- Updated `cargo-deny` to `0.11.4`
- Updated `cargo-about` to `0.5.1`
- Updated `cargo-release` to `0.20.5`
- Updated `zlib` to `1.2.12`
- Updated GitHub Actions docker images

## 1.58-0.1

- Updated Rust version to `1.58.1`.

## 1.57-0.3

- Added `curl` and `jq` to the image, since we've been frequently finding
  ourselves needing these for customization.

## 1.57-0.2

- Added `cargo-release` to the image, for easily cutting releases.

## 1.57-0.1

- Updated Rust version to `1.57.0`.

## 1.56-0.5

- Sped up build time of the docker image by sharing build artifacts
  between runs of `cargo install`.

## 1.56-0.4

- Added `cargo-about` for generating a license file describing the
  open-source dependencies used in a project.
- Updated `cargo-deny` to v0.11.0. This is a semver-breaking change
  for `cargo-deny` because it updated its minimum supported Rust version
  to 1.56.1, but we're already on that version of Rust anyway so it's
  not semver-breaking for this docker image.

## 1.56-0.3

- Added x86_64-unknown-linux-musl cargo target support.
- Add static compliation of openssl and zlib.

## 1.56-0.2

### Changed

- The bundled `cargo-deny` now links against the system OpenSSL rather than
  its own bundled copy.

### Removed

- The base image now derives from the "slim" debian variant, meaning that
  a lot of system tools have been removed. For example, `curl` is no longer
  present by default in the image.

## 1.56-0.1

### Added

- The first release of this docker image, including Rust version `1.56.1` and
  some basic scripting around `cargo-deny`.

## 1.56-0.0

This is a stub version for the initial commit, not corresponding to an
actual release of the image.
