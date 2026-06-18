cmake_minimum_required(VERSION 3.10)

project(ImplicitSurface VERSION 1.0 LANGUAGES C)

add_subdirectory(dependencies)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED TRUE)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CMAKE_COMMAND} -E time")

add_subdirectory(source)
add_subdirectory(shaders)

add_executable(ImplicitSurface
    ${SOURCE_FILES} 
    ${ICON}
    "${CMAKE_SOURCE_DIR}/source/main.c"
)

target_link_libraries(ImplicitSurface tREngine)
target_include_directories(ImplicitSurface PRIVATE 
    ${SOURCE_DIRECTORIES}
)
set(COMPILE_OPTIONS
    -W
    -Wall
    -Wextra
    -Wpedantic
    -Wshadow
    -Wunused
    -Wno-logical-op-parentheses
    -Wno-parentheses
    -Werror
    -Wno-comment
    -pedantic
    -pedantic-errors
    -D_GLIBCXX_DEBUG
    -D_GLIBCXX_DEBUG_PEDANTIC
    -D_UCRT
)

if (CMAKE_BUILD_TYPE STREQUAL "Release")
    set(COMPILE_OPTIONS 
        ${COMPILE_OPTIONS}
        -O3
    )
    if (WIN32)
        target_link_options(ImplicitSurface PRIVATE -mwindows)
    endif()
else()
    set(COMPILE_OPTIONS 
        ${COMPILE_OPTIONS}
        -g
    )
endif()

target_compile_options(ImplicitSurface PUBLIC ${COMPILE_OPTIONS})
add_dependencies(ImplicitSurface
    shaders
)
