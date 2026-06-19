module IBeamCaster;

import IScene;
import Intervals;
import Intervals3;

public interface IBeamCaster<S : IScene<Interval, Interval3>> {
    public static Optional<Interval> BeamCast(Interval U, Interval V, Interval T, float3 cameraOffset, float epsilon);

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
