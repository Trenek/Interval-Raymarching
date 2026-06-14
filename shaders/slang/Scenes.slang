[Differentiable]
float3x3 rot3D(float3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    axis = normalize(axis);

    return float3x3(
        oc * axis.x * axis.x + c,
        oc * axis.x * axis.y - axis.z * s, 
        oc * axis.x * axis.z + axis.y * s,
        oc * axis.y * axis.x + axis.z * s,
        oc * axis.y * axis.y + c,
        oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, 
        oc * axis.z * axis.y + axis.x * s,
        oc * axis.z * axis.z + c
    );
} 

struct Triangle : IScene<T, T3> {
    [Differentiable]
    static T signedDstToCircle(T3 p, float3 center, float r) {
        return abs(p.x) + abs(p.y) + abs(p.z) - r;
    }

    [Differentiable]
    static T evaluate(T3 p) {
        float3x3 rot = rot3D(float3(3.0, 2.0, 1.0), ubo.iTime);

        return signedDstToCircle(mul(rot, p), float3(0.0, 0.0, 0.0), 0.5);
    }
}

struct Sphere : IScene<T, T3> {
    [Differentiable]
    static T signedDstToCircle(T3 p, float3 center, float r) {
        return length(center - p) - r;
    }

    [Differentiable]
    static T evaluate(T3 p) {
        return signedDstToCircle(p, float3(sin(ubo.iTime), 0.0, 0.0), 0.5);
    }
}

struct Cube : IScene<T, T3> {
    [Differentiable]
    static T maxVal(T3 v) {
        return max(max(v.x, v.y), v.z);
    }

    [Differentiable]
    static T signedDstToBox(T3 p, float3 center, float side) {
        T3 offset = abs(p - center) - side;

        T outsideDst = length(max(offset, 0.0));
        T insideDst = maxVal(min(offset, 0.0));

        return outsideDst + insideDst;
    }

    [Differentiable]
    static T evaluate(T3 p) {
        float3x3 rot1 = rot3D(float3(3.0, 2.0, 1.0), ubo.iTime);

        return signedDstToBox(mul(rot1, p), float3(0.0), 0.5);
    }
};

struct FullScene : IScene<T, T3> {
    [Differentiable]
    static T smin(T a, T b, float k) {
        T h = max(k - abs(a - b), 0.0) / k;
        return min(a, b) - pow(h, 3) * k * (1.0 / 6.0);
    }

    [Differentiable]
    static T evaluate(T3 p) {
        return smin(Sphere::evaluate(p), Cube::evaluate(p), 1.0);
    }
};

struct Heart : IScene<T, T3> {
    [Differentiable]
    static T evaluate(T3 p) {
        float3x3 rot1 = rot3D(float3(1.0, 0.0, 0.0), 3.14 * 3 / 2);
        float3x3 rot2 = rot3D(float3(0.0, 0.0, 1.0), ubo.iTime);
        p = mul(rot1, p);
        p = mul(rot2, p);

        T x = p.x;
        T y = p.y;
        T z = p.z;

        T x2 = pow(x, 2);
        T y2 = pow(y, 2);
        T z2 = pow(z, 2);

        T z3 = pow(z, 3);

        return pow(x2 + (9.0 / 4.0) * y2 + z2 - 1, 3) - x2 * z3 - (9.0 / 80.0) * y2 * z3;
    }
};

struct DecoCube : IScene<T, T3> {
    [Differentiable]
    static T evaluate(T3 p) {
        float3x3 rot1 = rot3D(float3(1.0, 0.0, 0.0), 3.14 * 3 / 2);
        float3x3 rot2 = rot3D(float3(3.0, 2.0, 1.0), ubo.iTime);
        p = mul(rot1, p);
        p = mul(rot2, p);

        float c = pow(0.8f, 2);

        T x = p.x;
        T y = p.y;
        T z = p.z;

        T x2 = pow(x, 2);
        T y2 = pow(y, 2);
        T z2 = pow(z, 2);

        T term1 = pow(x2 + y2 - c, 2) + pow(z2 - 1.0f, 2);
        T term2 = pow(y2 + z2 - c, 2) + pow(x2 - 1.0f, 2);
        T term3 = pow(z2 + x2 - c, 2) + pow(y2 - 1.0f, 2);

        return (term1 * term2 * term3) - 0.02f;
    }
};

struct Steiner : IScene<T, T3> {
    [Differentiable]
    static T evaluate(T3 p) {
        float3x3 rot1 = rot3D(float3(1.0, 0.0, 0.0), 3.14 * 3 / 2);
        float3x3 rot2 = rot3D(float3(3.0, 2.0, 1.0), ubo.iTime);

        p = mul(rot1, p);
        p = mul(rot2, p);

        T x = p.x;
        T y = p.y;
        T z = p.z;

        T x2 = pow(x, 2);
        T y2 = pow(y, 2);
        T z2 = pow(z, 2);

        return x2 * y2 + y2 * z2 + x2 * z2 + x * y * z;
    }
};
