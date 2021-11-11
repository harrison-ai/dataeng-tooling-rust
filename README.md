
# Rust build and development tooling for harrison.ai

This repository builds the [`harrisonai/rust`](https://hub.docker.com/r/harrisonai/rust)
docker image, a convenient collection of Rust build and development tooling
for working with Rust-based projects in the harrison.ai Data Engineering team.

The docker image provides:

* Rust, rustup, cargo and friends, like you'd get from a standard Rust dev image.
* Pre-configured components and settings to cross-compile for `aarch64` targets,
  for deployment to AWS
* [`cargo-deny`](https://embarkstudios.github.io/cargo-deny/) and some default
  configuration for checking dependency licenses and security warnings.
* A custom `cargo hai-all-checks` command to easily run our standard suite of
  quality checks from a CI environment.

## Using the image

TODO: flesh out these docs.

* You can just run it to get started, like this: [...]
* Use 3-musketeers pattern with this docker-compose config.
* Use our cookiecutter, with cruft.

## Tags and Versioning

In an attempt to minimise possible confusion for users, the docker image version
reflects the underlying Rust version down to semver-minor level and appends a
separate version number for the customizations that we layer on top. The general
form is `harrisonai/rust:M.NN-X.Y` where:

* `M.NN` is the semver-minor version of Rust included in the image.
* `X.Y` is a major.minor version number for changes in this repo.

So for example, `harrisonai/rust:1.56-1.3` would include the Rust toolchain at
some version in the `1.56` series, and be the third release of our customizations
on top of that series.

Every commit to `main` in this repo creates a new version that is automatically
built and pushed to dockerhub, with version number updated according to the following
rules:

* If the change were purely additive (e.g. installing some additional tools, or a new
  point release of Rust) then it would move the version from `1.56-1.3` to `1.56-1.4`.
* If the change had the potential for breakage (such as replacing `cargo-deny` with a
  different tool) then it would move the version from `1.56-1.3` to `1.56-2.0`.
* If the change updated to a new major or minor version of Rust, then it would move
  the version from `1.56-1.3` to `1.57-1.0`.

We also provide floating semver tags if you don't want to pin to a specific release:

* `harrisonai/rust:M.NN-X` tracks the latest additive updates but should never pull
  in any breaking changes.
* `harrisonai/rust:M.NN` tracks all updates other than Rust version changes, and might
  potentially receive breaking changes in the surrounding tooling.

But please note that assessment of possible breaking changes is based purely on a
best-effort human-in-the-loop basis.

The scripting to manage all this is under [`./scripts`](./scripts) and is orchestrated
by GitHub Actions.
