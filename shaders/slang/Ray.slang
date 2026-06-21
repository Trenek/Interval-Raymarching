module Ray;

import Stack;
import Intervals;
import Intervals3;
import Affine;
import Affine3;
import IScene;

import Divider;

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

public struct AffineRayCaster<S : IScene<Affine, Affine3>, D : IDivider> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t;
        Affine f;

        D d = D(epsilon, maxDistance);

        while (d.lastingCondition()) {
            t = d.getNext();
            f = S::evaluate(ro + rd * Affine(t));

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

public struct IntervalRayCasterNewton<S : IScene<Interval, Interval3>, D : IDivider> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Interval f;

        D d = D(epsilon, maxDistance);

        while (d.lastingCondition()) {
            t0 = d.getNext();
            f = S::evaluate(ro + rd * t0);

            if (f.contains(0.0)) {
                Interval dF = dot(gradient<S>(ro + rd * t0), rd);

                if (!dF.contains(0.0)) {
                    Optional<float> n = Newton<S>(ro, rd, t0, f, dF, epsilon);

                    if (n != none) {
                        return n;
                    }
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

public struct AffineRayCasterNewton<S : IScene<Affine, Affine3>, D : IDivider> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Affine f;

        D d = D(epsilon, maxDistance);

        while (d.lastingCondition()) {
            t0 = d.getNext();
            f = S::evaluate(ro + rd * Affine(t0));

            if (f.contains(0.0)) {
                Affine dF = dot(gradient<S>(ro + rd * Affine(t0)), rd);

                if (!dF.contains(0.0)) {
                    Optional<float> n = Newton<S>(ro, rd, t0, f, dF, epsilon);

                    if (n != none) {
                        return n;
                    }
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
