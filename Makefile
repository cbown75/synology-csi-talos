#  Copyright 2021 Synology Inc.

REGISTRY_NAME=ghcr.io/cbown75
IMAGE_NAME=synology-csi
# Use date-based versioning instead of static version
DATE_TAG=$(shell date +'%Y%m%d')
DATETIME_TAG=$(shell date +'%Y%m%d-%H%M')
IMAGE_VERSION=$(DATE_TAG)
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(IMAGE_VERSION)

# For now, only build linux/amd64 platform
ifeq ($(GOARCH),)
GOARCH:=amd64
endif
GOARM?=""
BUILD_ENV=CGO_ENABLED=0 GOOS=linux GOARCH=$(GOARCH) GOARM=$(GOARM)
BUILD_FLAGS="-s -w -extldflags \"-static\""

.PHONY: all clean synology-csi-driver synocli test docker-build docker-build-date

all: synology-csi-driver

synology-csi-driver:
	@mkdir -p bin
	$(BUILD_ENV) go build -v -ldflags $(BUILD_FLAGS) -o ./bin/synology-csi-driver ./

docker-build:
	docker buildx build -t $(IMAGE_TAG) . --push

docker-build-multiarch:
	docker buildx build -t $(IMAGE_TAG) \
		-t $(REGISTRY_NAME)/$(IMAGE_NAME):latest \
		--platform linux/amd64,linux/arm/v7,linux/arm64 . --push

# New target for date-time based tags
docker-build-date:
	docker buildx build \
		-t $(REGISTRY_NAME)/$(IMAGE_NAME):$(DATE_TAG) \
		-t $(REGISTRY_NAME)/$(IMAGE_NAME):$(DATETIME_TAG) \
		-t $(REGISTRY_NAME)/$(IMAGE_NAME):latest \
		--platform linux/amd64,linux/arm64 . --push

synocli:
	@mkdir -p bin
	$(BUILD_ENV) go build -v -ldflags $(BUILD_FLAGS) -o ./bin/synocli ./synocli

test:
	go clean -testcache
	go test -v ./test/...

clean:
	-rm -rf ./bin
