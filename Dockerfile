# Prepare the build environment.
# Use this stage to add certificates and set proxy
# All ARGs need to be set via the docker `--build-arg` flags.
ARG GO_BUILD_IMAGE
ARG GO_VERIFY_IMAGE
FROM $GO_BUILD_IMAGE AS build
ARG GO_VERIFY_IMAGE
ARG RUN_IMAGE
ARG GLOOE_VERSION
ARG PLUGIN_NAME
ARG PLUGIN_PATH
ARG PLUGIN_FRAMEWORK_PATH
ARG PLUGIN_FRAMEWORK_VERSION
ARG PLUGIN_FRAMEWORK_URL
ARG STORAGE_HOSTNAME

# Fail if not all ARGs are set
RUN if [ ! $GO_VERIFY_IMAGE ]; then echo "Required GO_VERIFY_IMAGE build argument not set" && exit 1; fi
RUN if [ ! $RUN_IMAGE ]; then echo "Required RUN_IMAGE build argument not set" && exit 1; fi
RUN if [ ! $GLOOE_VERSION ]; then echo "Required GLOOE_VERSION build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_NAME ]; then echo "Required PLUGIN_NAME build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_PATH ]; then echo "Required PLUGIN_PATH build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_FRAMEWORK_PATH ]; then echo "Required PLUGIN_FRAMEWORK_PATH build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_FRAMEWORK_VERSION ]; then echo "Required PLUGIN_FRAMEWORK_VERSION build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_FRAMEWORK_URL ]; then echo "Required PLUGIN_FRAMEWORK_URL build argument not set" && exit 1; fi
RUN if [ ! $STORAGE_HOSTNAME ]; then echo "Required STORAGE_HOSTNAME build argument not set" && exit 1; fi

ARG GLOOE_DIR=_glooe

WORKDIR /go/src/$PLUGIN_PATH

# Downaload and extract plugin framework.
ADD ${PLUGIN_FRAMEWORK_URL}/archive/${PLUGIN_FRAMEWORK_VERSION}.tar.gz .
RUN mkdir -p /go/src/$PLUGIN_FRAMEWORK_PATH && \
    tar -zxvf ${PLUGIN_FRAMEWORK_VERSION}.tar.gz --strip 1 -C /go/src/$PLUGIN_FRAMEWORK_PATH && \
    rm -f ${PLUGIN_FRAMEWORK_VERSION}.tar.gz

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
RUN Glooe_verify_image=$(grep GO_BUILD_IMAGE $GLOOE_DIR/build_env | cut -d '=' -f 2-) && \
    if [ "$GO_VERIFY_IMAGE" != "${Glooe_verify_image}" ]; then echo "Go verify image '$GO_VERIFY_IMAGE' is invalid. Use '${Glooe_verify_image}'" && pwd && ls -al && exit 1; fi

# Build plugin
ENV CGO_ENABLED=1 GOARCH=amd64 GOOS=linux
RUN go build -buildmode=plugin \
             -gcflags="$(grep GC_FLAGS $GLOOE_DIR/build_env | cut -d '=' -f 2-)" \
             -o $PLUGIN_NAME plugin.go \
             || { echo "Used module:" | cat - go.mod; exit 1; }

FROM $GO_VERIFY_IMAGE as verify
ARG PLUGIN_PATH
ARG GLOOE_DIR=_glooe
ARG VERIFY_SCRIPT=$GLOOE_DIR/verify-plugins-linux-amd64
WORKDIR /go/src/$PLUGIN_PATH

COPY --from=build /go/src/$PLUGIN_PATH ./

# Run the script to verify that the plugin can be loaded by Gloo
RUN chmod +x $VERIFY_SCRIPT && \
    $VERIFY_SCRIPT -pluginDir ./ -manifest plugin_manifest.yaml

# This stage builds the final image containing just the plugin .so files. It can really be any linux/amd64 image.
FROM $RUN_IMAGE
ARG PLUGIN_PATH
ARG PLUGIN_BUILD_NAME

# Copy compiled plugin file from previous stage
RUN mkdir /compiled-auth-plugins
COPY --from=build /go/src/$PLUGIN_PATH/$PLUGIN_NAME /compiled-auth-plugins/
COPY --from=build /go/src/$PLUGIN_PATH/go.mod /compiled-auth-plugins/

# This is the command that will be executed when the container is run.
# It has to copy the compiled plugin file(s) to a directory.
CMD cp /compiled-auth-plugins/*.so /auth-plugins/