# Updating Tracy and Building Desktop Tools

- [Updating Tracy and Building Desktop Tools](#updating-tracy-and-building-desktop-tools)
  - [Scope](#scope)
  - [Updating the Tracy Source](#updating-the-tracy-source)
    - [1. Fetch the latest upstream tags](#1-fetch-the-latest-upstream-tags)
    - [2. Create an update branch from `runtimecore`](#2-create-an-update-branch-from-runtimecore)
    - [3. Merge the upstream release tag](#3-merge-the-upstream-release-tag)
    - [4. Update the Tracy version in scripts](#4-update-the-tracy-version-in-scripts)
    - [5. Keep runtime and tools on the same version](#5-keep-runtime-and-tools-on-the-same-version)
  - [Build Overview](#build-overview)
    - [Optional dependency caching](#optional-dependency-caching)
  - [Building for macOS](#building-for-macos)
    - [macOS requirements](#macos-requirements)
    - [macOS build command](#macos-build-command)
    - [macOS expected result](#macos-expected-result)
  - [Building for Linux](#building-for-linux)
    - [Linux requirements](#linux-requirements)
    - [Linux build flow](#linux-build-flow)
      - [Linux `arm64`](#linux-arm64)
      - [Linux `x64`](#linux-x64)
    - [Linux expected result](#linux-expected-result)
  - [Building for Windows](#building-for-windows)
    - [Windows requirements](#windows-requirements)
    - [Windows build command](#windows-build-command)
    - [Windows expected result](#windows-expected-result)
  - [Staging the Binaries](#staging-the-binaries)
  - [Suggested Release Checklist](#suggested-release-checklist)

This document describes how to update the vendored Tracy source to a newer upstream release and how to build the Tracy
desktop tools for distribution on macOS, Linux, and Windows.

The process has four parts:

1. Merge the desired upstream Tracy release into the local Tracy integration.
2. Update any local scripts that record the Tracy version.
3. Build the three Tracy tools for each supported desktop target.
4. Stage the finished binaries so DevOps can package and distribute them through Conan.

## Scope

This flow covers the following Tracy tools:

1. `capture`
2. `csvexport`
3. `profiler`

The intended desktop outputs are:

1. macOS `arm64`
2. Linux `arm64`
3. Linux `x64`
4. Windows `x64`

At minimum, you need:

1. A 64-bit Windows machine for the Windows build
2. An Apple Silicon Mac for the macOS build
3. Docker Desktop for the Linux builds (installed on the Apple Silicon Mac)

## Updating the Tracy Source

### 1. Fetch the latest upstream tags

Make sure the Tracy repository has an upstream remote that points to the original Tracy project, then fetch tags from
upstream.

```bash
git fetch upstream --tags
git tag --list
```

Identify the Tracy release tag you want to import.

### 2. Create an update branch from `runtimecore`

Start from the branch that carries the current Tracy integration and create a dedicated update branch.

```bash
git checkout runtimecore
git pull
git checkout -b tracy-update-<release-tag>
```

### 3. Merge the upstream release tag

Merge the selected upstream release tag into the branch.

```bash
git merge <release-tag>
```

In the normal case, this should merge cleanly because the local integration only carries a small amount of divergence
from vanilla Tracy.

If the merge does not apply cleanly, handle it in this order:

1. Identify the local change that sits on top of upstream Tracy.
2. Revert or temporarily back it out if it blocks the merge.
3. Complete the merge to the new Tracy release.
4. Reapply the local change on top of the updated Tracy code.

### 4. Update the Tracy version in scripts

After the source update is merged, update any local scripts that record or package the Tracy version so they match the
new upstream release tag. These are found in the `esri` folder.

This is important because the build scripts and produced artifacts should report the same Tracy version that was just
merged.

### 5. Keep runtime and tools on the same version

Tracy works best when the instrumented client and the Tracy server tools stay aligned on the same version. After
upgrading Tracy in the source tree, rebuild and redistribute the matching desktop tools as part of the same update.

## Build Overview

Tracy uses CMake and downloads a number of third-party build dependencies automatically during configuration. Some
dependencies also rely on system libraries.

Build outputs for each platform should include:

1. An `install` directory containing the tool executables
2. A zip archive containing the distributable binaries

### Optional dependency caching

Builds are faster if `CPM_SOURCE_CACHE` is set. Tracy shares downloaded packages across tool builds, so a cache avoids
repeatedly fetching the same dependencies.

Example:

```bash
export CPM_SOURCE_CACHE="$HOME/.cache/cpm"
```

For Linux, this cache is handled automatically in the Docker-based flow.

## Building for macOS

macOS builds should target `arm64` only.

Universal binaries are not recommended here because there are known linking issues, and Intel macOS machines are no
longer the primary target. If an Intel macOS build is ever required, it can be produced locally by adjusting the script
to target `x86_64` instead.

### macOS requirements

Install the build dependencies required by the repo's dependency bootstrap script. This is generally handled through
`install_dependencies.sh`, so you likely already have them.

1. CMake `4.2.1`
2. LLVM `19.1.2`

### macOS build command

From the Tracy integration directory, run:

```bash
cd esri
./build_tracy_tools_macos.sh
```

### macOS expected result

The script should build all three tools and place the results into:

1. An `install` directory
2. A zip archive containing the macOS binaries

## Building for Linux

Linux desktop binaries are built in Docker, with one container per target architecture.

### Linux requirements

Install Docker Desktop and make sure Docker can build and run Linux containers.

### Linux build flow

The Docker image is built from `esri/tracy.dockerfile`, and the repository is mounted into the container so the build
artifacts are written back to the host checkout.

Start within the tracy root directory.

#### Linux `arm64`

```bash
docker build --platform=linux/arm64 --tag=tracy-arm64 - < esri/tracy.dockerfile
docker run --rm -it -u $(id -u):$(id -g) --volume ${PWD}:/tracy --workdir /tracy/esri tracy-arm64 ./build_tracy_tools_linux.sh
```

After the build finishes, save the generated `arm64` binaries and zip from the mounted workspace.

#### Linux `x64`

```bash
docker build --platform=linux/amd64 --tag=tracy-amd64 - < esri/tracy.dockerfile
docker run --rm -it -u $(id -u):$(id -g) --volume ${PWD}:/tracy --workdir /tracy/esri tracy-amd64 ./build_tracy_tools_linux.sh
```

After the build finishes, save the generated `amd64` binaries and zip from the mounted workspace.

### Linux expected result

Each Linux architecture build should produce:

1. An `install` directory with the three tool executables
2. A zip archive for that architecture

## Building for Windows

Windows builds target `x64`.

Windows on Arm users can generally run the `x64` binaries through Prism, so a separate Windows Arm build is not required
for this distribution flow.

### Windows requirements

Install the versions of CMake and MSVC required by the repo's installation flow. This is generally handled through
`install_dependencies.sh`, so you likely already have them.

### Windows build command

Run:

```bash
cd esri
./build_tracy_tools_windows.sh
```

### Windows expected result

The script should build the three Windows Tracy tools and place the results into:

1. An `install` directory
2. A zip archive containing the Windows binaries

## Staging the Binaries

Once all platform builds are complete, collect the finished artifacts for:

1. macOS `arm64`
2. Linux `arm64`
3. Linux `x64`
4. Windows `x64`

Stage those binaries on apps-data or shortbread, depending on the current release process, so DevOps can bundle and
publish them through Conan.

## Suggested Release Checklist

1. Fetch upstream Tracy tags.
2. Create a branch from `runtimecore`.
3. Merge the chosen upstream release tag.
4. Reapply any local patch if the merge required backing it out.
5. Update the Tracy version in local scripts.
6. Build macOS `arm64` with `./build_tracy_tools_macos.sh`.
7. Build Linux `arm64` and `x64` with Docker and `./build_tracy_tools_linux.sh`.
8. Build Windows `x64` with `./build_tracy_tools_windows.sh`.
9. Verify each build produced an `install` directory and zip archive.
10. Stage the finished artifacts for DevOps distribution.
