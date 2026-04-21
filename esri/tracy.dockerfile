# Container that has all the tools needed to build the tracy tools
FROM ubuntu:22.04

# This stops krb5-user package from prompting for geographic region
ENV DEBIAN_FRONTEND="noninteractive"

# Set a cache for CPM packages so they are reused for all 3 builds (capture, csvexport, and profiler)
ENV CPM_SOURCE_CACHE=/tracy/esri/.cache/cpm
ENV llvm_version="19.1.2"
ENV PATH="/usr/local/rtc/llvm/${llvm_version}/bin:${PATH}"

ARG TARGETARCH
ARG CMAKE_VERSION=4.2.1

# install dependencies
RUN \
  apt update \
  && \
  apt install -y \
  build-essential \
  ca-certificates \
  curl \
  git \
  libdbus-1-dev \
  libglfw3-dev \
  libgl1-mesa-dev \
  libssl-dev \
  libx11-dev \
  libxcursor-dev \
  libxi-dev \
  libxinerama-dev \
  libxrandr-dev \
  libxxf86vm-dev \
  ninja-build \
  pkg-config \
  unzip \
  zip \
  zlib1g-dev \
  && \
  rm -rf /var/lib/apt/lists/* /tmp/* \
  && \
  echo "Done"

# Install the RTC prebuilt LLVM toolchain.
RUN \
  mkdir -p /usr/local/rtc/llvm \
  && \
  curl --insecure "https://runtime-zip.esri.com/userContent/apps-archive/archive/local_system_setup/runtimecore/linux/llvm-${llvm_version}-$(uname -m).zip" --output /tmp/llvm.zip \
  && \
  unzip /tmp/llvm.zip -d /usr/local/rtc/llvm \
  && \
  rm /tmp/llvm.zip \
  && \
  echo "Done installing linux compiler"

# Install a newer version of cmake, as Tracy requires 4.x
RUN \
  case "${TARGETARCH}" in \
    arm64) cmake_arch="aarch64" ;; \
    amd64) cmake_arch="x86_64" ;; \
    *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && \
  curl -L "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${cmake_arch}.tar.gz" -o /tmp/cmake.tar.gz \
  && \
  mkdir -p /opt/cmake \
  && \
  tar -xzf /tmp/cmake.tar.gz -C /opt/cmake --strip-components=1 \
  && \
  ln -sf /opt/cmake/bin/cmake /usr/local/bin/cmake \
  && \
  rm -f /tmp/cmake.tar.gz

# use docker build variables to set the target architecture so all build commands can use it by using the build
# time TARGETARCH variable and manipulating it to get the right uname
ENV TARGETARCH="${TARGETARCH/amd/x86_}"
ENV TARGETARCH="${TARGETARCH/arm/aarch}"