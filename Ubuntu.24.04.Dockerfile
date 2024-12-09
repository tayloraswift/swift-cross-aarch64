FROM ubuntu:24.04
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

ARG SWIFT_VERSION
ARG UBUNTU_VERSION='ubuntu24.04'

WORKDIR /home/ubuntu

# Squash the following RUN commands into a single command to reduce image size
RUN <<EOF

apt update
apt -y install curl

# Note: The Docker CLI does not print the correct URL to the console, but the actual
# interpolated string passed to `curl` is correct.
curl "https://download.swift.org/\
swift-${SWIFT_VERSION}-release/\
${UBUNTU_VERSION//[.]/}/\
swift-${SWIFT_VERSION}-RELEASE/\
swift-${SWIFT_VERSION}-RELEASE-${UBUNTU_VERSION}.tar.gz" \
    -o toolchain.tar.gz

curl "https://download.swift.org/\
swift-${SWIFT_VERSION}-release/\
${UBUNTU_VERSION//[.]/}-aarch64/\
swift-${SWIFT_VERSION}-RELEASE/\
swift-${SWIFT_VERSION}-RELEASE-${UBUNTU_VERSION}-aarch64.tar.gz" \
    -o toolchain-aarch64.tar.gz

apt -y dist-upgrade

# Install dependencies of the Swift toolchain
apt update
apt -y install \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libncurses-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev

# Install dependencies needed for AArch64 cross-compilation. For some reason, `apt` cannot
# resolve the dependencies if we install them all at once.
apt -y install gcc-aarch64-linux-gnu
apt -y install libstdc++-13-dev-arm64-cross
apt -y install g++-multilib

# Unpack the Swift toolchain for x86_64
mkdir -p /home/ubuntu/x86_64/${SWIFT_VERSION}
cd /home/ubuntu/x86_64/${SWIFT_VERSION}

tar --strip-components=1 -xf /home/ubuntu/toolchain.tar.gz
rm /home/ubuntu/toolchain.tar.gz

# Unpack the Swift toolchain for AArch64
mkdir -p /home/ubuntu/aarch64/${SWIFT_VERSION}
cd /home/ubuntu/aarch64/${SWIFT_VERSION}

tar --strip-components=1 -xf /home/ubuntu/toolchain-aarch64.tar.gz
rm /home/ubuntu/toolchain-aarch64.tar.gz

EOF

WORKDIR /home/ubuntu

# See:
# https://forums.swift.org/t/swift-runtime-unable-to-suspend-thread-when-compiling-in-qemu/67676/3
RUN rm /home/ubuntu/aarch64/${SWIFT_VERSION}/usr/lib/swift/clang
RUN ln -s \
    /home/ubuntu/x86_64/${SWIFT_VERSION}/usr/lib/swift/clang \
    /home/ubuntu/aarch64/${SWIFT_VERSION}/usr/lib/swift/clang

# Create symbolic links to the Swift toolchains, to make it easier to reference them
RUN ln -s /home/ubuntu/aarch64/${SWIFT_VERSION} /home/ubuntu/aarch64/swift
RUN ln -s /home/ubuntu/x86_64/${SWIFT_VERSION} /home/ubuntu/x86_64/swift
