## ---------------------------------------------------------------------
##
## Copyright (C) 2012 - 2023 by the deal.II authors
##
## This file is part of the deal.II library.
##
## The deal.II library is free software; you can use it, redistribute
## it, and/or modify it under the terms of the GNU Lesser General
## Public License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
## The full text of the license can be found in the file LICENSE.md at
## the top level directory of deal.II.
##
## ---------------------------------------------------------------------

#
# General setup for GCC and compilers sufficiently close to GCC
#
# Please read the fat note in setup_compiler_flags.cmake prior to
# editing this file.
#

if( CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND
    CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9.0" )
  message(FATAL_ERROR "\n"
    "deal.II requires support for features of C++17 that are not present in\n"
    "versions of GCC prior to 9.0."
    )
endif()

if( CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND
    CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9.0" )
  message(FATAL_ERROR "\n"
    "deal.II requires support for features of C++17 that are not present in\n"
    "versions of Clang prior to 10.0."
    )
endif()

# Correspondence between AppleClang version and upstream Clang version:
# https://en.wikipedia.org/wiki/Xcode#Xcode_7.0_-_11.x_(since_Free_On-Device_Development)
if (POLICY CMP0025)
  if( CMAKE_CXX_COMPILER_ID MATCHES "AppleClang" AND
      CMAKE_CXX_COMPILER_VERSION VERSION_LESS "12.0" )
    message(FATAL_ERROR "\n"
      "deal.II requires support for features of C++17 that are not present in\n"
      "versions of AppleClang prior to 12.0."
      )
  endif()
endif()


########################
#                      #
#    General setup:    #
#                      #
########################

#
# Set -pedantic if the compiler supports it.
#
enable_if_supported(DEAL_II_WARNING_FLAGS "-pedantic")

#
# Setup various warnings:
#
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wall")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wextra")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wmissing-braces")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Woverloaded-virtual")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wpointer-arith")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wsign-compare")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wsuggest-override")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wswitch")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wsynth")
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wwrite-strings")

#
# Disable Wplacement-new that will trigger a lot of warnings
# in the BOOST function classes that we include via the
# BOOST signals classes:
#
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-placement-new")

#
# Disable deprecation warnings
#
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-deprecated-declarations")

#
# Disable warning generated by Debian version of openmpi
#
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-literal-suffix")

