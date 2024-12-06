# Cross compilation requires libstdc++-12-dev-arm64-cross, which is only available in
# Ubuntu 22.04 or newer.
FROM ubuntu:jammy
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

ARG SWIFT_VERSION='6.0.2'
ARG UBUNTU_VERSION='ubuntu22.04'

WORKDIR /home/ubuntu

RUN apt update
RUN apt -y install curl

# Note: The Docker CLI does not print the correct URL to the console, but the actual
# interpolated string passed to `curl` is correct.
RUN curl "https://download.swift.org/\
swift-${SWIFT_VERSION}-release/\
${UBUNTU_VERSION//[.]/}/\
swift-${SWIFT_VERSION}-RELEASE/\
swift-${SWIFT_VERSION}-RELEASE-${UBUNTU_VERSION}.tar.gz" \
    -o toolchain.tar.gz

RUN curl "https://download.swift.org/\
swift-${SWIFT_VERSION}-release/\
${UBUNTU_VERSION//[.]/}-aarch64/\
swift-${SWIFT_VERSION}-RELEASE/\
swift-${SWIFT_VERSION}-RELEASE-${UBUNTU_VERSION}-aarch64.tar.gz" \
    -o toolchain-aarch64.tar.gz

RUN apt -y dist-upgrade

# Install dependencies of the Swift toolchain
RUN apt update
RUN apt -y install \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-9-dev \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev

# Install dependencies needed for AArch64 cross-compilation
RUN apt -y install \
    gcc-aarch64-linux-gnu \
    g++-multilib \
    libstdc++-12-dev-arm64-cross

# Unpack the Swift toolchain for x86_64
WORKDIR /home/ubuntu/x86_64/${SWIFT_VERSION}

RUN tar --strip-components=1 -xf /home/ubuntu/toolchain.tar.gz
RUN rm /home/ubuntu/toolchain.tar.gz

# Unpack the Swift toolchain for AArch64
WORKDIR /home/ubuntu/aarch64/${SWIFT_VERSION}

RUN tar --strip-components=1 -xf /home/ubuntu/toolchain-aarch64.tar.gz
RUN rm /home/ubuntu/toolchain-aarch64.tar.gz


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
