# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(aubio_flutter_library VERSION 0.0.1 LANGUAGES C)

add_library(aubio STATIC
        aubio-c/aubio.h
        aubio-c/types.h
        aubio-c/fvec.c
        aubio-c/fvec.h
        aubio-c/cvec.c
        aubio-c/cvec.h
        aubio-c/lvec.c
        aubio-c/lvec.h
        aubio-c/mathutils.c
        aubio-c/mathutils.h
        aubio-c/vecutils.c
        aubio-c/vecutils.h

        aubio-c/filter.c
        aubio-c/filter.h
        aubio-c/biquad.c
        aubio-c/biquad.h
        aubio-c/temporal/resampler.c
        aubio-c/temporal/resampler.h
        aubio-c/temporal/a_weighting.c
        aubio-c/temporal/a_weighting.h
        aubio-c/temporal/c_weighting.c
        aubio-c/temporal/c_weighting.h

        aubio-c/fft/fft.c
        aubio-c/fft/fft.h
        aubio-c/spectral/phasevoc.c
        aubio-c/spectral/phasevoc.h
        aubio-c/spectral/specdesc.c
        aubio-c/spectral/specdesc.h
        aubio-c/spectral/awhitening.c
        aubio-c/spectral/awhitening.h
        aubio-c/ooura_fft8g.c

        aubio-c/pitch/pitch.c
        aubio-c/pitch/pitch.h
        aubio-c/pitch/pitchyin.c
        aubio-c/pitch/pitchyin.h
        aubio-c/pitch/pitchyinfast.c
        aubio-c/pitch/pitchyinfast.h
        aubio-c/pitch/pitchyinfft.c
        aubio-c/pitch/pitchyinfft.h
        aubio-c/pitch/pitchschmitt.c
        aubio-c/pitch/pitchschmitt.h

        aubio-c/onset/onset.c
        aubio-c/onset/onset.h
        aubio-c/onset/peakpicker.c
        aubio-c/onset/peakpicker.h

        aubio-c/tempo/tempo.c
        aubio-c/tempo/tempo.h
        aubio-c/tempo/beattracking.c
        aubio-c/tempo/beattracking.h

        aubio-c/utils/parameter.c
        aubio-c/utils/parameter.h
        aubio-c/utils/log.c
        aubio-c/utils/log.h
        aubio-c/utils/scale.c
        aubio-c/utils/scale.h
        aubio-c/musicutils.c
        aubio-c/musicutils.h

        aubio-c/effects/pitchshift.h
        aubio-c/effects/pitchshift_dummy.c
        aubio-c/effects/timestretch.h
        aubio-c/effects/timestretch_dummy.c

        aubio-c/io/source.c
        aubio-c/io/source.h
        aubio-c/io/sink.c
        aubio-c/io/sink.h
        aubio-c/io/sink_sndfile.c
        aubio-c/io/sink_sndfile.h
        aubio-c/io/source_sndfile.c
        aubio-c/io/source_sndfile.h
        aubio-c/io/ioutils.c
        aubio-c/io/ioutils.h
)

target_include_directories(aubio PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/aubio-c)
target_compile_definitions(aubio PRIVATE HAVE_AUBIO_DOUBLE=0)

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
