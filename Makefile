
.DEFAULT_GOAL := help

git_ref:
	$(eval GIT_REF := $(shell git describe --tags --exact-match 2>/dev/null || git rev-parse --short=8 HEAD))

tag: app git_ref
	$(eval TAG := modelmill-$(APP):$(GIT_REF))

build-app: dc-build tag app
	docker build --platform arm64 -t $(TAG) ./src/$(APP)

## publish:			build docker images and push to registry
#
# This assumes a pre-existing ECR registry and a pre-existing repository in that registry
# called "modelmill-hello-world". Details of managing those repositories are TBD, probably
# via shared infrastructure.
#
# If the current checkout is a git tag, then the docker image will be labelled with
# that tag, otherwise it will be labelled with the git commit sha.
publish: build-app tag
	if [ -z "$(ECR)" ]; then echo "\nUsage: make publish ECR=<registry_url>\n"; exit 1; fi
	docker tag $(TAG) $(ECR)/$(TAG)
	aws ecr get-login-password | docker login --username AWS --password-stdin $(ECR)
	docker push $(ECR)/$(TAG)

## help:			show this help
help:
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
