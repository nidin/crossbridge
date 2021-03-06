# - Includes a public function for assisting users in trying to determine the
# Visual Studio service pack in use.
#
# Sets the passed in variable to one of the following values or an empty
# string if unknown.
#    vc80
#    vc80sp1
#    vc90
#    vc90sp1
#    vc100
#    vc100sp1
#
# Usage:
# ===========================
#
#    if(MSVC)
#       include(CMakeDetermineVSServicePack)
#       DetermineVSServicePack( my_service_pack )
#
#       if( my_service_pack )
#           message(STATUS "Detected: ${my_service_pack}")
#       endif()
#    endif()
#
# ===========================

#=============================================================================
# Copyright 2009-2011 Kitware, Inc.
# Copyright 2009-2010 Philip Lowman <philip@yhbt.com>
# Copyright 2010-2011 Aaron C. meadows <cmake@shadowguarddev.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# [INTERNAL]
# Please do not call this function directly
function(_DetermineVSServicePackFromCompiler _OUT_VAR _cl_version)
   if    (${_cl_version} VERSION_EQUAL "14.00.50727.42")
       set(_version "vc80")
   elseif(${_cl_version} VERSION_EQUAL "14.00.50727.762")
       set(_version "vc80sp1")
   elseif(${_cl_version} VERSION_EQUAL "15.00.21022.08")
       set(_version "vc90")
   elseif(${_cl_version} VERSION_EQUAL "15.00.30729.01")
       set(_version "vc90sp1")
   elseif(${_cl_version} VERSION_EQUAL "16.00.30319.01")
       set(_version "vc100")
   elseif(${_cl_version} VERSION_EQUAL "16.00.40219.01")
       set(_version "vc100sp1")
   else()
       set(_version "")
   endif()
   set(${_OUT_VAR} ${_version} PARENT_SCOPE)
endfunction()


############################################################
# [INTERNAL]
# Please do not call this function directly
function(_DetermineVSServicePack_FastCheckVersionWithCompiler _SUCCESS_VAR  _VERSION_VAR)
    if(EXISTS ${CMAKE_CXX_COMPILER})
      execute_process(
          COMMAND ${CMAKE_CXX_COMPILER} /?
          ERROR_VARIABLE _output
          OUTPUT_QUIET
        )

      string(REGEX MATCH "Compiler Version [0-9]+.[0-9]+.[0-9]+.[0-9]+"
        _cl_version "${_output}")

      if(_cl_version)
        string(REGEX MATCHALL "[0-9]+"
            _cl_version_list "${_cl_version}")
        list(GET _cl_version_list 0 _major)
        list(GET _cl_version_list 1 _minor)
        list(GET _cl_version_list 2 _patch)
        list(GET _cl_version_list 3 _tweak)

        if("${_major}${_minor}" STREQUAL "${MSVC_VERSION}")
          set(_cl_version ${_major}.${_minor}.${_patch}.${_tweak})
        else()
          unset(_cl_version)
        endif()
      endif()

      if(_cl_version)
          set(${_SUCCESS_VAR} true PARENT_SCOPE)
          set(${_VERSION_VAR} ${_cl_version} PARENT_SCOPE)
      endif()
    endif()
endfunction()

############################################################
# [INTERNAL]
# Please do not call this function directly
function(_DetermineVSServicePack_CheckVersionWithTryCompile _SUCCESS_VAR  _VERSION_VAR)
    file(WRITE "${CMAKE_BINARY_DIR}/return0.cc"
      "int main() { return 0; }\n")

    try_compile(
      _CompileResult
      "${CMAKE_BINARY_DIR}"
      "${CMAKE_BINARY_DIR}/return0.cc"
      OUTPUT_VARIABLE _output
      COPY_FILE "${CMAKE_BINARY_DIR}/return0.cc")

    file(REMOVE "${CMAKE_BINARY_DIR}/return0.cc")

    string(REGEX MATCH "Compiler Version [0-9]+.[0-9]+.[0-9]+.[0-9]+"
      _cl_version "${_output}")

    if(_cl_version)
      string(REGEX MATCHALL "[0-9]+"
          _cl_version_list "${_cl_version}")

      list(GET _cl_version_list 0 _major)
      list(GET _cl_version_list 1 _minor)
      list(GET _cl_version_list 2 _patch)
      list(GET _cl_version_list 3 _tweak)

      set(${_SUCCESS_VAR} true PARENT_SCOPE)
      set(${_VERSION_VAR} ${_major}.${_minor}.${_patch}.${_tweak} PARENT_SCOPE)
    endif()
endfunction()

############################################################
# [INTERNAL]
# Please do not call this function directly
function(_DetermineVSServicePack_CheckVersionWithTryRun _SUCCESS_VAR  _VERSION_VAR)
    file(WRITE "${CMAKE_BINARY_DIR}/return0.cc"
        "#include <stdio.h>\n\nconst unsigned int CompilerVersion=_MSC_FULL_VER;\n\nint main(int argc, char* argv[])\n{\n  int M( CompilerVersion/10000000);\n  int m((CompilerVersion%10000000)/100000);\n  int b(CompilerVersion%100000);\n\n  printf(\"%d.%02d.%05d.01\",M,m,b);\n return 0;\n}\n")

    try_run(
        _RunResult
        _CompileResult
        "${CMAKE_BINARY_DIR}"
        "${CMAKE_BINARY_DIR}/return0.cc"
        RUN_OUTPUT_VARIABLE  _runoutput
        )

    file(REMOVE "${CMAKE_BINARY_DIR}/return0.cc")

    string(REGEX MATCH "[0-9]+.[0-9]+.[0-9]+.[0-9]+"
        _cl_version "${_runoutput}")

    if(_cl_version)
      set(${_SUCCESS_VAR} true PARENT_SCOPE)
      set(${_VERSION_VAR} ${_cl_version} PARENT_SCOPE)
    endif()
endfunction()


#
# A function to call to determine the Visual Studio service pack
# in use.  See documentation above.
function(DetermineVSServicePack _pack)
    if(NOT DETERMINED_VS_SERVICE_PACK OR NOT ${_pack})

        _DetermineVSServicePack_FastCheckVersionWithCompiler(DETERMINED_VS_SERVICE_PACK _cl_version)
        if(NOT DETERMINED_VS_SERVICE_PACK)
            _DetermineVSServicePack_CheckVersionWithTryCompile(DETERMINED_VS_SERVICE_PACK _cl_version)
            if(NOT DETERMINED_VS_SERVICE_PACK)
                _DetermineVSServicePack_CheckVersionWithTryRun(DETERMINED_VS_SERVICE_PACK _cl_version)
            endif()
        endif()

        if(DETERMINED_VS_SERVICE_PACK)

            if(_cl_version)
                # Call helper function to determine VS version
                _DetermineVSServicePackFromCompiler(_sp "${_cl_version}")
                if(_sp)
                    set(${_pack} ${_sp} CACHE INTERNAL
                        "The Visual Studio Release with Service Pack")
                endif()
            endif()
        endif()
    endif()
endfunction()

