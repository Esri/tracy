#!/usr/bin/env bash
set -ex

rm -rf build_capture*
rm -rf build_csvexport*
rm -rf build_profiler*
rm -rf install
rm -f tracy-*.zip

TRACY_VERSION=0.13.1

LLVM_ROOT="/usr/local/rtc/llvm/19.1.2"

COMMON_CMAKE_FLAGS=(
  -GNinja
  -DCMAKE_C_COMPILER="${LLVM_ROOT}/bin/clang"
  -DCMAKE_CXX_COMPILER="${LLVM_ROOT}/bin/clang++"
  -DCMAKE_CXX_FLAGS="-stdlib=libc++"
  -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++ -fuse-ld=lld -rtlib=compiler-rt -ldl -pthread"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX=install/${TRACY_VERSION}/${TARGETARCH}
  # Set legacy mode to use GLFW instead of wayland
  -DLEGACY=ON
  # Download, build, and statically link dependencies for portability
  -DDOWNLOAD_CAPSTONE=ON
  -DDOWNLOAD_GLFW=ON
  -DDOWNLOAD_FREETYPE=ON
  -DDOWNLOAD_LIBCURL=ON
  -DDOWNLOAD_PUGIXML=ON
  # Downloading and building GLFW will default to including wayland support,
  # so manually prefer x11 over wayland
  -DGLFW_BUILD_WAYLAND=OFF
  -DGLFW_BUILD_X11=ON
)

cmake -S ../capture -B build_capture_${TARGETARCH} \
  "${COMMON_CMAKE_FLAGS[@]}" 
cmake --build build_capture_${TARGETARCH} -t install

cmake -S ../csvexport -B build_csvexport_${TARGETARCH} \
  "${COMMON_CMAKE_FLAGS[@]}" 
cmake --build build_csvexport_${TARGETARCH} -t install

cmake -S ../profiler -B build_profiler_${TARGETARCH} \
  "${COMMON_CMAKE_FLAGS[@]}" 
cmake --build build_profiler_${TARGETARCH} -t install

cd install
zip -r ../tracy-${TRACY_VERSION}.zip ${TRACY_VERSION}
