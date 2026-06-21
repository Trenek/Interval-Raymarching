module Ray;

import Intervals;
import Intervals3;
import Affine;
import Affine3;
import IScene;
import Stack;

public interface IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance);
}

public struct SphereMarcher<T : IScene<float, float3>> : IIntersector {
    static bool between(float a, float minVal, float maxVal) {
        return a >= minVal && a <= maxVal;
    }

    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
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
}

public struct RayMarcher<T : IScene<float, float3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float, const float maxDistance) {
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
}

public interface IDivider {
    public __init(float epsilon, float maxDistance);

    bool lastingCondition();
    bool acceptanceCondition();
    [[mutating]] Interval getNext();
    [[mutating]] void goDown();
    [[mutating]] void goUp();
}

public struct StackDivider : IDivider {
    Stack<Interval, 64> stack;
    Interval curr;
    float epsilon;

    public __init(float epsilon, float maxDistance) {
        this.curr = Interval(0);
        this.epsilon = epsilon;
        stack.push(Interval(0, maxDistance));
    }

    [[mutating]]
    Interval getNext() {
        return curr = stack.pop();
    }

    bool lastingCondition() {
        return false == stack.isEmpty() && false == stack.isFull();
    }

    [[mutating]]
    void goDown() {
        Interval t = this.curr;
        float mid = t.mid();

        stack.push(Interval(mid, t.maxVal));
        stack.push(Interval(t.minVal, mid));
    }

    [[mutating]]
    void goUp() {}

    bool acceptanceCondition() {
        return this.curr.length() < this.epsilon;
    }
}

public struct IntDivider : IDivider {
    uint32_t eps;
    uint32_t h = 1;
    uint32_t l = 1;

    float epsilon;
    float maxDistance;

    public __init(float epsilon, float maxDistance) {
        this.epsilon = epsilon;
        this.maxDistance = maxDistance;

        this.eps = uint32_t(floor(log2(maxDistance / epsilon)));
    }

    Interval getNext() {
        return Interval(float2(
            (this.h - 1) * this.maxDistance / this.l, 
            this.h * this.maxDistance / this.l
        ));
    }

    bool lastingCondition() {
        return this.h <= this.l;
    }

    [[mutating]]
    void goDown() {
        this.h <<= 1;
        this.l <<= 1;

        this.h -= 1;
    }

    [[mutating]]
    void goUp() {
        uint shift = firstbitlow(h & (-h));

        this.h >>= shift;
        this.l >>= shift;

        this.h += 1;
    }

    bool acceptanceCondition() {
        return firstbithigh(this.l) >= this.eps;
    }
}

public struct IntervalRayCaster<S : IScene<Interval, Interval3>, D : IDivider> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t;
        Interval f;

        D d = D(epsilon, maxDistance);

        while (d.lastingCondition()) {
            t = d.getNext();
            f = S::evaluate(ro + rd * t);

            if (f.contains(0.0)) {
                if (d.acceptanceCondition()) {
                    return t.minVal;
                }

                d.goDown();
            }
            else {
                d.goUp();
            }
        }

        return result;
    }
}

public struct AffineRayCasterInt<T : IScene<Affine, Affine3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Affine f;

        uint32_t eps = uint32_t(floor(log2(maxDistance / epsilon)));
        uint32_t h = 1;
        uint32_t l = 1;

        while (h <= l) {
            t0 = Interval(float2((h - 1) * maxDistance / l, h * maxDistance / l));
            f = T::evaluate(ro + rd * Affine(t0));

            if (f.contains(0.0)) {
                if (firstbithigh(l) >= eps) {
                    return t0.minVal;
                }

                h = 1 + 2 * (h - 1);
                l *= 2;
            }
            else {
                uint shift = firstbitlow(h & (-h));

                l >>= shift;
                h >>= shift;

                h += 1;
            }
        }

        return result;
    }
}

public struct IntervalRayCasterFloat<T : IScene<Interval, Interval3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        int dlast = int(round(log2(maxDistance / epsilon)));
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
}

