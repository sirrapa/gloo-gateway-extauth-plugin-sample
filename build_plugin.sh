#!/bin/bash -e

GO_BUILD_IMAGE=golang:1.13
GLOOE_VERSION=1.3.0
STORAGE_HOSTNAME=storage.googleapis.com
GITHUB_PROXY=


CONTAINER_GOPATH=/go
plugin_framework_version=v0.2.1
plugin_name=sample
plugin_version=0.0.1
plugin_image="gloo-ext-auth-plugin-${plugin_framework_version/:/-}-${plugin_name}:${plugin_version/:/-}"
plugin_path=${CONTAINER_GOPATH}/src/sirrapa.com/k8s/gloo-gateway/extauth-plugin/${plugin_name}
plugin_output_path=_output

# Build image which holds the plugin framework and custom implementation
docker build --no-cache -f Dockerfile \
    --build-arg ENV_GLOOE_VERSION=1.3.0 \
    --build-arg ENV_STORAGE_HOSTNAME=$STORAGE_HOSTNAME \
    --build-arg GO_BUILD_IMAGE=$GO_BUILD_IMAGE \
    --build-arg PLUGIN_FRAMEWORK_VERSION=$plugin_framework_version \
    --build-arg PLUGIN_PATH=$plugin_path \
    -t $plugin_image .


## run the image and some make tasks
#docker run \
#        -e GLOOE_VERSION=${GLOOE_VERSION} \
#        -e STORAGE_HOSTNAME=${STORAGE_HOSTNAME} \
#        ${plugin_image} make compare-deps
##        -v $(pwd)$/{plugin_output_path}:${plugin_path} \

