import Intervals;
import Intervals3;
import IScene;
import Ray;
import Affine;
import Affine3;
import Divider;

struct UniformBufferObject {
    float2 iResolution;
    float iTime;
    float iTimeDelta;
};

[[vk::binding(0, 0)]]
ParameterBlock<UniformBufferObject> ubo;

namespace V {
    typedef float T;
    typedef float3 T3;

    #include "Scenes.slang"
}

namespace I {
    typedef Interval T;
    typedef Interval3 T3;

    #include "Scenes.slang"
}

namespace A {
    typedef Affine T;
    typedef Affine3 T3;

    #include "Scenes.slang"
}

float3 getColor<T : IScene<float, float3>>(float3 ro, float3 rd, float distance, float3 lightDirection) {
    float3 normal = getNormal<T>(ro + rd * float(distance));

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

float3 getColor<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float distance, float3 lightDirection, float epsilon, float maxDistance) {
    float3 normal = getNormal<T>(ro + rd * Interval(distance)).mid();

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

float3 getColor<T : IScene<Affine, Affine3>>(float3 ro, float3 rd, float distance, float3 lightDirection, float epsilon, float maxDistance) {
    float3 normal = getNormal<T>(ro + rd * Affine(distance)).mid();

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

bool tryToDraw<T : IScene<float, float3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = RayMarcher<T>::checkIntersection(ro, rd, epsilon, maxDistance))) {
        color = getColor<T>(ro, rd, distance.value, lightDir);
    }

    return none != distance;
}

bool tryToDraw<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = IntervalRayCasterNewton<T, StackDivider>::checkIntersection(ro, rd, epsilon, maxDistance))) {
        color = getColor<T>(ro, rd, distance.value, lightDir, epsilon, maxDistance);
    }

    return none != distance;
}

bool tryToDraw<T : IScene<Affine, Affine3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = AffineRayCaster<T, IntDivider>::checkIntersection(ro, rd, epsilon, maxDistance))) {
        color = getColor<T>(ro, rd, distance.value, lightDir, epsilon, maxDistance);
    }

    return none != distance;
}

struct FragmentInput {
    float2 fragCoord : TEXCOORD0; 
    float4 gl_FragCoord : SV_Position;
};

[shader("fragment")]
float4 fragMain(FragmentInput input) : SV_Target {
    const float2 uv = (input.gl_FragCoord.xy - 0.5 * ubo.iResolution.xy) / ubo.iResolution.y;
    const float3 lightDir = normalize(float3(1, 1.0, -0.5));

    const float3 ro = float3(0.0, 0.0, -6.0);
    const float3 rd = normalize(float3(uv, 1.0));

    float3 color = float3(0.1, 0.1, 0.1);

    if (tryToDraw<I::Mitchell>(ro, rd, lightDir, color, exp2(-12.0), 10)) {
        color *= float3(0x21.0 / 0xFF, 0x37.0 / 0xFF, 0x00.0 / 0xFF);
    }

    return float4(color, 1.0);
}