public struct AffineRayCasterFloat<T : IScene<Affine, Affine3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        int dlast = int(round(log2(maxDistance / epsilon)));
        int d = 0;

        float2 t = float2(0.0f, maxDistance);
        float tincr = maxDistance * 0.5f;

        Interval t0 = Interval(t);
        Affine f = T::evaluate(ro + rd * Affine(t0));

        if (f.contains(0.0f)) while (true) {
            t.y = t.x + tincr;

            t0 = Interval(t);
            f = T::evaluate(ro + rd * Affine(t0));

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

public struct IntervalRayCasterStackNewton<T : IScene<Interval, Interval3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
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

                Optional<float> n = none;

                if (!dF.contains(0.0)) {
                    n = Newton<T>(ro, rd, t0, f, dF, epsilon);
                }

                if (n != none) {
                    return n;
                }
                else if (t0.length() < epsilon) {
                    return t0.minVal;
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
}

public struct IntervalRayCasterIntNewton<T : IScene<Interval, Interval3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Interval f;

        uint32_t eps = uint32_t(floor(log2(maxDistance / epsilon)));
        uint32_t h = 1;
        uint32_t l = 1;

        while (h <= l) {
            t0 = Interval(float2((h - 1) * maxDistance / l, h * maxDistance / l));
            f = T::evaluate(ro + rd * t0);

            if (f.contains(0.0)) {
                Interval dF = dot(gradient<T>(ro + rd * t0), rd);

                Optional<float> n = none;
                
                if (!dF.contains(0.0)) {
                    n = Newton<T>(ro, rd, t0, f, dF, epsilon);
                }

                if (n != none) {
                    return n;
                }

                if (firstbithigh(l) >= eps) {
                    return t0.minVal;
                }

                h = 1 + 2 * (h - 1);
                l *= 2;
            }
            else {
                uint shift = firstbitlow(h & (-h));

                l >>= shift;
                h >>= shift;

                h += 1;
            }
        }

        return result;
    }
}

Optional<float> Newton<T : IScene<Affine, Affine3>>(float3 ro, float3 rd, Interval t0, Affine f, Affine dF, float epsilon) {
    while (t0.length() > epsilon) {
        float mid = t0.mid();

        Affine fMid = T::evaluate(ro + rd * Affine(mid));
        Interval t1 = mid - (fMid / dF).toInterval();

        if (t0.contains(t1)) {
            t0 = t1;
        }
        else if (t1.intersects(t0)) {
            t0 = t1.intersection(t0);
        }
        else {
            return none;
        }

        f = T::evaluate(ro + rd * Affine(t0));
        dF = dot(gradient<T>(ro + rd * Affine(t0)), rd);

        if (dF.contains(0.0)) {
            return none; 
        }
    }

    if (f.contains(0.0)) {
        return Optional<float>(t0.minVal);
    }

    return none;
}

public struct AffineRayCasterIntNewton<T : IScene<Affine, Affine3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Affine f;

        uint32_t eps = uint32_t(floor(log2(maxDistance / epsilon)));
        uint32_t h = 1;
        uint32_t l = 1;

        while (h <= l) {
            t0 = Interval(float2((h - 1) * maxDistance / l, h * maxDistance / l));
            f = T::evaluate(ro + rd * Affine(t0));

            if (f.contains(0.0)) {
                Affine dF = dot(gradient<T>(ro + rd * Affine(t0)), rd);

                Optional<float> n = none;
                
                if (!dF.contains(0.0)) {
                    n = Newton<T>(ro, rd, t0, f, dF, epsilon);
                }

                if (n != none) {
                    return n;
                }

                if (firstbithigh(l) >= eps) {
                    return t0.minVal;
                }

                h = 1 + 2 * (h - 1);
                l *= 2;
            }
            else {
                uint shift = firstbitlow(h & (-h));

                l >>= shift;
                h >>= shift;

                h += 1;
            }
        }

        return result;
    }
}
