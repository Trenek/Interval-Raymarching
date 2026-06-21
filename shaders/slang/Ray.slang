module Ray;

import Stack;
import Intervals;
import Intervals3;
import Affine;
import Affine3;
import IScene;

import Divider;
import Modes;

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

public struct IntervalRayCaster<S : IScene<Interval, Interval3>, D : IDivider, M : Mode> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Interval f;

        D d = D(epsilon, maxDistance);

        while (d.lastingCondition()) {
            t0 = d.getNext();
            f = S::evaluate(ro + rd * t0);

            if (f.contains(0.0)) {
                Optional<float> n = M::mode<S>(ro, rd, t0, f, epsilon);

                if (n != none) {
                    return n;
                }
                
                if (d.acceptanceCondition()) {
                    return t0.minVal;
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

public struct AffineRayCaster<S : IScene<Affine, Affine3>, D : IDivider, M : Mode> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Affine f;

        D d = D(epsilon, maxDistance);

        while (d.lastingCondition()) {
            t0 = d.getNext();
            f = S::evaluate(ro + rd * Affine(t0));

            if (f.contains(0.0)) {
                Optional<float> n = M::mode<S>(ro, rd, t0, f, epsilon);

                if (n != none) {
                    return n;
                }
                
                if (d.acceptanceCondition()) {
                    return t0.minVal;
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
