# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
but version numbers for this repo and a little complicated because they track
both the Rust version and our own changes no top; consule [`./README.md`] for details.

Every commit to `main` in this project creates a new release and hence must have
a new version number. Fill in an appropriate changelog entry in this file to
get CI passing and enable the changes to land on `main`.

## 1.56-0.1

### Added

- The first release of this docker image, including Rust version `1.56.1` and
  some basic scripting around `cargo-deny`.
