# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
but version numbers for this repo and a little complicated because they track
both the Rust version and our own changes no top; consule [`./README.md`] for details.

Every commit to `main` in this project creates a new release and hence must have
a new version number. Fill in an appropriate changelog entry in this file to
get CI passing and enable the changes to land on `main`.

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
