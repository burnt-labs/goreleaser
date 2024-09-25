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

WORKDIR /opt

# Build osxcross
# See https://github.com/tpoechtrager/osxcross/blob/master/build.sh#L31-L49 for SDK overview.
RUN git clone https://github.com/tpoechtrager/osxcross \
  && cd osxcross \
  # Don't change file name when downloading because osxcross auto-detects the version from the name
  && wget -nc https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz \
  && mv MacOSX11.3.sdk.tar.xz tarballs/ \
  && UNATTENDED=yes OSX_VERSION_MIN=10.15 ./build.sh \
  # Cleanups before Docker layer is finalized
  && rm -r tarballs/ \
  && chmod +rx /opt/osxcross \
  && chmod +rx /opt/osxcross/target \
  && chmod -R +rx /opt/osxcross/target/bin 

# RUN ls -l /opt/osxcross/target/bin
RUN /opt/osxcross/target/bin/x86_64-apple-darwin20.4-clang --version \
    && /opt/osxcross/target/bin/aarch64-apple-darwin20.4-clang --version

