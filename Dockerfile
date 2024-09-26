ARG GORELEASER_VERSION=v1.22.7

FROM goreleaser/goreleaser-cross:${GORELEASER_VERSION} AS builder

# Install build dependencies
RUN  apt-get update \
  && apt-get install --no-install-recommends -y -q \
    zlib1g-dev \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    libxml2-dev \
    libssl-dev 

ENV OSX_CROSS_PATH=/usr/local/osxcross

# Build osxcross
# See https://github.com/tpoechtrager/osxcross/blob/master/build.sh#L31-L49 for SDK overview.
RUN git clone https://github.com/tpoechtrager/osxcross \
  && cd $(basename ${OSX_CROSS_PATH}) \
  # Don't change file name when downloading because osxcross auto-detects the version from the name
  && wget -nc https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz \
  && mv MacOSX11.3.sdk.tar.xz tarballs/ \
  && UNATTENDED=yes OSX_VERSION_MIN=10.15 ./build.sh \
  # Cleanups before Docker layer is finalized
  && rm -r tarballs/ \
  && chmod +rx ${OSX_CROSS_PATH} \
  && chmod +rx ${OSX_CROSS_PATH}/target \
  && chmod -R +rx ${OSX_CROSS_PATH}/target/bin 

# RUN ls -l ${OSX_CROSS_PATH}/target/bin
RUN ${OSX_CROSS_PATH}/target/bin/x86_64-apple-darwin20.4-clang --version \
    && ${OSX_CROSS_PATH}/target/bin/aarch64-apple-darwin20.4-clang --version

FROM scratch AS release
COPY --from=builder / /

ENV OSX_CROSS_PATH=/usr/local/osxcross
ENV PATH=$PATH:${OSX_CROSS_PATH}/bin:/usr/local/go/bin

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
