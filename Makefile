
.PHONY: format
format:
	gofmt -w -e pkg scripts
	goimports -w -e pkg scripts

#----------------------------------------------------------------------------------
# Set build variables
#----------------------------------------------------------------------------------
# Set this variable to the image name and version used for building the plugin
GO_BUILD_IMAGE ?= golang:1.14.0-alpine

RUN_IMAGE ?= alpine:3.10

# Set this variable to the version of GlooE you want to target
GLOOE_VERSION ?= 1.3.1

# Set this variable to the name of your plugin
PLUGIN_NAME ?= Sample

# Set this variable to the version of your plugin
PLUGIN_VERSION ?= 0.0.1

PLUGIN_IMAGE ?= gloo-ext-auth-plugin-$(GLOOE_VERSION)-sample:$(PLUGIN_VERSION)

# Set this variable to the module name of the (forked) plugin framework you want to target
PLUGIN_FRAMEWORK_PATH ?= github.com/sirrapa/ext-auth-plugin-examples

# Set this variable to the url of your custom (air gapped) github server
PLUGIN_FRAMEWORK_URL ?= https://$(PLUGIN_FRAMEWORK_PATH)

# Set this variable to the version of the plugin framework you want to target
PLUGIN_FRAMEWORK_VERSION ?= v0.2.2-beta8

# Set this variable to the hostname of your custom (air gapped) storage server
STORAGE_HOSTNAME ?= storage.googleapis.com

PLUGIN_PATH := $(shell grep module plugin/go.mod | cut -d ' ' -f 2-)

#----------------------------------------------------------------------------------
# Build an docker image which contains the compiled plugin implementation
#----------------------------------------------------------------------------------
.PHONY: plugin-image
plugin-image:
	docker build --no-cache \
		--build-arg GO_BUILD_IMAGE=$(GO_BUILD_IMAGE) \
		--build-arg GLOOE_VERSION=$(GLOOE_VERSION) \
		--build-arg PLUGIN_FRAMEWORK_PATH=$(PLUGIN_FRAMEWORK_PATH) \
		--build-arg PLUGIN_FRAMEWORK_VERSION=$(PLUGIN_FRAMEWORK_VERSION) \
		--build-arg PLUGIN_NAME=$(PLUGIN_NAME) \
		--build-arg PLUGIN_FRAMEWORK_URL=$(PLUGIN_FRAMEWORK_URL) \
		--build-arg PLUGIN_PATH=$(PLUGIN_PATH) \
		--build-arg RUN_IMAGE=$(RUN_IMAGE) \
		--build-arg STORAGE_HOSTNAME=$(STORAGE_HOSTNAME) \
		-t $(PLUGIN_IMAGE)  .

