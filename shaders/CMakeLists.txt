file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/shaders)

set(ALL_SPV_OUTPUTS "")

set(SHADER_SRC "${CMAKE_CURRENT_SOURCE_DIR}")
set(SHADER_SRC_2 "${CMAKE_CURRENT_SOURCE_DIR}/slang")
set(SHADER_DST "${CMAKE_BINARY_DIR}/shaders")

macro(compile_shader SRC_FILE DST_FILE)
    add_custom_command(
        OUTPUT "${SHADER_DST}/${DST_FILE}"
        COMMAND glslc "${SHADER_SRC}/${SRC_FILE}" -o "${SHADER_DST}/${DST_FILE}"
        DEPENDS "${SHADER_SRC}/${SRC_FILE}"
    )

    list(APPEND ALL_SPV_OUTPUTS "${SHADER_DST}/${DST_FILE}")
endmacro()

macro(compile_shader2 SRC_FILE DST_FILE)
    add_custom_command(
        OUTPUT "${SHADER_DST}/${DST_FILE}"
        COMMAND slangc "${SHADER_SRC_2}/${SRC_FILE}" -I "${SHADER_SRC_2}/" -o "${SHADER_DST}/${DST_FILE}"
        DEPENDS "${SHADER_SRC_2}/${SRC_FILE}" 
                "${SHADER_SRC_2}/IScene.slang"
                "${SHADER_SRC_2}/Intervals.slang"
                "${SHADER_SRC_2}/Intervals3.slang"
                "${SHADER_SRC_2}/Affine.slang"
                "${SHADER_SRC_2}/Affine3.slang"
                "${SHADER_SRC_2}/Ray.slang"
                "${SHADER_SRC_2}/Scenes.slang"
                "${SHADER_SRC_2}/Stack.slang"
                "${SHADER_SRC_2}/BeamCast.slang"
    )

    list(APPEND ALL_SPV_OUTPUTS "${SHADER_DST}/${DST_FILE}")
endmacro()

compile_shader("screen.vert" "screenV.spv")
compile_shader("screen.frag" "screenF.spv")
compile_shader2("raymarchComp.slang" "slangRaymarch.spv")
compile_shader2("beamcastComp.slang" "slangBeamcast.spv")
compile_shader2("raymarchFrag.slang" "slangRaymarchF.spv")

add_custom_target(shaders DEPENDS ${ALL_SPV_OUTPUTS})
