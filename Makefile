
.DEFAULT_GOAL := help

IMAGE="ghcr.io/harrison-ai/rust"

# Integrate docker cache with github actions.
BUILDX_CACHE_FROM =
BUILDX_CACHE_TO =
ifeq ($(GITHUB_ACTIONS), true)
    BUILDX_CACHE_FROM += --cache-from=type=local,src=/tmp/buildx-cache
    BUILDX_CACHE_TO += --cache-to=type=local,dest=/tmp/buildx-cache-new,mode=max
endif

# Conviences for running locally-built docker images.
UID = $(shell id -u)
DRUN = docker run \
	--rm \
	--user $(UID) \
    --volume "`pwd`:/app" \
    --volume "$(HOME)/.cargo/registry:/usr/local/cargo/registry" \
    --workdir "/app"

## build:			build docker images for local use
#
# We'd typically use `docker-compose` for managing locally-build docker images, but
# I wasn't able to get that to play nicely with the `docker buildx` build cache, and
# caching is very important for these expensive builds. So, we make our own ad-hoc
# system for managing local docker images using `make`, by exporting it from `buildx`
# as a tarball, loading it into the local docker, and writing the sha256 of the loaded
# image into a local file for future reference.
#
build: .built.amd64.image .built.arm64.image

.built.images: Makefile Dockerfile scripts/*
	# Building both images together should give better cache behaviour.
	docker buildx build $(BUILDX_CACHE_FROM) $(BUILDX_CACHE_TO) --platform  linux/amd64,linux/arm64 .

.built.%.image.tar: .built.images
	# The `.built.images` dependency will have exported the cache, don't waste time writing it out again.
	# It seems that we still need to *read* from the cache again though, at least in CI.
	docker buildx build $(BUILDX_CACHE_FROM) --platform "linux/$*" --output "type=docker,dest=$@" .

.built.%.image: .built.%.image.tar
	docker load -i $< | cut -d ' ' -f 4 > $@

## test:			test compilation of a local test project
#
# This tests operation of both the amd64 and arm64 variants of the docker image,
# so at least one of them will likely run under emulation in docker, depending
# on your native system architecture.
#
test: build
	$(DRUN) --platform=amd64 `cat .built.amd64.image` cargo test --manifest-path ./test_project/Cargo.toml
	$(DRUN) --platform=amd64 `cat .built.amd64.image` cargo build --manifest-path ./test_project/Cargo.toml --target x86_64-unknown-linux-musl
	$(DRUN) --platform=amd64 `cat .built.amd64.image` cargo build --manifest-path ./test_project/Cargo.toml --target aarch64-unknown-linux-musl

	$(DRUN) --platform=arm64 `cat .built.arm64.image` cargo test --manifest-path ./test_project/Cargo.toml
	$(DRUN) --platform=arm64 `cat .built.arm64.image` cargo build --manifest-path ./test_project/Cargo.toml --target x86_64-unknown-linux-musl
	$(DRUN) --platform=arm64 `cat .built.arm64.image` cargo build --manifest-path ./test_project/Cargo.toml --target aarch64-unknown-linux-musl

## publish:		build docker images and push to registry
#
publish:
	./scripts/check-clean-publish.sh
	export VERSION=`./scripts/version-number.sh` && \
	export RUST_VERSION=`echo $${VERSION} | cut -s -d '-' -f 1` && \
	export OUR_MAJOR_VERSION="$${RUST_VERSION}-`echo $${VERSION} | cut -s -d '-' -f 2 | cut -s -d '.' -f 1`" && \
	echo "Building image with tags: '$${VERSION}', '$${OUR_MAJOR_VERSION}', '$${RUST_VERSION}', 'latest'" && \
	docker buildx build $(BUILDX_CACHE_FROM) $(BUILDX_CACHE_TO) \
		--platform linux/amd64,linux/arm64 \
		-t "$(IMAGE):latest" \
		-t "$(IMAGE):$${VERSION}" \
		-t "$(IMAGE):$${OUR_MAJOR_VERSION}" \
		-t "$(IMAGE):$${RUST_VERSION}" \
		--push \
		.

## clean:			remove locally-built docker images
#
clean: clean-amd64 clean-arm64

clean-%:
	if [ -f .built.$*.image ]; then docker rmi -f `cat .built.$*.image`; fi
	rm -rf .built.$*.*

## help:			show this help
#
help:
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
