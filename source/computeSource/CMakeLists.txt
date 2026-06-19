set(SOURCE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")

list(TRANSFORM SOURCE_DIRECTORIES APPEND "/*.c" OUTPUT_VARIABLE SOURCE_FILES)
file(GLOB SOURCE_FILES ${SOURCE_FILES})

set(SOURCE_FILES ${SOURCE_FILES} PARENT_SCOPE)
set(SOURCE_DIRECTORIES ${SOURCE_DIRECTORIES} PARENT_SCOPE)

add_executable(ImplicitSurfaceComp
    ${SOURCE_FILES} 
    ${ICON}
    "${CMAKE_CURRENT_SOURCE_DIR}/main.c"
)

target_link_libraries(ImplicitSurfaceComp tREngine)
target_include_directories(ImplicitSurfaceComp PRIVATE 
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
        target_link_options(ImplicitSurfaceComp PRIVATE -mwindows)
    endif()
else()
    set(COMPILE_OPTIONS 
        ${COMPILE_OPTIONS}
        -g
    )
endif()

target_compile_options(ImplicitSurfaceComp PUBLIC ${COMPILE_OPTIONS})
add_dependencies(ImplicitSurfaceComp
    shaders
)
