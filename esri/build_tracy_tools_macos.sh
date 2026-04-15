#!/usr/bin/env bash
set -ex

rm -rf build_capture
rm -rf build_csvexport
rm -rf build_profiler
rm -rf install
rm -f tracy-*.zip

TRACY_VERSION=0.13.1

PATH="/usr/local/rtc/cmake/4.2.1/bin:/usr/local/rtc/ninja/1.12.1/bin:$PATH"

COMMON_CMAKE_FLAGS=(
  -GNinja
  -DCMAKE_OSX_ARCHITECTURES="arm64" \
  -DCMAKE_SYSTEM_PROCESSOR="arm64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="14.0" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=install/${TRACY_VERSION}/arm64 \
  # Download, build, and statically link dependencies for portability
  -DDOWNLOAD_CAPSTONE=ON \
  -DDOWNLOAD_GLFW=ON \
  -DDOWNLOAD_FREETYPE=ON \
  -DDOWNLOAD_LIBCURL=ON \
  -DDOWNLOAD_PUGIXML=ON
)

cmake -S ../capture -B build_capture \
  "${COMMON_CMAKE_FLAGS[@]}" 
cmake --build build_capture -t install

cmake -S ../csvexport -B build_csvexport \
  "${COMMON_CMAKE_FLAGS[@]}" 
cmake --build build_csvexport -t install

cmake -S ../profiler -B build_profiler \
  "${COMMON_CMAKE_FLAGS[@]}" 
cmake --build build_profiler -t install

cd install
zip -r ../tracy-${TRACY_VERSION}.zip ${TRACY_VERSION}