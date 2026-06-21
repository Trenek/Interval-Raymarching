public interface IBeamCaster<S : IScene<Interval, Interval3>> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon);

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

    public static Optional<Interval3> Subdivide(Interval U, Interval V, float w, uint d, float epsilon, uint maxDepth, float maxDistance, float3 cameraOffset, float2 normCoord) {
        Optional<Interval3> result = none;

        while (true) {
            Optional<Interval> T = BeamCast(U, V, Interval(w, maxDistance), cameraOffset, epsilon);

            if (!T.hasValue || d == maxDepth) {
                if (T.hasValue) {
                    result = Interval3(U * T.value, V * T.value, T.value) - cameraOffset;
                }

                return result;
            } else {
                float midU = U.mid();
                Interval U1 = Interval(U.minVal, midU);
                Interval U2 = Interval(midU, U.maxVal);

                float midV = V.mid();
                Interval V1 = Interval(V.minVal, midV);
                Interval V2 = Interval(midV, V.maxVal);

                float a = T.value.minVal;

                U = U1.contains(normCoord.x) ? U1 : U2;
                V = V1.contains(normCoord.y) ? V1 : V2;
                
                w = a;
                d += 1;
                epsilon /= 2.0;
            }
        }

        return result;
    }
}

public struct BeamCaster<S : IScene<Interval, Interval3>, D : IDivider> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        Interval t = T;
        Interval f;

        D d = D(epsilon, T);

        while (d.lastingCondition()) {
            t = d.getNext();
            
            Interval3 p = Interval3(U * t, V * t, t);
            f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0)) {
                if (d.acceptanceCondition()) {
                    return t;
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

public struct BeamCasterNewton<S : IScene<Interval, Interval3>, D : IDivider> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        Interval t = T;
        Interval f;

        D d = D(epsilon, T);

        float3 rdCenter = float3(U.mid(), V.mid(), 1.0f);

        while (d.lastingCondition()) {
            t = d.getNext();
            
            Interval3 p = Interval3(U * t, V * t, t);
            f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0)) {
                Interval dF = dot(gradient<S>(p - cameraOffset), Interval3(rdCenter));
                
                if (!dF.contains(0.0)) {
                    Optional<float> n = Newton<S>(cameraOffset, rdCenter, t, f, dF, epsilon);

                    if (n != none) {
                        return Interval(n.value, n.value + epsilon);
                    }
                }

                if (d.acceptanceCondition()) {
                    return t;
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
