
.PHONY: format
format:
	gofmt -w -e pkg scripts
	goimports -w -e pkg scripts

#----------------------------------------------------------------------------------
# Set build variables
#----------------------------------------------------------------------------------
# Set this variable to the image name and version used for building the plugin
GO_BUILD_IMAGE ?= golang:1.14.0-alpine

RUN_IMAGE ?= alpine:3.11

# Set this variable to the version of GlooE you want to target
GLOOE_VERSION ?= 1.3.4

# Set this variable to the name of your plugin (no spaces)
PLUGIN_NAME ?= sample

# Set this variable to the name of your build plugin
PLUGIN_BUILD_NAME ?= Sample.so

# Set this variable to the version of your plugin
PLUGIN_VERSION ?= 0.0.1

# Set this variable to the module name of the (forked) plugin framework you want to target
PLUGIN_BUILDER_MODULE_PATH ?= github.com/solo-io/ext-auth-plugin-examples

# Set this variable to the url of your custom (air gapped) github server
PLUGIN_BUILDER_URL ?= https://$(PLUGIN_BUILDER_MODULE_PATH)

# Set this variable to the version of the plugin framework you want to target
PLUGIN_BUILDER_VERSION ?= master

# Set this variable to the hostname of your custom (air gapped) storage server
STORAGE_HOSTNAME ?= storage.googleapis.com

PLUGIN_MODULE_PATH := $(shell grep module go.mod | cut -d ' ' -f 2-)
PLUGIN_IMAGE ?= gloo-ext-auth-plugin-$(PLUGIN_BUILDER_VERSION)-sample-$(GLOOE_VERSION):$(PLUGIN_VERSION)

#----------------------------------------------------------------------------------
# Build an docker image which contains the compiled plugin implementation
#----------------------------------------------------------------------------------
.PHONY: plugin-image
plugin-image:
	docker build --no-cache \
		--build-arg GO_BUILD_IMAGE=$(GO_BUILD_IMAGE) \
		--build-arg GLOOE_VERSION=$(GLOOE_VERSION) \
		--build-arg PLUGIN_BUILDER_MODULE_PATH=$(PLUGIN_BUILDER_MODULE_PATH) \
		--build-arg PLUGIN_BUILDER_URL=$(PLUGIN_BUILDER_URL) \
		--build-arg PLUGIN_BUILDER_VERSION=$(PLUGIN_BUILDER_VERSION) \
		--build-arg PLUGIN_BUILD_NAME=$(PLUGIN_BUILD_NAME) \
		--build-arg PLUGIN_MODULE_PATH=$(PLUGIN_MODULE_PATH) \
		--build-arg PLUGIN_NAME=$(PLUGIN_NAME) \
		--build-arg RUN_IMAGE=$(RUN_IMAGE) \
		--build-arg STORAGE_HOSTNAME=$(STORAGE_HOSTNAME) \
		-t $(PLUGIN_IMAGE)  .

