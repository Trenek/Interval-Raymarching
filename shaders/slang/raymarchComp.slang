import Intervals;
import Intervals3;
import IScene;
import Ray;
import Divider;

struct UniformBufferObject {
    float2 iResolution;
    float iTime;
    float iTimeDelta;
};

[[vk::binding(0, 0)]]
RWTexture2D<float4> outputTexture;

[[vk::binding(0, 1)]]
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

    if (none != (distance = RayMarcher<T>::checkIntersection(ro, rd, epsilon, maxDistance))) {
        color = getColor<T>(ro, rd, distance.value, lightDir);
    }

    return none != distance;
}

float3 getColor<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float distance, float3 lightDirection, float epsilon, float maxDistance) {
    float3 normal = getNormal<T>(ro + rd * Interval(distance)).mid();

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

float3 getColor2<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float distance, float3 lightDirection, float epsilon, float maxDistance) {
    float3 normal = getNormal<T>(ro + rd * Interval(distance)).mid();
    float diffuse = clamp(dot(normal, lightDirection), 0.0, 1.0);

    float3 hitPoint = ro + rd * distance;
    float3 shadowOrigin = hitPoint + lightDirection;
    
    Optional<float> shadowDistance = IntervalRayCaster<T, IntDivider>::checkIntersection(shadowOrigin, lightDirection, epsilon, maxDistance);
    
    float shadowFactor = 1.0;
    
    if (none != shadowDistance) {
        shadowFactor = 0.0;
    }

    return 0.15 + diffuse * shadowFactor;
}

bool tryToDraw<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = IntervalRayCaster<T, IntDivider>::checkIntersection(ro, rd, epsilon, maxDistance))) {
        color = getColor<T>(ro, rd, distance.value, lightDir, epsilon, maxDistance);
    }

    return none != distance;
}

[shader("compute")]
[numthreads(32, 1, 1)] 
void computeMain(uint3 threadID : SV_DispatchThreadID) {
    const float2 fragCoord = float2(threadID.xy);
    const float2 uv = (fragCoord - 0.5 * ubo.iResolution.xy) / ubo.iResolution.y;
    const float3 lightDir = normalize(float3(1, 1.0, -0.5));

    const float3 ro = float3(0.0, 0.0, -10.0);
    const float3 rd = normalize(float3(uv, 1.0));

    float3 color = float3(0.1, 0.1, 0.1);

    if (tryToDraw<I::Sphere>(ro, rd, lightDir, color, exp2(-12.0), 100)) {
        color *= float3(0x21.0 / 0xFF, 0x37.0 / 0xFF, 0x00.0 / 0xFF);
    }

    outputTexture[threadID.xy] = float4(color, 1.0);
}
