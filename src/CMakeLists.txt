# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(aubio_flutter_library VERSION 0.0.1 LANGUAGES C)

add_library(aubio STATIC
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/aubio.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/types.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/fvec.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/fvec.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/cvec.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/cvec.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/lvec.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/lvec.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/mathutils.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/mathutils.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/vecutils.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/vecutils.h

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/filter.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/filter.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/biquad.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/biquad.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/resampler.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/resampler.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/a_weighting.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/a_weighting.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/c_weighting.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/temporal/c_weighting.h

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/fft.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/fft.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/phasevoc.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/phasevoc.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/specdesc.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/specdesc.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/awhitening.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/awhitening.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/spectral/ooura_fft8g.c

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitch.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitch.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchyin.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchyin.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchyinfast.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchyinfast.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchyinfft.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchyinfft.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchschmitt.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchschmitt.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchmcomb.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchfcomb.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/pitch/pitchspecacf.c

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/onset/onset.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/onset/onset.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/onset/peakpicker.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/onset/peakpicker.h

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/tempo/tempo.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/tempo/tempo.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/tempo/beattracking.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/tempo/beattracking.h

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/utils/parameter.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/utils/parameter.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/utils/log.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/utils/log.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/utils/scale.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/utils/scale.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/musicutils.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/musicutils.h

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/effects/pitchshift.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/effects/pitchshift_dummy.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/effects/timestretch.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/effects/timestretch_dummy.c

        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/source.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/source.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/sink.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/sink.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/sink_sndfile.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/sink_sndfile.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/source_sndfile.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/source_sndfile.h
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/ioutils.c
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c/io/ioutils.h
)

target_include_directories(aubio PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c
)

target_compile_definitions(aubio PRIVATE
        HAVE_AUBIO_DOUBLE=0
        HAVE_STDLIB_H=1
        HAVE_STDIO_H=1
        AUBIO_UNSTABLE=1
)

add_library(aubio_flutter SHARED
  "aubio_flutter.c"
)

set_target_properties(aubio_flutter PROPERTIES
  PUBLIC_HEADER aubio_flutter.h
  OUTPUT_NAME "aubio_flutter"
)

target_link_libraries(aubio_flutter PRIVATE aubio)

target_include_directories(aubio_flutter PRIVATE "aubio-c")

target_compile_definitions(aubio_flutter PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(aubio_flutter PRIVATE "-Wl,-z,max-page-size=16384")
endif()
