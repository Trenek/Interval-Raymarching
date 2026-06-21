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

public struct BeamCasterStack<S : IScene<Interval, Interval3>> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        Interval t = T;
        Interval f;

        Stack<Interval, 64> stack;
        stack.push(t);

        while (false == stack.isEmpty() && false == stack.isFull()) {
            t = stack.pop();
            
            Interval3 p = Interval3(U * t, V * t, t);
            f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0)) {
                if (t.length() < epsilon) {
                    return t;
                }
                float mid = t.mid();

                stack.push(Interval(mid, t.maxVal));
                stack.push(Interval(t.minVal, mid));
            }
        }

        if (f.contains(0.0)) {
            result = t;
        }

        return result;
    }
}

public struct BeamCasterInt<S : IScene<Interval, Interval3>> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        float tLength = T.length();
        float tStart = T.minVal;

        uint32_t eps = uint32_t(floor(log2(T.length() / epsilon)));
        uint32_t2 idx = { 1, 1 };

        while (idx.x <= idx.y) {
            Interval t0 = tStart + Interval(float(idx.x - 1) * tLength / idx.y, float(idx.x) * tLength / idx.y);
            Interval3 p = Interval3(U * t0, V * t0, t0);
            Interval f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0)) {
                if (firstbithigh(idx.y) >= eps) {
                    return t0;
                }

                idx <<= 1;
                idx.x -= 1;
            }
            else {
                idx >>= firstbitlow(idx.x);
                idx.x += 1;
            }
        }

        return result;
    }
}

public struct BeamCasterFloat<S : IScene<Interval, Interval3>> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        float tLength = T.length();
        float tStart = T.minVal;

        int dlast = int(round(log2(T.length() / epsilon)));
        int d = 0;

        float2 t = float2(0.0f, tLength);
        float tincr = tLength * 0.5f;

        Interval t0 = tStart + Interval(t);
        Interval3 p = Interval3(U * t0, V * t0, t0);
        Interval f = S::evaluate(p - cameraOffset);

        if (f.contains(0.0f)) while (true) {
            t.y = t.x + tincr;

            t0 = tStart + Interval(t);
            p = Interval3(U * t0, V * t0, t0);
            f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0f)) {
                if (d == dlast) {
                    return t0;
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

public struct BeamCasterStackNewton<S : IScene<Interval, Interval3>> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        Interval t = T;
        Interval f;

        Stack<Interval, 64> stack;
        stack.push(t);

        float3 rdCenter = float3(U.mid(), V.mid(), 1.0f);

        while (false == stack.isEmpty() && false == stack.isFull()) {
            t = stack.pop();
            
            Interval3 p = Interval3(U * t, V * t, t);
            f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0)) {
                Interval dF = dot(gradient<S>(p - cameraOffset), Interval3(rdCenter));

                Optional<float> n = none;
                
                if (!dF.contains(0.0)) {
                    n = Newton<S>(cameraOffset, rdCenter, t, f, dF, epsilon);
                }

                if (n != none) {
                    return Interval(n.value, n.value + epsilon);
                }
                else if (t.length() < epsilon) {
                    return t;
                }
                else {
                    float mid = t.mid();

                    stack.push(Interval(mid, t.maxVal));
                    stack.push(Interval(t.minVal, mid));
                }
            }
        }

        if (f.contains(0.0)) {
            result = t;
        }

        return result;
    }
}

public struct BeamCasterIntNewton<S : IScene<Interval, Interval3>> : IBeamCaster<S> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon) {
        Optional<Interval> result = none;

        float tLength = T.length();
        float tStart = T.minVal;

        uint64_t eps = uint64_t(floor(log2(T.length() / epsilon)));
        uint64_t h = 1;
        uint64_t l = 1;

        float3 rdCenter = float3(U.mid(), V.mid(), 1.0f);

        while (h <= l) {
            Interval t0 = tStart + Interval(float(h - 1) * tLength / l, float(h) * tLength / l);
            Interval3 p = Interval3(U * t0, V * t0, t0);
            Interval f = S::evaluate(p - cameraOffset);

            if (f.contains(0.0)) {
                // Zachowanie identycznego mapowania przestrzeni dla gradientu i metody Newtona
                Interval dF = dot(gradient<S>(p - cameraOffset), rdCenter);

                Optional<float> n = none;
                
                if (!dF.contains(0.0)) {
                    n = Newton<S>(cameraOffset, rdCenter, t0, f, dF, epsilon);
                }

                // Przypisanie wyniku bezpośrednio z zachowaniem dopasowania typów Optional
                if (n != none) {
                    return Interval(n.value, n.value + epsilon);
                }

                if (firstbithigh(l) >= eps) {
                    return t0;
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

