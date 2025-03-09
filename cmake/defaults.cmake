#
# Copyright (c) 2022 Winsider Seminars & Solutions, Inc.  All rights reserved.
#
# This file is part of System Informer.
#

if(NOT MSVC)
    message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
endif()

#
# Clean some flags that will conflict with our defaults. This is discouraged
# but unavoidable for some generators.
#
if(CMAKE_GENERATOR STREQUAL "Ninja")
    string(REPLACE "/Ob0" "" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
    string(REPLACE "/Ob0" "" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
    string(REPLACE "/Ob0" "" CMAKE_C_FLAGS_DEBUG_INIT "${CMAKE_C_FLAGS_DEBUG_INIT}")
    string(REPLACE "/Ob0" "" CMAKE_CXX_FLAGS_DEBUG_INIT "${CMAKE_CXX_FLAGS_DEBUG_INIT}")
endif()

#
# Detect and set the platform for simplicity elsewhere.
#
if(CMAKE_VS_PLATFORM_NAME)
    set(SI_PLATFORM "${CMAKE_VS_PLATFORM_NAME}")
elseif(CMAKE_GENERATOR_PLATFORM)
    if(CMAKE_GENERATOR_PLATFORM MATCHES "x64|AMD64")
        set(SI_PLATFORM "x64")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
        set(SI_PLATFORM "ARM64")
    elseif(CMAKE_GENERATOR_PLATFORM MATCHES "i[3-6]86|x86")
        set(SI_PLATFORM "Win32")
    else()
        message(FATAL_ERROR "Unsupported platform: ${CMAKE_GENERATOR_PLATFORM}")
    endif()
else()
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x64|AMD64")
        set(SI_PLATFORM "x64")
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
        set(SI_PLATFORM "ARM64")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i[3-6]86|x86")
        set(SI_PLATFORM "Win32")
    else()
        message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_PROCESSOR}")
    endif()
endif()
if(SI_PLATFORM STREQUAL "x64")
    set(SI_PLATFORM_SHORT "64")
elseif(SI_PLATFORM STREQUAL "ARM64")
    set(SI_PLATFORM_SHORT "ARM64")
elseif(SI_PLATFORM STREQUAL "Win32")
    set(SI_PLATFORM_SHORT "32")
else()
    message(FATAL_ERROR "Unexpected platform: ${SI_PLATFORM}")
endif()

#
# Compiler flags
#

set(SI_COMPILE_FLAGS_COMMON
    /MP               # Multi-processor compilation
    /FC               # Show full path to source file in compiler output
    /WX               # Treat warnings as errors
    /Oi               # Enable intrinsic functions
    /Ot               # Favor speed
    /Ob2              # Enable inline function expansion
    /GF               # Enable string pooling
    /Gm-              # Disable minimal rebuild
    /GS               # Buffer security check
    /Gy               # Enable function-level linking
    /Zc:wchar_t       # wchar_t is native type
    /Zc:forScope      # Force conformance in for loop scope
    /Zc:inline        # Remove unreferenced functions
    /Zc:rvalueCast    # Enforce type conversion rules
    /Zc:preprocessor  # New preprocessor conformance
    /permissive-      # Standards conformance
    /external:W3      # Warning level for external headers
    /utf-8            # Set source and execution charsets to UTF-8
    /DEBUG            # Generate debug info

    #
    # Debug
    #

    $<$<CONFIG:Debug>:/Od>      # Disable optimizations

    #
    # Release
    #

    $<$<CONFIG:Release>:/O2>      # Maximum optimizations
)

set(SI_COMPILE_FLAGS_USER
    ${SI_COMPILE_FLAGS_COMMON}
    /W3               # Warning level 3
    /Gz               # __stdcall calling convention
    /fp:precise       # Precise floating point
    /EHsc             # Exception handling model
    /sdl              # Additional security checks
    /d1nodatetime     # Disable date/time in debug info

    $<$<STREQUAL:${SI_PLATFORM},ARM64>:/guard:signret> # Signed return guard

    #
    # Debug
    #

    $<$<CONFIG:Debug>:/RTC1>    # Run-time error checks

    #
    # Release
    #

    $<$<CONFIG:Release>:/d1trimfile:${SI_ROOT}>            # Trim debug path prefixes
    $<$<CONFIG:Release>:/Qspectre>                         # Enable spectre mitigations
    $<$<CONFIG:Release>:/guard:cf>                         # Control flow guard
    $<$<CONFIG:Release>:
        $<$<STREQUAL:${SI_PLATFORM},x64>:/guard:xfg>       # Extended flow guard
    >
    $<$<CONFIG:Release>:
        $<$<STREQUAL:${SI_PLATFORM},x64>:/guard:ehcont>    # EH continuation guard
    >
    $<$<CONFIG:Release>:
        $<$<NOT:$<STREQUAL:${SI_PLATFORM},ARM64>>:/QIntel-jcc-erratum> # Intel erratum 1279
    >
)

set(SI_COMPILE_FLAGS_KERNEL
    ${SI_COMPILE_FLAGS_COMMON}
    /W4      # Warning level 4
    /kernel  # Kernel mode compilation
)

#
# Linker flags
#

set(SI_LINK_FLAGS_COMMON
    /DEBUG                   # Generate debug info
    /DYNAMICBASE             # Enable ASLR
    /NXCOMPAT                # Enable DEP
    /DEPENDENTLOADFLAG:0x800 # LOAD_LIBRARY_SEARCH_SYSTEM32
    /FILEALIGN:0x1000        # Align sections to 4K
    /BREPRO                  # Reproducible builds

    #
    # Release
    #
    $<$<CONFIG:Release>:/RELEASE>                        # Release build
)

set(SI_LINK_FLAGS_USER
    ${SI_LINK_FLAGS_COMMON}
    /MANIFEST:NO          # Disable manifest generation
    /INCREMENTAL          # Incremental linking
    /LARGEADDRESSAWARE    # Handles addresses larger than 2GB

    #
    # Release
    #
    $<$<CONFIG:Release>:/OPT:REF>                        # Eliminate unreferenced
    $<$<CONFIG:Release>:/OPT:ICF>                        # COMDAT folding
    $<$<CONFIG:Release>:/LTCG:incremental>               # Link-time code generation
    $<$<CONFIG:Release>:/guard:cf>                       # Control flow guard
    $<$<CONFIG:Release>:
        $<$<STREQUAL:${SI_PLATFORM},x64>:/guard:xfg>     # Extended flow guard
    >
    $<$<CONFIG:Release>:
        $<$<STREQUAL:${SI_PLATFORM},x64>:/guard:ehcont>  # EH continuation guard
    >
    $<$<CONFIG:Release>:
        $<$<NOT:$<STREQUAL:${SI_PLATFORM},ARM64>>:/CETCOMPAT> # CET compatibility
    >
)

set(SI_LINK_FLAGS_KERNEL
    ${SI_LINK_FLAGS_COMMON}
)

#
# Compiler definitions
#

set(SI_COMPILE_DEFS_COMMON
)

set(SI_COMPILE_DEFS_USER
    ${SI_COMPILE_DEFS_COMMON}
)

set(SI_COMPILE_DEFS_KERNEL
    ${SI_COMPILE_DEFS_COMMON}
)
