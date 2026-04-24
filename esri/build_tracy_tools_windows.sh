#!/usr/bin/env bash
set -ex

rm -rf build_capture
rm -rf build_csvexport
rm -rf build_profiler
rm -rf install
rm -f tracy-*.zip

TRACY_VERSION=0.13.1
PATH="/c/rtc/cmake/4.2.1/bin:${PATH}"

COMMON_CMAKE_FLAGS=(
  -G "Visual Studio 17 2022" \
  -T "version=14.44.35207" \
  -A x64 \
  -DCMAKE_SYSTEM_VERSION=10.0.19041.0 \
  -DCMAKE_INSTALL_PREFIX=install/${TRACY_VERSION}/x64 \
  # Download, build, and statically link dependencies for portability
  -DDOWNLOAD_CAPSTONE=ON \
  -DDOWNLOAD_GLFW=ON \
  -DDOWNLOAD_FREETYPE=ON \
  -DDOWNLOAD_LIBCURL=ON \
  -DDOWNLOAD_PUGIXML=ON
)

COMMON_BUILD_FLAGS=(
  --config Release
  --target install
)

cmake -S ../capture -B build_capture \
  "${COMMON_CMAKE_FLAGS[@]}"
cmake --build build_capture "${COMMON_BUILD_FLAGS[@]}"

cmake -S ../csvexport -B build_csvexport \
  "${COMMON_CMAKE_FLAGS[@]}"
cmake --build build_csvexport "${COMMON_BUILD_FLAGS[@]}"

cmake -S ../profiler -B build_profiler \
  "${COMMON_CMAKE_FLAGS[@]}"
cmake --build build_profiler "${COMMON_BUILD_FLAGS[@]}"

cd install

powershell.exe Compress-Archive ${TRACY_VERSION} ../tracy-${TRACY_VERSION}.zip
