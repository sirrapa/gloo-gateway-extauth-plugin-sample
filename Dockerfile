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
ARG PLUGIN_FRAMEWORK_PATH
ARG PLUGIN_FRAMEWORK_VERSION
ARG PLUGIN_FRAMEWORK_URL
ARG STORAGE_HOSTNAME

# Fail if not all ARGs are set
RUN if [ ! $RUN_IMAGE ]; then echo "Required RUN_IMAGE build argument not set" && exit 1; fi
RUN if [ ! $GLOOE_VERSION ]; then echo "Required GLOOE_VERSION build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_BUILD_NAME ]; then echo "Required PLUGIN_BUILD_NAME build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_MODULE_PATH ]; then echo "Required PLUGIN_MODULE_PATH build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_FRAMEWORK_PATH ]; then echo "Required PLUGIN_FRAMEWORK_PATH build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_FRAMEWORK_VERSION ]; then echo "Required PLUGIN_FRAMEWORK_VERSION build argument not set" && exit 1; fi
RUN if [ ! $PLUGIN_FRAMEWORK_URL ]; then echo "Required PLUGIN_FRAMEWORK_URL build argument not set" && exit 1; fi
RUN if [ ! $STORAGE_HOSTNAME ]; then echo "Required STORAGE_HOSTNAME build argument not set" && exit 1; fi

RUN apk add --no-cache gcc musl-dev git make

ARG GLOOE_DIR=_glooe
ARG VERIFY_SCRIPT=$GLOOE_DIR/verify-plugins-linux-amd64
ENV GONOSUMDB=*
ENV CGO_ENABLED=1

WORKDIR /go/src/$PLUGIN_MODULE_PATH

# Downaload and extract plugin framework.
ADD ${PLUGIN_FRAMEWORK_URL}/archive/${PLUGIN_FRAMEWORK_VERSION}.tar.gz .
RUN mkdir -p /go/src/$PLUGIN_FRAMEWORK_PATH && \
    tar -zxvf ${PLUGIN_FRAMEWORK_VERSION}.tar.gz --strip 1 -C /go/src/$PLUGIN_FRAMEWORK_PATH && \
    rm -f ${PLUGIN_FRAMEWORK_VERSION}.tar.gz

# Copy the plugin implementation
COPY go.mod go.sum plugin* ./
COPY pkg/ ./pkg/

RUN make get-glooe-info -f /go/src/$PLUGIN_FRAMEWORK_PATH/Makefile

RUN go run /go/src/$PLUGIN_FRAMEWORK_PATH/scripts/resolve_deps/main.go go.mod $GLOOE_DIR/dependencies
RUN echo "// Generated for GlooE $GLOOE_VERSION" | cat - go.mod > go.new && mv go.new go.mod

# Run compile and verify the plugin can be loaded by Gloo
#RUN make build-plugin -f /go/src/$PLUGIN_FRAMEWORK_PATH/Makefile || { echo "Used module:" | cat - go.mod; exit 1; }
RUN CGO_ENABLED=1 GOARCH=amd64 GOOS=linux \
    go build -buildmode=plugin -gcflags='all=-N -l' -o plugins/$PLUGIN_BUILD_NAME plugin.go \
             || { echo "Used module:" | cat - go.mod; exit 1; }

# Run the script to verify that the plugin can be loaded by Gloo
RUN chmod +x $VERIFY_SCRIPT && \
    $VERIFY_SCRIPT -pluginDir plugins -manifest plugin_manifest.yaml

# This stage builds the final image containing just the plugin .so files. It can really be any linux/amd64 image.
FROM $RUN_IMAGE
ARG PLUGIN_MODULE_PATH

# Copy compiled plugin file from previous stage
RUN mkdir /compiled-auth-plugins
COPY --from=build /go/src/$PLUGIN_MODULE_PATH/plugins/*.so /compiled-auth-plugins/
COPY --from=build /go/src/$PLUGIN_MODULE_PATH/go.mod /compiled-auth-plugins/

# This is the command that will be executed when the container is run.
# It has to copy the compiled plugin file(s) to a directory.
CMD cp /compiled-auth-plugins/*.so /auth-plugins/