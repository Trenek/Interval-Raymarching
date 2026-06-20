import IScene;
import Intervals;
import Intervals3;
import Stack;

struct UniformBufferObject {
    float2 iResolution;
    float iTime;
};

[[vk::binding(0, 0)]] RWTexture2D<float4> outputTexture;
[[vk::binding(0, 1)]] ParameterBlock<UniformBufferObject> ubo;

namespace I {
    typedef Interval T;
    typedef Interval3 T3;

    #include "Scenes.slang"
}

#include "BeamCast.slang"

float4 Paint<S : IScene<Interval, Interval3>>(Optional<Interval3> P) {
    if (!P.hasValue) {
        return float4(0.0, 0.0, 0.0, 1.0);
    } else {
        Interval3 p = P.value;

        float3 normal = getNormal<S>(p).mid();
        float3 lightDirection = normalize(float3(-1.0, -1.0, -1.0));

        float a = 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
        
        return float4(float3(1.0, 0.0, 0.0) * a, 1.0);
    }
}

float4 draw<S : IScene<Interval, Interval3>>(uint2 threadID, uint maxDepth, float maxDistance, float3 cameraPos) {
    float aspect = ubo.iResolution.x / ubo.iResolution.y;
    float2 normCoord = (float2(threadID) / ubo.iResolution) * 2.0 - 1.0;
    normCoord.x *= aspect;

    Interval U0 = Interval(-1.0, 1.0) * aspect;
    Interval V0 = Interval(-1.0, 1.0);

    return Paint<S>(BeamCasterFloat<S>::Subdivide(U0, V0, 0.0, 0, 1.0, maxDepth, maxDistance, cameraPos, normCoord));
}

[shader("compute")]
[numthreads(16, 16, 1)] 
void computeMain(uint3 threadID : SV_DispatchThreadID) {
    outputTexture[threadID.xy] = draw<I::BarthDecic>(threadID.xy, 12, 10.0, float3(0.0, 0.0, 5.0));
}
