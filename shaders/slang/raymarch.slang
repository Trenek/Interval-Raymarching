import Intervals;
import Intervals3;
import Stack;

struct UniformBufferObject {
    float2 iResolution;
    float iTime;
    float iTimeDelta;
};

[[vk::binding(0, 0)]]
ParameterBlock<UniformBufferObject> ubo;

interface IScene<R : IDifferentiable, T3 : IDifferentiable> {
    [Differentiable]
    static R evaluate(T3 p);
}

float3 gradient<T : IScene<float, float3>>(float3 p) {
    DifferentialPair<float3> dp = diffPair(p, float3(0.0));

    bwd_diff(T::evaluate)(dp, 1.0);

    return dp.d;
}

// #define FORWARD_DIFF

#ifdef FORWARD_DIFF
Interval3 gradient<T : IScene<Interval, Interval3>>(Interval3 p) {
    Interval3 grad;

    DifferentialPair<Interval3> dp_x = diffPair(p, Interval3(float3(1.0, 0.0, 0.0)));
    DifferentialPair<Interval3> dp_y = diffPair(p, Interval3(float3(0.0, 1.0, 0.0)));
    DifferentialPair<Interval3> dp_z = diffPair(p, Interval3(float3(0.0, 0.0, 1.0)));

    grad.x = fwd_diff(T::evaluate)(dp_x).d;
    grad.y = fwd_diff(T::evaluate)(dp_y).d;
    grad.z = fwd_diff(T::evaluate)(dp_z).d;

    return grad;
}
#else
Interval3 gradient<T : IScene<Interval, Interval3>>(Interval3 p) {
    Interval eps = Interval(1e-5);
    Interval3 grad;

    Interval3 p_x_plus  = Interval3(p.x + eps, p.y, p.z);
    Interval3 p_x_minus = Interval3(p.x - eps, p.y, p.z);

    Interval3 p_y_plus  = Interval3(p.x, p.y + eps, p.z);
    Interval3 p_y_minus = Interval3(p.x, p.y - eps, p.z);

    Interval3 p_z_plus  = Interval3(p.x, p.y, p.z + eps);
    Interval3 p_z_minus = Interval3(p.x, p.y, p.z - eps);

    grad.x = (T::evaluate(p_x_plus) - T::evaluate(p_x_minus)) / (eps * 2.0);
    grad.y = (T::evaluate(p_y_plus) - T::evaluate(p_y_minus)) / (eps * 2.0);
    grad.z = (T::evaluate(p_z_plus) - T::evaluate(p_z_minus)) / (eps * 2.0);

    return grad;
}
#endif

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

bool between(float a, float minVal, float maxVal) {
    return a >= minVal && a <= maxVal;
}

Optional<float> rayMarch<T : IScene<float, float3>>(float3 ro, float3 rd) {
    const float maxDistance = 10000.0;
    Optional<float> result = none;
    float t = 0.0;
    float distanceTraveled = 1.0;
    
    for (int i = 0; between(distanceTraveled, 0.001, maxDistance) && i < 80; i += 1) {
        t += distanceTraveled = T::evaluate(ro + rd * t);
    }

    if (distanceTraveled < maxDistance) {
        result = t;
    }
    
    return result;
}

Optional<float> rayMarchStep<T : IScene<float, float3>>(float3 ro, float3 rd) {
    const float maxDistance = 10000.0;
    Optional<float> result = none;
    float t = 0.0;
    float prevVal = 1.0;
    float val = 1.0;
    float step = 0.1;
    
    for (int i = 0; val * prevVal > 0 && i < 20000; i += 1) {
        t += step;

        prevVal = val;
        val = T::evaluate(ro + rd * t);
    }

    if (prevVal * val <= 0) {
        result = t;
    }
    
    return result;
}

