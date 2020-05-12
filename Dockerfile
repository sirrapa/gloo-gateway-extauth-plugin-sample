# Prepare the build environment.
# Use this stage to add certificates and setting proxies
# All ARGs need to be set via the docker `--build-arg` flags.
ARG FRAMEWORK_BUILD_IMAGE
ARG RUN_IMAGE
FROM $FRAMEWORK_BUILD_IMAGE AS framework
ARG PLUGIN_FRAMEWORK_PATH
ARG GLOOE_VERSION
ARG PLUGIN_PATH

ENV GONOSUMDB=*
ENV GO111MODULE=on
ENV CGO_ENABLED=1

WORKDIR /go/src/$PLUGIN_PATH

# Copy framework files to workdir
RUN cp -Rfp /go/src/$PLUGIN_FRAMEWORK_PATH/. /go/src/$PLUGIN_PATH/

# Fail if Makefile does not exist
# This means that the framework files copy failed
RUN if [ ! -f "Makefile" ]; then echo "Framework Makefile not found in workdir:" && pwd && ls -al && exit 1; fi

# Copy plugin's mod file
COPY go.mod go.sum ./
# Copy the plugin implementation
COPY pkg plugins/required_header/pkg

# Calling the make rules from the framework's Makefile...
# Resolve dependencies and ensure dependency version usage and build plugin
RUN make get-glooe-info resolve-deps
RUN echo "// Generated for GlooE $GLOOE_VERSION" | cat - go.mod > go.new && mv go.new go.mod
RUN make build-plugins || { echo "Used module:" | cat - go.mod; exit 1; }

# This stage builds the final image containing just the plugin .so files. It can really be any linux/amd64 image.
FROM $RUN_IMAGE
ARG PLUGIN_PATH

# Copy compiled plugin file from previous stage
RUN mkdir /compiled-auth-plugins
COPY --from=framework /go/src/$PLUGIN_PATH/plugins/RequiredHeader.so /compiled-auth-plugins/
COPY --from=framework /go/src/$PLUGIN_PATH/go.mod /compiled-auth-plugins/

# This is the command that will be executed when the container is run.
# It has to copy the compiled plugin file(s) to a directory.
CMD cp /compiled-auth-plugins/*.so /auth-plugins/