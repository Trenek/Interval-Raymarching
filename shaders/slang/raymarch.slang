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
    float3 grad;

    DifferentialPair<float3> dp_x = diffPair(p, float3(1.0, 0.0, 0.0));
    DifferentialPair<float3> dp_y = diffPair(p, float3(0.0, 1.0, 0.0));
    DifferentialPair<float3> dp_z = diffPair(p, float3(0.0, 0.0, 1.0));

    grad.x = fwd_diff(T::evaluate)(dp_x).d;
    grad.y = fwd_diff(T::evaluate)(dp_y).d;
    grad.z = fwd_diff(T::evaluate)(dp_z).d;

    return grad;
}

#define FORWARD_DIFF

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

Optional<float> rayMarch<T : IScene<float, float3>>(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
    Optional<float> result = none;
    float t = 0.0;
    float distanceTraveled = 1.0;
    
    for (int i = 0; between(distanceTraveled, epsilon, maxDistance) && i < 80; i += 1) {
        t += distanceTraveled = T::evaluate(ro + rd * t);
    }

    if (distanceTraveled < maxDistance) {
        result = t;
    }
    
    return result;
}

Optional<float> rayMarchStep<T : IScene<float, float3>>(float3 ro, float3 rd, const float, const float maxDistance) {
    Optional<float> result = none;
    float t = 0.0;
    float prevVal = 1.0;
    float val = 1.0;
    float step = 0.01;
    
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

Optional<float> rayMarch<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
    Optional<float> result = none;

    Interval t = Interval(0.0, maxDistance);
    Interval f;

    Stack<Interval, 64> stack;
    stack.push(t);

    while (false == stack.isEmpty() && false == stack.isFull()) {
        t = stack.pop();
        f = T::evaluate(ro + rd * t);

        if (f.contains(0.0)) {
            if (t.length() < epsilon) {
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

Optional<float> rayMarchInt<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
    Optional<float> result = none;

    Interval t0;
    Interval f;

    uint64_t eps = floor(log2(10.0 / epsilon));
    uint64_t h = 1;
    uint64_t l = 1;

    while (h <= l) {
        t0 = Interval(float2((h - 1) * maxDistance / l, h * maxDistance / l));
        f = T::evaluate(ro + rd * t0);

        if (f.contains(0.0)) {
            if (firstbithigh(l) >= eps) {
                return t0.minVal;
            }

            h = 1 + 2 * (h - 1);
            l *= 2;
        }
        else {
            uint przesuniecie = firstbitlow(h & (-h));

            l = l >> przesuniecie;
            h = h >> przesuniecie;

            h += 1;
        }
    }

    return result;
}

Optional<float> rayMarchFloat<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
    Optional<float> result = none;

    int dlast = round(log2(maxDistance / epsilon));
    int d = 0;

    float2 t = float2(0.0f, maxDistance);
    float tincr = maxDistance * 0.5f;

    Interval t0 = Interval(t);
    Interval f = T::evaluate(ro + rd * t0);

    if (f.contains(0.0f)) while (true) {
        t.y = t.x + tincr;

        t0 = Interval(t);
        f = T::evaluate(ro + rd * t0);

        if (f.contains(0.0f)) {
            if (d == dlast) {
                return t.x;
            }

            d++;
            tincr *= 0.5f;
        }
        else {
            t.x = t.y;

            float fp = frac(0.5f * t.x / tincr);

            if (fp < 1e-8) {
                for (int j = 0; j <= dlast; j += 1) {
                    tincr *= 2;
                    d--;
                    fp = frac(0.5 * t.x / tincr);
                    if (d == -1 || fp > 1e-8) break;
                }

                if (d == -1) {
                    break;
                }
            }
        }
    }

    return result;
}


Optional<float> Newton<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, Interval t0, Interval f, Interval dF, float epsilon) {
    while (t0.length() > epsilon) {
        float mid = t0.mid();

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

Optional<float> rayMarchNewton<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
    Optional<float> result = none;

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

Interval3 getNormal<T : IScene<Interval, Interval3>>(Interval3 p) {
    return normalize(gradient<T>(p));
}

float3 getColor<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float distance, float3 lightDirection, float epsilon, float maxDistance) {
    float3 normal = getNormal<T>(ro + rd * Interval(distance)).mid();
    //
    // float3 hitPoint = ro + rd * distance;
    // float3 shadowRo = hitPoint + lightDirection;
    //
    // Optional<float> shadowHit = rayMarch<T>(shadowRo, lightDirection, epsilon, maxDistance);
    // float shadowFactor = (none == shadowHit) ? 1.0 : 0.0;

    return 0.15 + clamp(dot(normal, lightDirection), 0.0, 1.0);
}

bool tryToDraw<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, float3 lightDir, in out float3 color, const float epsilon, const float maxDistance) {
    Optional<float> distance = none;

    if (none != (distance = rayMarchFloat<T>(ro, rd, epsilon, maxDistance))) {
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

    if (tryToDraw<I::Steiner>(ro, rd, lightDir, color, exp2(-12.0), 10)) {
        color *= float3(0.0, 1.0, 1.0);
    }

    return float4(color, 1.0);
}