Optional<float> rayMarch<T : IScene<Interval, Interval3>>(float3 ro, float3 rd) {
    Optional<float> result = none;

    const float maxDistance = 10000.0;
    const float epsilon = 0.001;

    Interval t = Interval(0.0, maxDistance);
    Interval f;

    Stack<Interval, 64> stack;
    stack.push(t);

    while (false == stack.isEmpty() && false == stack.isFull()) {
        t = stack.pop();
        f = T::evaluate(ro + rd * t);

        if (f.contains(0.0)) {
            if (t.maxVal - t.minVal < epsilon) {
                return t.maxVal;
            }
            float mid = t.mid();

            stack.push(Interval(mid, t.maxVal));
            stack.push(Interval(t.minVal, mid));
        }
    }

    if (f.contains(0.0)) {
        result = t.minVal;
    }

    return result;
}

Optional<float> Newton<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, Interval t0, Interval f, Interval dF, float epsilon) {
    while (t0.length() > epsilon) {
        float mid = t0.mid();

        // if (abs(dF.minVal) < 0.0001f || abs(dF.maxVal) < 0.0001f) {
        //     return none;
        // }

        Interval fMid = T::evaluate(ro + rd * Interval(mid));
        Interval t1 = mid - (fMid / dF);

        if (t0.contains(t1)) {
            t0 = t1;
        }
        else if (t1.intersects(t0)) {
            t0 = t1.intersection(t0);
        }
        else {
            return none;
        }

        f = T::evaluate(ro + rd * t0);
        dF = dot(gradient<T>(ro + rd * t0), rd);

        if (dF.contains(0.0)) {
            return none; 
        }
    }

    if (f.contains(0.0)) {
        return Optional<float>(t0.minVal);
    }

    return none;
}

Optional<float> rayMarchNewton<T : IScene<Interval, Interval3>>(float3 ro, float3 rd) {
    Optional<float> result = none;
    const float maxDistance = 100.0;
    const float epsilon = 0.001;

    Interval t0 = Interval(0.0, maxDistance);
    Interval f;

    Stack<Interval, 64> stack;
    stack.push(t0);

    while (false == stack.isEmpty()) {
        t0 = stack.pop();
        f = T::evaluate(ro + rd * t0);

        if (f.contains(0.0)) {
            Interval dF = dot(gradient<T>(ro + rd * t0), rd);

            Optional<float> n = Newton<T>(ro, rd, t0, f, dF, epsilon);

            if (n != none) {
                return n;
            }
            else {
                float mid = t0.mid();

                stack.push(Interval(mid, t0.maxVal));
                stack.push(Interval(t0.minVal, mid));
            }
        }
    }

    return result;
}

float3 getNormal<T : IScene<float, float3>>(float3 p) {
    return normalize(gradient<T>(p));
}

Interval3 getNormal<T : IScene<Interval, Interval3>>(Interval3 p) {
    return normalize(gradient<T>(p));
}

float3 getColor<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float distance, float3 lightDirection) {
    Interval3 normal = getNormal<T>(ro + rd * Interval(distance));

    return 0.15 + clamp(dot(normal.mid(), lightDirection), 0.0, 1.0);
}

float3 getColor<T : IScene<float, float3>>(float3 ro, float3 rd, float distance, float3 lightDirection) {
    float3 normal = getNormal<T>(ro + rd * distance);

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

bool tryToDraw<T : IScene<float, float3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color) {
    Optional<float> distance = none;

    if (none != (distance = rayMarch<T>(ro, rd))) {
        color = getColor<T>(ro, rd, distance.value, lightDir);
    }

    return none != distance;
}

bool tryToDraw<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color) {
    Optional<float> distance = none;

    if (none != (distance = rayMarchNewton<T>(ro, rd))) {
        color = getColor<T>(ro, rd, distance.value, lightDir);
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

    if (tryToDraw<I::Triangle>(ro, rd, lightDir, color)) {
        color *= float3(1.0, 0.0, 0.0);
    }

    return float4(color, 1.0);
}
