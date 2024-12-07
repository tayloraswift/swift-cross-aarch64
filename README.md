[![ci status](https://github.com/tayloraswift/swift-cross-aarch64/actions/workflows/Test.yml/badge.svg)](https://github.com/tayloraswift/swift-cross-aarch64/actions/workflows/Test.yml)
[![ci status](https://github.com/tayloraswift/swift-cross-aarch64/actions/workflows/Deploy.yml/badge.svg)](https://github.com/tayloraswift/swift-cross-aarch64/actions/workflows/Deploy.yml)


This repository contains a Docker image for Swift AArch64 cross-compilation, and a GitHub Actions task that builds and pushes it to [`tayloraswift/swift-cross-aarch64`](https://hub.docker.com/r/tayloraswift/swift-cross-aarch64/tags) on DockerHub.


## Why would anyone want to do this?

This Docker image is for cross-compiling Swift applications from an x86_64 Linux host to an AArch64 (ARM64) deployment target.

You would usually want to compile from an x86_64 host because you do not have an AArch64 builder available. One common use case is automatically building and deploying binaries from a GitHub Actions workflow, as GitHub Actions only offers x86_64 Linux runners for open-source repositories.

You would usually want to compile for an AArch64 target to save money. For example, AWS Graviton instances are significantly cheaper than their x86_64 counterparts, and you can use this image to build Swift applications for them.


## How do I cross-compile Swift applications?

If you really want to learn how Swift cross-compilation works, you can read a full walk-through [here](https://swiftinit.org/articles/cross-compiling-x86_64-linux-to-aarch64-linux).

But if you’re just trying to deploy an application, all you really need to do is copy and paste this JSON destination template.

> `aarch64-unknown-linux-gnu.static.json`
```json5
{
    "version": 1,
    "target": "aarch64-unknown-linux-gnu",
    "toolchain-bin-dir": "/home/ubuntu/x86_64/swift/usr/bin",
    "sdk": "/usr/aarch64-linux-gnu",
    "extra-cc-flags": [
        "-fPIC"

        // Add project-specific -Xcc flags here
    ],
    "extra-cpp-flags": [
        "-lstdc++",
        "-I", "/usr/aarch64-linux-gnu/include/c++/12",
        "-I", "/usr/aarch64-linux-gnu/include/c++/12/aarch64-linux-gnu/",

        // Add project-specific -Xcxx flags here
    ],
    "extra-swiftc-flags": [
        "-resource-dir", "/home/ubuntu/aarch64/swift/usr/lib/swift_static"

        // Add project-specific -Xswiftc flags here
    ]
}
```

This is JSON5, so you may need to remove the comments before passing it to SwiftPM.


## How do I deploy Swift applications?

Here’s a simple `docker run` command to build a SwiftPM project in the current directory for an AArch64 target, assuming you have the `aarch64-unknown-linux-gnu.json` file in the project root.

```bash
docker run -t --rm \
    -v $PWD:/swift-example \
    -w /swift-example \
    tayloraswift/swift-cross-aarch64:master \
    /home/ubuntu/x86_64/swift/usr/bin/swift build \
        -c release \
        --destination aarch64-unknown-linux-gnu.static.json \
        --static-swift-stdlib
```

If you use the `tayloraswift/swift-cross-aarch64:master` tag, you should also be using the `--static-swift-stdlib` flag to avoid runtime incompatibilities, because Swift is not ABI stable on Linux. This is optimal if you are deploying a single monolithic binary to each machine.

If you would rather not go this route, you need to ensure the correct Swift runtime is installed on the target machines at the path `/home/ubuntu/aarch64/swift/usr`. This is optimal if you are deploying multiple Swift applications per machine, but is a little more complicated to set up.


## What are my alternatives?

If your application and its dependencies support [Musl](https://musl.libc.org/), you could also use the [Static Linux SDK](https://www.swift.org/documentation/articles/static-linux-getting-started.html) to cross-compile portable binaries. However, many Swift packages depend on Glibc when building on Linux, so these Docker images allow you to use those libraries.


## Do I really need to use Docker?

No. You could also set up a cross-compilation environment directly on GitHub Actions by porting the commands in the [Dockerfile](Dockerfile) to a workflow step. But GitHub’s Linux runners already have Docker installed, and it doesn’t affect the generated binaries, so there’s not much of a point in avoiding Docker.
