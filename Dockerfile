# Prepare the build environment.
# Use this stage to add certificates and setting proxies
# All ARGs need to be set via the docker `--build-arg` flags.
ARG GO_BUILD_IMAGE
FROM $GO_BUILD_IMAGE AS build
ARG GO_BUILD_IMAGE
ARG RUN_IMAGE
ARG GLOOE_VERSION
ARG PLUGIN_PATH
ARG PLUGIN_BUILD_NAME
ARG PLUGIN_FRAMEWORK_PATH
ARG PLUGIN_FRAMEWORK_VERSION
ARG PLUGIN_FRAMEWORK_URL
ARG STORAGE_HOSTNAME


ARG GLOOE_DIR=_glooe
ARG VERIFY_SCRIPT=$GLOOE_DIR/verify-plugins-linux-amd64

WORKDIR /go/src/$PLUGIN_PATH

# Downaload and extract plugin framework.
ADD ${PLUGIN_FRAMEWORK_URL}/archive/${PLUGIN_FRAMEWORK_VERSION}.tar.gz .
RUN mkdir -p /go/src/$PLUGIN_FRAMEWORK_PATH && tar -zxvf ${PLUGIN_FRAMEWORK_VERSION}.tar.gz --strip 1 -C /go/src/$PLUGIN_FRAMEWORK_PATH

# Retrieve GlooE build information
RUN mkdir -p $GLOOE_DIR/ && \
    for x in dependencies verify-plugins-linux-amd64 build_env ; do \
        wget -O $GLOOE_DIR/${x} http://${STORAGE_HOSTNAME}/gloo-ee-dependencies/${GLOOE_VERSION}/${x}; \
    done

# Copy the plugin implementation
COPY plugin/ ./

# Resolve dependencies and ensure dependency version usage and build image type and version
RUN go run /go/src/$PLUGIN_FRAMEWORK_PATH/scripts/resolve_deps/main.go go.mod $GLOOE_DIR/dependencies
RUN echo "// Generated for GlooE $GLOOE_VERSION" | cat - go.mod > go.new && mv go.new go.mod

# Fail if we are not using the same image GlooE is build with
RUN Glooe_build_image=$(grep GO_BUILD_IMAGE $GLOOE_DIR/build_env | cut -d '=' -f 2-) && \
    if [ "$GO_BUILD_IMAGE" != "${Glooe_build_image}" ]; then echo "Go build image '$GO_BUILD_IMAGE' is invalid. Use '${Glooe_build_image}'" && pwd && ls -al && exit 1; fi

# Build plugin
ENV CGO_ENABLED=1 GOARCH=amd64 GOOS=linux
RUN go build -buildmode=plugin \
             -gcflags="$(grep GC_FLAGS $GLOOE_DIR/build_env | cut -d '=' -f 2-)" \
             -o $PLUGIN_BUILD_NAME.so plugin.go \
             || { echo "Used module:" | cat - go.mod; exit 1; }

# Run the script to verify that the plugin can be loaded by Gloo
RUN chmod +x $VERIFY_SCRIPT \
    $VERIFY_SCRIPT -pluginDir ./ -manifest plugin_manifest.yaml

# This stage builds the final image containing just the plugin .so files. It can really be any linux/amd64 image.
FROM $RUN_IMAGE
ARG PLUGIN_PATH
ARG PLUGIN_BUILD_NAME

# Copy compiled plugin file from previous stage
RUN mkdir /compiled-auth-plugins
COPY --from=build /go/src/$PLUGIN_PATH/$PLUGIN_BUILD_NAME.so /compiled-auth-plugins/
COPY --from=build /go/src/$PLUGIN_PATH/go.mod /compiled-auth-plugins/

# This is the command that will be executed when the container is run.
# It has to copy the compiled plugin file(s) to a directory.
CMD cp /compiled-auth-plugins/*.so /auth-plugins/