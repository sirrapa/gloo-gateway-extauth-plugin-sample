# Prepare the build environment.
# This stage is parametrized to replicate the same environment Gloo Enterprise was built in.
# All ARGs need to be set via the docker `--build-arg` flags.
ARG GO_BUILD_IMAGE
FROM $GO_BUILD_IMAGE AS build-env

RUN apt-get update -qq && apt-get install -yq bsdtar vim

# Download the specified version of the extauth plugin framework and
# compose plugin code by merging the implementation with the framework code
# This stage is parametrized to replicate the same environment Gloo Enterprise was built in.
# All ARGs need to be set via the docker `--build-arg` flags.
FROM build-env as plugin
ARG ENV_GLOOE_VERSION
ARG ENV_STORAGE_HOSTNAME
ARG PLUGIN_FRAMEWORK_VERSION
ARG PLUGIN_PATH

ENV GONOSUMDB=*
ENV GOPROXY=
ENV GO111MODULE=on
ENV CGO_ENABLED=0
# ENV GOFLAGS="-mod="
ENV PLUGIN_FRAMEWORK_PATH=github.com/solo-io/ext-auth-plugin-examples
ENV GLOOE_VERSION=$ENV_GLOOE_VERSION
ENV STORAGE_HOSTNAME=$ENV_STORAGE_HOSTNAME

WORKDIR $PLUGIN_PATH

# TODO replace this code block with an go dependency
ADD https://${GITHUB_PROXY}${PLUGIN_FRAMEWORK_PATH}/archive/master.zip ${PLUGIN_PATH}/${PLUGIN_FRAMEWORK_VERSION}.zip
RUN bsdtar --strip-components=1 -xvf ${PLUGIN_FRAMEWORK_VERSION}.zip
COPY plugin_framework/Makefile.framework Makefile
COPY plugin_framework/scripts scripts

COPY go.mod .
RUN make get-glooe-info
#RUN rm -f plugin.mod *.zip


FROM plugin
ARG PLUGIN_PATH
COPY pkg plugins/required_header/pkg

VOLUME $PLUGIN_PATH
