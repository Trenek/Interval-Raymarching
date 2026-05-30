file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/shaders)

set(ALL_SPV_OUTPUTS "")

set(SHADER_SRC "${CMAKE_CURRENT_SOURCE_DIR}")
set(SHADER_DST "${CMAKE_BINARY_DIR}/shaders")

macro(compile_shader SRC_FILE DST_FILE)
    add_custom_command(
        OUTPUT "${SHADER_DST}/${DST_FILE}"
        COMMAND glslc "${SHADER_SRC}/${SRC_FILE}" -o "${SHADER_DST}/${DST_FILE}"
        DEPENDS "${SHADER_SRC}/${SRC_FILE}"
    )

    list(APPEND ALL_SPV_OUTPUTS "${SHADER_DST}/${DST_FILE}")
endmacro()

compile_shader("screen.vert" "screen.spv")
compile_shader("raymarch.frag" "raymarch.spv")

add_custom_target(shaders DEPENDS ${ALL_SPV_OUTPUTS})
