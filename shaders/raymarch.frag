#version 450

#extension GL_GOOGLE_include_directive : enable

#include "common.glsl"

layout(location = 0) in vec2 fragCoord;

layout(location = 0) out vec4 fragColor;

layout(set = 0, binding = 0) readonly uniform UniformBufferObject {
    vec2 iResolution;
    float iTime;
    float iTimeDelta;
} ubo;

float signedDstToCircle(vec3 p, vec3 center, float r) {
    return length(center - p) - r;
}

float maxVal(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float signedDstToBox(vec3 p, vec3 center, float side) {
    vec3 offset = abs(p - center) - side;

    float outsideDst = length(max(offset, 0));
    float insideDst = maxVal(min(offset, 0.0));

    return outsideDst;
}

float circle(vec3 p) {
    float circle = signedDstToCircle(p, vec3(sin(ubo.iTime) * 3, 0.0, 0.0), 0.5);

    return circle;
}
prepareScene(circle)

float box(vec3 p) {
    mat3 rot = rot3D(vec3(3.0, 2.0, 1.0), ubo.iTime);

    float box = signedDstToBox(rot * p, vec3(0.0), 0.5);

    return box;
}
prepareScene(box)

float scene(vec3 p) {
    return smin(circle(p), box(p), 1.0);
}
prepareScene(scene)

float mulVal(vec3 p) {
    return p.x * p.y * p.z;
}

float pathology(vec3 p) {
    float base = dot(p, p) - 0.8;
    float wave = 0.12 * mulVal(sin(25 * p));
    
    return base + wave;
}
prepareScene(pathology)

float pathology2(vec3 p) {
    float r_radial = length(p.xz);
    float torusProfile = r_radial - 0.55;
    float torusSDF = (torusProfile * torusProfile) + (p.y * p.y);
    float baseTorus = torusSDF - 0.04;
    
    float waveX = sin(p.x * 10.0);
    float waveZ = sin(p.z * 10.0);
    float waveY = sin(p.y * 6.0);
    float ornament = (waveX * waveY * waveZ) * 0.18;
    
    float combinedShape = baseTorus + ornament;
    float pathologyFactor = combinedShape * (combinedShape * combinedShape);
    
    return pathologyFactor * 1.8;
}
prepareScene(pathology2)

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * ubo.iResolution.xy) / ubo.iResolution.y;
    vec3 lightDirection = normalize(vec3(0.5, 1.0, -0.5));

    vec3 ro = { 0.0, 0.0, -3.0 };
    vec3 rd = normalize(vec3(uv, 1.0));

    vec3 color = vec3(0.1);

    bool ok = false;

    // if (ok == false) {
    //     float distance = getRayMarch(pathology, ro, rd);
    //     if (distance < 10000) {
    //         vec3 normal = getNormal(pathology, ro + rd * distance);
    //
    //         color = vec3(1.0, 0.0, 0.0) * getLightning(normal, lightDirection);
    //     }
    // }
    if (ok == false) {
        float distance = getRayMarch(circle, ro, rd);
        float distance2 = getRayMarch(box, ro, rd);

        if (distance < 10000) {
            vec3 normal = getNormal(circle, ro + rd * distance);

            color = vec3(1.0, 0.0, 0.0) * getLightning(normal, lightDirection);
            ok = true;
        }

        if (distance2 < distance && distance2 < 10000) {
            vec3 normal = getNormal(box, ro + rd * distance2);

            color = vec3(0.0, 1.0, 0.0) * getLightning(normal, lightDirection);
            ok = true;
        }
    }
    if (ok == false) {
        float distance = getRayMarch(scene, ro, rd);
        if (distance < 10000) {
            vec3 normal = getNormal(scene, ro + rd * distance);

            color = vec3(0.0, 0.0, 1.0) * getLightning(normal, lightDirection);
            ok = true;
        }
    }

    fragColor = vec4(color, 1.0);
}
