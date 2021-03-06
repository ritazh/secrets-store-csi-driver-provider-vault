REGISTRY_NAME?=docker.io/hashicorp
IMAGE_NAME=secrets-store-csi-driver-provider-vault
IMAGE_VERSION?=$(shell git tag | tail -1)
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(IMAGE_VERSION)
IMAGE_TAG_LATEST=$(REGISTRY_NAME)/$(IMAGE_NAME):latest
LDFLAGS?='-X github.com/hashicorp/secrets-store-csi-driver-provider-vault/main.version=$(IMAGE_VERSION) -extldflags "-static"'
GOOS=linux
GOARCH=amd64

.PHONY: all build image clean test-style

GO111MODULE ?= on
export GO111MODULE

HAS_GOLANGCI := $(shell command -v golangci-lint;)

all: build

test: test-style
	go test github.com/deislabs/secrets-store-csi-driver/pkg/... -cover
	go vet github.com/deislabs/secrets-store-csi-driver/pkg/...

test-style: setup
	@echo "==> Running static validations and linters <=="
	golangci-lint run

sanity-test:
	go test -v ./test/sanity

build: setup
	CGO_ENABLED=0 go build -tags 'no_mock_provider' -a -ldflags ${LDFLAGS} -o _output/secrets-store-csi-driver-provider-vault_$(GOOS)_$(GOARCH)_$(IMAGE_VERSION) main.go provider.go 

image: build 
	docker build --build-arg VERSION=$(IMAGE_VERSION) --no-cache -t $(IMAGE_TAG) .

docker-push: image
	docker push $(IMAGE_TAG)
	docker tag $(IMAGE_TAG) $(IMAGE_TAG_LATEST)
	docker push $(IMAGE_TAG_LATEST)

clean:
	-rm -rf _output

setup: clean
	@echo "Setup..."
	$Q go env

.PHONY: mod
mod:
	@go mod tidy
