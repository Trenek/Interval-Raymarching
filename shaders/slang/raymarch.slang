import Intervals;
import Intervals3;
import IScene;
import Ray;

struct UniformBufferObject {
    float2 iResolution;
    float iTime;
    float iTimeDelta;
};

[[vk::binding(0, 0)]]
ParameterBlock<UniformBufferObject> ubo;

namespace V {
    #define T float
    #define T3 float3

    #include "Scenes.slang"

    #undef T
    #undef T3
}

namespace I {
    #define T Interval
    #define T3 Interval3

    #include "Scenes.slang"

    #undef T
    #undef T3
}

float3 getColor<T : IScene<float, float3>>(float3 ro, float3 rd, float distance, float3 lightDirection) {
    float3 normal = getNormal<T>(ro + rd * distance);

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

bool tryToDraw<T : IScene<float, float3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = rayMarchStep<T>(ro, rd, epsilon, maxDistance))) {
        color = getColor<T>(ro, rd, distance.value, lightDir);
    }

    return none != distance;
}

float3 getColor<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float distance, float3 lightDirection, float epsilon, float maxDistance) {
    float3 normal = getNormal<T>(ro + rd * Interval(distance)).mid();

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

bool tryToDraw<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = rayMarchInt<T>(ro, rd, epsilon, maxDistance))) {
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
    const float3 lightDir = normalize(float3(0.5, 1.0, -0.5));

    const float3 ro = float3(0.0, 0.0, -3.0);
    const float3 rd = normalize(float3(uv, 1.0));

    float3 color = float3(0.1);

    if (tryToDraw<I::BarthDecic>(ro, rd, lightDir, color, exp2(-12.0), 10)) {
        color *= float3(0.0, 1.0, 1.0);
    }

    return float4(color, 1.0);
}
