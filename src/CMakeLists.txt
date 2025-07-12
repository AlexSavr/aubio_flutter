# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(aubio_flutter_library VERSION 0.0.1 LANGUAGES C)

file(GLOB AUBIO_SOURCES "aubio-c/*.c")

add_library(aubio_flutter SHARED
  "aubio_flutter.c"
)

set_target_properties(aubio_flutter PROPERTIES
  PUBLIC_HEADER aubio_flutter.h
  OUTPUT_NAME "aubio_flutter"
)

target_include_directories(aubio_flutter PRIVATE "aubio-c")

target_compile_definitions(aubio_flutter PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(aubio_flutter PRIVATE "-Wl,-z,max-page-size=16384")
endif()
