module Modes;

import IScene;
import Intervals;
import Intervals3;
import Affine;
import Affine3;

public interface Mode {
    public static Optional<float> mode<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, Interval t0, Interval f, float epsilon);
    public static Optional<float> mode<T : IScene<Affine, Affine3>>(float3 ro, float3 rd, Interval t0, Affine f, float epsilon);
}

public struct NormalMode : Mode {
    public static Optional<float> mode<T : IScene<Interval, Interval3>>(float3, float3, Interval, Interval, float) {
        return none;
    }
    public static Optional<float> mode<T : IScene<Affine, Affine3>>(float3, float3, Interval, Affine, float) {
        return none;
    }
}

public struct NewtonMode : Mode {
    static Optional<float> Newton<T : IScene<Interval, Interval3>>(float3 ro, float3 rd, Interval t0, Interval f, Interval dF, float epsilon) {
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

    static Optional<float> Newton<T : IScene<Affine, Affine3>>(float3 ro, float3 rd, Interval t0, Affine f, Affine dF, float epsilon) {
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

    public static Optional<float> mode<S : IScene<Interval, Interval3>>(float3 ro, float3 rd, Interval t0, Interval f, float epsilon) {
        Interval dF = dot(gradient<S>(ro + rd * t0), rd);
        Optional<float> n = none;

        if (!dF.contains(0.0)) {
            Optional<float> n = Newton<S>(ro, rd, t0, f, dF, epsilon);
        }

        return n;
    }

    public static Optional<float> mode<S : IScene<Affine, Affine3>>(float3 ro, float3 rd, Interval t0, Affine f, float epsilon) {
        Affine dF = dot(gradient<S>(ro + rd * Affine(t0)), rd);
        Optional<float> n = none;

        if (!dF.contains(0.0)) {
            Optional<float> n = Newton<S>(ro, rd, t0, f, dF, epsilon);
        }

        return n;
    }
}