#
# Disable warning about ABI changes
#
enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-psabi")

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "IntelLLVM")
  # Enable warnings for conversion from real types to integer types.
  # The warning is too noisy in gcc and therefore only enabled for clang.
  enable_if_supported(DEAL_II_WARNING_FLAGS "-Wfloat-conversion")

  #
  # Silence Clang warnings about unused compiler parameters (works around a
  # regression in the clang driver frontend of certain versions):
  #
  enable_if_supported(DEAL_II_WARNING_FLAGS "-Qunused-arguments")

  #
  # Clang verbosely warns about not supporting all our friend declarations
  # (and consequently removing access control altogether)
  #
  enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-unsupported-friend")

  #
  # Clang versions prior to 3.6 emit a lot of false positives wrt
  # "-Wunused-function". Also suppress warnings for Xcode older than 6.3
  # (which is equivalent to clang < 3.6).
  # Policy CMP0025 allows to differentiate between Clang and AppleClang
  # which admits a more fine-grained control. Otherwise, we are left
  # with just disabling this feature for all versions between 4.0 and 6.3.
  #
  if (POLICY CMP0025)
    if( (CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
         AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.6")
        OR (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
         AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "6.3"))
      enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-unused-function")
    endif()
  elseif(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.6" OR
      ( NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.0" AND
        CMAKE_CXX_COMPILER_VERSION VERSION_LESS "6.3") )
    enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-unused-function")
  endif()

  #
  # Clang-14.0.5 complaines loudly about not being able to vectorize some
  # of our loops that we have annotated with DEAL_II_OPENMP_SIMD:
  #
  #     warning: loop not vectorized: the optimizer was unable to perform
  #     the requested transformation; the transformation might be disabled
  #     or specified as part of an unsupported transformation ordering
  #     [-Wpass-failed=transform-warning]
  #
  # Let us simply disable the warning for now.
  #
  enable_if_supported(DEAL_II_WARNING_FLAGS "-Wno-pass-failed")
endif()


#############################
#                           #
#    For Release target:    #
#                           #
#############################

if (CMAKE_BUILD_TYPE MATCHES "Release")
  #
  # General optimization flags:
  #
  add_flags(DEAL_II_CXX_FLAGS_RELEASE "-O2")

  enable_if_supported(DEAL_II_CXX_FLAGS_RELEASE "-funroll-loops")
  enable_if_supported(DEAL_II_CXX_FLAGS_RELEASE "-funroll-all-loops")
  enable_if_supported(DEAL_II_CXX_FLAGS_RELEASE "-fstrict-aliasing")

  #
  # Disable assert() in deal.II and user projects in release mode
  #
  list(APPEND DEAL_II_DEFINITIONS_RELEASE "NDEBUG")

  #
  # There are many places in the library where we create a new typedef and then
  # immediately use it in an Assert. Hence, only ignore unused typedefs in Release
  # mode.
  #
  enable_if_supported(DEAL_II_CXX_FLAGS_RELEASE "-Wno-unused-local-typedefs")

  #
  # We are using __builtin_assume in Assert in Release mode and the compiler is
  # warning about ignored side effects which we don't care about.
  #
  enable_if_supported(DEAL_II_CXX_FLAGS_RELEASE "-Wno-assume")
endif()


###########################
#                         #
#    For Debug target:    #
#                         #
###########################

if (CMAKE_BUILD_TYPE MATCHES "Debug")

  list(APPEND DEAL_II_DEFINITIONS_DEBUG "DEBUG")

  #
  # We have to ensure that we emit floating-point instructions in debug
  # mode that preserve the occurrence of floating-point exceptions and don't
  # introduce new ones. gcc plays nicely in this regard by enabling
  # `-ftrapping-math` per default, at least for the level of optimization
  # we have in debug mode. clang however is more aggressive and assumes
  # that it can optimize code disregarding precise floating-point exception
  # semantics.
  #
  # We thus set `-ffp-exceptions-behavior=strict` in debug mode to ensure
  # that our testsuite doesn't run into false positive floating-point
  # exceptions. See
  #
  # https://github.com/dealii/dealii/issues/15496
  #
  enable_if_supported(DEAL_II_CXX_FLAGS_DEBUG "-ffp-exception-behavior=strict")

  #
  # In recent versions, gcc often eliminates too much debug information
  # using '-Og' to be useful.
  #
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    enable_if_supported(DEAL_II_CXX_FLAGS_DEBUG "-Og")
  endif()
  #
  # If -Og is not available, fall back to -O0:
  #
  if(NOT DEAL_II_HAVE_FLAG_Og)
    add_flags(DEAL_II_CXX_FLAGS_DEBUG "-O0")
  endif()

  enable_if_supported(DEAL_II_CXX_FLAGS_DEBUG "-ggdb")
  enable_if_supported(DEAL_II_LINKER_FLAGS_DEBUG "-ggdb")
  #
  # If -ggdb is not available, fall back to -g:
  #
  if(NOT DEAL_II_HAVE_FLAG_ggdb)
    enable_if_supported(DEAL_II_CXX_FLAGS_DEBUG "-g")
    enable_if_supported(DEAL_II_LINKER_FLAGS_DEBUG "-g")
  endif()

  if(DEAL_II_SETUP_COVERAGE)
    #
    # Enable test coverage
    #
    enable_if_supported(DEAL_II_CXX_FLAGS_DEBUG "-fno-elide-constructors")
    add_flags(DEAL_II_CXX_FLAGS_DEBUG "-ftest-coverage -fprofile-arcs")
    add_flags(DEAL_II_LINKER_FLAGS_DEBUG "-ftest-coverage -fprofile-arcs")
  endif()

endif()
