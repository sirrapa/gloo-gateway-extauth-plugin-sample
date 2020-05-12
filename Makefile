
.PHONY: format
format:
	gofmt -w -e pkg scripts
	goimports -w -e pkg scripts

#----------------------------------------------------------------------------------
# Set build variables
#----------------------------------------------------------------------------------
# Set this variable to the name of your plugin
PLUGIN_NAME ?= sample

# Set this variable to the version of your plugin
PLUGIN_VERSION ?= 0.0.1

# Set this variable to the version of GlooE you want to target
GLOOE_VERSION ?= 1.3.1

# Set this variable to the image name and version used for building the plugin
GO_BUILD_IMAGE ?= golang:1.14.0-buster
RUN_IMAGE ?= alpine:3.10

# Set this variable to the module name of the (forked) plugin framework you want to target
PLUGIN_FRAMEWORK_PATH ?= github.com/sirrapa/ext-auth-plugin-examples

# Set this variable to the url of your custom (air gapped) github server
PLUGIN_FRAMEWORK_URL ?= https://$(PLUGIN_FRAMEWORK_PATH)

# Set this variable to the version of the plugin framework you want to target
PLUGIN_FRAMEWORK_VERSION ?= v0.2.2-beta8
#PLUGIN_FRAMEWORK_VERSION ?= master

# Set this variable to the hostname of your custom (air gapped) storage server
STORAGE_HOSTNAME ?= storage.googleapis.com

FRAMEWORK_BUILD_IMAGE := gloo-ext-auth-plugin-framework:$(PLUGIN_FRAMEWORK_VERSION)
PLUGIN_PATH := $(shell grep module go.mod | cut -d ' ' -f 2-)
PLUGIN_IMAGE := gloo-ext-auth-plugin-$(PLUGIN_FRAMEWORK_VERSION)-$(PLUGIN_NAME):$(PLUGIN_VERSION)

#----------------------------------------------------------------------------------
# Build an docker image which contains the plugin framework
#----------------------------------------------------------------------------------
.PHONY: framework-image
framework-image: pull-framework-image build-framework-image push-framework-image
push-framework-image:
	docker push $(FRAMEWORK_BUILD_IMAGE)
build-framework-image:
	docker build \
		--build-arg GO_BUILD_IMAGE=$(GO_BUILD_IMAGE) \
		--build-arg GLOOE_VERSION=$(GLOOE_VERSION) \
		--build-arg PLUGIN_FRAMEWORK_PATH=$(PLUGIN_FRAMEWORK_PATH) \
		--build-arg PLUGIN_FRAMEWORK_URL=$(PLUGIN_FRAMEWORK_URL) \
		--build-arg PLUGIN_FRAMEWORK_VERSION=$(PLUGIN_FRAMEWORK_VERSION) \
		--build-arg STORAGE_HOSTNAME=$(STORAGE_HOSTNAME) \
		-t $(FRAMEWORK_BUILD_IMAGE) -f Dockerfile.framework .
pull-framework-image:
	docker pull $(GO_BUILD_IMAGE)

#----------------------------------------------------------------------------------
# Build an docker image which contains the compiled plugin implementation
#----------------------------------------------------------------------------------
.PHONY: plugin-image
plugin-image: pull-plugin-image build-plugin-image push-plugin-image
push-plugin-image:
	docker push $(PLUGIN_IMAGE)
build-plugin-image:
	docker build --no-cache \
		--build-arg FRAMEWORK_BUILD_IMAGE=$(FRAMEWORK_BUILD_IMAGE) \
		--build-arg GLOOE_VERSION=$(GLOOE_VERSION) \
		--build-arg PLUGIN_FRAMEWORK_PATH=$(PLUGIN_FRAMEWORK_PATH) \
		--build-arg PLUGIN_PATH=$(PLUGIN_PATH) \
		--build-arg RUN_IMAGE=$(RUN_IMAGE) \
		--build-arg STORAGE_HOSTNAME=$(STORAGE_HOSTNAME) \
		-t $(PLUGIN_IMAGE) .
pull-plugin-image:
	docker pull $(FRAMEWORK_BUILD_IMAGE)

