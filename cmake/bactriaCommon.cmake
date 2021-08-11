# Copyright 2021 Jan Stephan
#
# Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the “Licence”).
# You may not use this work except in compliance with the Licence.
# You may obtain a copy of the Licence at:
#
#     http://ec.europa.eu/idabc/eupl.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the Licence is distributed on an “AS IS” basis, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  Licence permissions and limitations under the Licence.


if(NOT TARGET bactria)
    add_library(bactria INTERFACE)

    # Don't warn on bactria's headers, e.g. because of unknown attributes
    target_include_directories(bactria SYSTEM INTERFACE ${_BACTRIA_INCLUDE_DIRECTORY})
    
    target_compile_features(bactria INTERFACE cxx_std_14)
    target_link_libraries(bactria INTERFACE $<$<NOT:$<PLATFORM_ID:Windows>>:${CMAKE_DL_LIBS}>)

    add_library(bactria::bactria ALIAS bactria)
endif()
