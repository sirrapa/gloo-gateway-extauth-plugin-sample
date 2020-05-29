# Prepare the build environment.
# Use this stage to add certificates and set proxy
# All ARGs need to be set via the docker `--build-arg` flags.
ARG GO_BUILD_IMAGE
ARG RUN_IMAGE
FROM $GO_BUILD_IMAGE AS build
ARG RUN_IMAGE
ARG GLOOE_VERSION
ARG PLUGIN_BUILD_NAME
ARG PLUGIN_MODULE_PATH
ARG PLUGIN_NAME
ARG PLUGIN_BUILDER_MODULE_PATH
ARG PLUGIN_BUILDER_VERSION
ARG PLUGIN_BUILDER_URL
ARG STORAGE_HOSTNAME

# Fail if not all ARGs are set
RUN if [ ! $RUN_IMAGE ]; then echo "Required RUN_IMAGE build argument not set" && exit 1; fi && \
    if [ ! $GLOOE_VERSION ]; then echo "Required GLOOE_VERSION build argument not set" && exit 1; fi && \
    if [ ! $PLUGIN_BUILD_NAME ]; then echo "Required PLUGIN_BUILD_NAME build argument not set" && exit 1; fi && \
    if [ ! $PLUGIN_MODULE_PATH ]; then echo "Required PLUGIN_MODULE_PATH build argument not set" && exit 1; fi && \
    if [ ! $$PLUGIN_NAME ]; then echo "Required $PLUGIN_NAME build argument not set" && exit 1; fi && \
    if [ ! $PLUGIN_BUILDER_MODULE_PATH ]; then echo "Required PLUGIN_BUILDER_MODULE_PATH build argument not set" && exit 1; fi && \
    if [ ! $PLUGIN_BUILDER_VERSION ]; then echo "Required PLUGIN_BUILDER_VERSION build argument not set" && exit 1; fi && \
    if [ ! $PLUGIN_BUILDER_URL ]; then echo "Required PLUGIN_BUILDER_URL build argument not set" && exit 1; fi && \
    if [ ! $STORAGE_HOSTNAME ]; then echo "Required STORAGE_HOSTNAME build argument not set" && exit 1; fi

RUN apk add --no-cache gcc musl-dev git make

# Copy the plugin implementation
WORKDIR /go/src/$PLUGIN_MODULE_PATH
COPY go.mod go.sum ./
COPY pkg ./pkg


# Start Building the plugin
WORKDIR /go/src/$PLUGIN_BUILDER_MODULE_PATH

# Downaload and extract plugin framework.
RUN mkdir -p /go/src/$PLUGIN_BUILDER_MODULE_PATH && \
    wget -O - $PLUGIN_BUILDER_URL/archive/$PLUGIN_BUILDER_VERSION.tar.gz | \
    tar -zxvf - --strip 1 -C . && \
    rm -Rf ./plugins/required_header

# Copy the plugin
COPY plugin_manifest.yaml ./plugins/
COPY plugin*.go ./plugins/$PLUGIN_NAME/

# Resolve dependencies and ensure dependency version usage
RUN make resolve-deps
RUN echo "// Generated for GlooE $GLOOE_VERSION" | cat - go.mod > go.new && mv go.new go.mod

# Run compile and verify the plugin can be loaded by Gloo
RUN GLOOE_VERSION=$GLOOE_VERSION \
    PLUGIN_NAME=$PLUGIN_NAME \
    PLUGIN_BUILD_NAME=$PLUGIN_BUILD_NAME \
    PLUGIN_MODULE_PATH=$PLUGIN_MODULE_PATH \
    STORAGE_HOSTNAME=$STORAGE_HOSTNAME \
    make build-plugin || { echo "Used module:" | cat - go.mod; exit 1; }
#RUN CGO_ENABLED=1 GOARCH=amd64 GOOS=linux \
#    go build -buildmode=plugin -gcflags='all=-N -l' -o plugins/$PLUGIN_BUILD_NAME plugin.go \
#             || { echo "Used module:" | cat - go.mod; exit 1; }

## Run the script to verify that the plugin can be loaded by Gloo
#RUN chmod +x $VERIFY_SCRIPT && \
#    $VERIFY_SCRIPT -pluginDir plugins -manifest plugin_manifest.yaml

# This stage builds the final image containing just the plugin .so files. It can really be any linux/amd64 image.
FROM $RUN_IMAGE
ARG PLUGIN_BUILDER_MODULE_PATH

# Copy compiled plugin file from previous stage
RUN mkdir /compiled-auth-plugins
COPY --from=build /go/src/$PLUGIN_BUILDER_MODULE_PATH/plugins/*.so /compiled-auth-plugins/

# This is the command that will be executed when the container is run.
# It has to copy the compiled plugin file(s) to a directory.
CMD cp /compiled-auth-plugins/*.so /auth-plugins/