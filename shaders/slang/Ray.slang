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

public struct IntervalRayCasterStackNewton<S : IScene<Interval, Interval3>> : IIntersector {
    public static Optional<float> checkIntersection(float3 ro, float3 rd, const float epsilon, const float maxDistance) {
        Optional<float> result = none;

        Interval t0;
        Interval f;

        Stack<Interval, 64> stack;
        stack.push(Interval(0, maxDistance));

        while (false == stack.isEmpty() && false == stack.isFull()) {
            t0 = stack.pop();
            f = S::evaluate(ro + rd * t0);

            if (f.contains(0.0)) {
                if (t0.length() < epsilon) {
                    return t0.minVal;
                }

                Interval dF = dot(gradient<S>(ro + rd * t0), rd);

                float mid = t0.mid();
                Interval fMid = S::evaluate(ro + rd * Interval(mid));

                if (!dF.contains(0.0)) {
                    Interval t1 = mid - (fMid / dF);

                    if (t1.intersects(t0)) {
                        Interval res = t1.intersection(t0);

                        if (res.length() < t0.length()) {
                            stack.push(res);
                        }
                        else {
                            stack.push(Interval(mid, t0.maxVal));
                            stack.push(Interval(t0.minVal, mid));
                        }
                    }
                }
                else if (!fMid.contains(0.0)) {
                    if (0.0 < fMid.i.x) {
                        Interval t1 = mid - Interval(-1e30, fMid.i.x / dF.i.x);
                        Interval t2 = mid - Interval(fMid.i.x / dF.i.y, 1e30);

                        if (t1.intersects(t0)) {
                            Interval res = t1.intersection(t0);

                            if (res.length() < t0.length()) {
                                stack.push(res);
                            }
                            else {
                                stack.push(Interval(mid, t0.maxVal));
                                stack.push(Interval(t0.minVal, mid));
                            }
                        }
                        if (t2.intersects(t0)) {
                            Interval res = t2.intersection(t0);

                            if (res.length() < t0.length()) {
                                stack.push(res);
                            }
                            else {
                                stack.push(Interval(mid, t0.maxVal));
                                stack.push(Interval(t0.minVal, mid));
                            }
                        }
                    }
                    else {
                        Interval t1 = mid - Interval(-1e30, fMid.i.x / dF.i.y);
                        Interval t2 = mid - Interval(fMid.i.x / dF.i.x, 1e30);

                        if (t1.intersects(t0)) {
                            stack.push(t1.intersection(t0));
                        }
                        if (t2.intersects(t0)) {
                            stack.push(t2.intersection(t0));
                        }
                    }
                }
                else {
                    stack.push(Interval(mid, t0.maxVal));
                    stack.push(Interval(t0.minVal, mid));
                }
            }
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
