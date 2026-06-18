#version 450

layout(location = 0) in vec2 fragCoord;

layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 0) uniform sampler2D image[]; 

void main() {
    vec2 actualCoord = fragCoord;
    actualCoord[1] = 1 - fragCoord[1];

    vec3 color = texture(image[0], actualCoord).rgb;

    outColor = vec4(color, 1.0);
}
