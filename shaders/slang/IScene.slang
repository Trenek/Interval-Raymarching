module IScene;

import Intervals;
import Intervals3;
import Affine;
import Affine3;

public interface IScene<R : IDifferentiable, T3 : IDifferentiable> {
    [Differentiable]
    static R evaluate(T3 p);
}

public float3 gradient<T : IScene<float, float3>>(float3 p) {
    return float3(
        fwd_diff(T::evaluate)(diffPair(p, float3(1.0, 0.0, 0.0))).d,
        fwd_diff(T::evaluate)(diffPair(p, float3(0.0, 1.0, 0.0))).d,
        fwd_diff(T::evaluate)(diffPair(p, float3(0.0, 0.0, 1.0))).d,
    );
}

// #define FORWARD_DIFF

#ifdef FORWARD_DIFF
public Interval3 gradient<T : IScene<Interval, Interval3>>(Interval3 p) {
    return Interval3(
        fwd_diff(T::evaluate)(diffPair(p, Interval3(float3(1.0, 0.0, 0.0)))).d,
        fwd_diff(T::evaluate)(diffPair(p, Interval3(float3(0.0, 1.0, 0.0)))).d,
        fwd_diff(T::evaluate)(diffPair(p, Interval3(float3(0.0, 0.0, 1.0)))).d
    );
}

public Affine3 gradient<T : IScene<Affine, Affine3>>(Affine3 p) {
    return Affine3(
        fwd_diff(T::evaluate)(diffPair(p, Affine3(float3(1.0, 0.0, 0.0)))).d,
        fwd_diff(T::evaluate)(diffPair(p, Affine3(float3(0.0, 1.0, 0.0)))).d,
        fwd_diff(T::evaluate)(diffPair(p, Affine3(float3(0.0, 0.0, 1.0)))).d
    );
}
#else
public Interval3 gradient<T : IScene<Interval, Interval3>>(Interval3 p) {
    float eps = 1e-5;

    Interval3 pXP = Interval3(p.x + eps, p.y, p.z);
    Interval3 pXM = Interval3(p.x - eps, p.y, p.z);

    Interval3 pYP = Interval3(p.x, p.y + eps, p.z);
    Interval3 pYM = Interval3(p.x, p.y - eps, p.z);

    Interval3 pZP = Interval3(p.x, p.y, p.z + eps);
    Interval3 pZM = Interval3(p.x, p.y, p.z - eps);

    return Interval3(
        T::evaluate(pXP) - T::evaluate(pXM),
        T::evaluate(pYP) - T::evaluate(pYM),
        T::evaluate(pZP) - T::evaluate(pZM)
    ) / (2 * eps);
}

public Affine3 gradient<T : IScene<Affine, Affine3>>(Affine3 p) {
    float eps = 1e-5;

    Affine3 pXP = Affine3(p.x + eps, p.y, p.z);
    Affine3 pXM = Affine3(p.x - eps, p.y, p.z);

    Affine3 pYP = Affine3(p.x, p.y + eps, p.z);
    Affine3 pYM = Affine3(p.x, p.y - eps, p.z);

    Affine3 pZP = Affine3(p.x, p.y, p.z + eps);
    Affine3 pZM = Affine3(p.x, p.y, p.z - eps);

    return Affine3(
        T::evaluate(pXP) - T::evaluate(pXM),
        T::evaluate(pYP) - T::evaluate(pYM),
        T::evaluate(pZP) - T::evaluate(pZM)
    ) / (2 * eps);
}
#endif

public float3 getNormal<T : IScene<float, float3>>(float3 p) {
    return normalize(gradient<T>(p));
}

public Interval3 getNormal<T : IScene<Interval, Interval3>>(Interval3 p) {
    return normalize(gradient<T>(p));
}

public Affine3 getNormal<T : IScene<Affine, Affine3>>(Affine3 p) {
    return normalize(gradient<T>(p));
}
