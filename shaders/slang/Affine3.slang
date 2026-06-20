module Affine3;

import Affine;

public struct Affine3 : IDifferentiable {
    public Affine x;
    public Affine y;
    public Affine z;

    [Differentiable]
    public __init(int val) {
        this.x = Affine(val);
        this.y = Affine(val);
        this.z = Affine(val);
    }

    [Differentiable]
    public __init(Affine3 val) {
        this.x = val.x;
        this.y = val.y;
        this.z = val.z;
    }

    [Differentiable]
    public __init(Affine x, Affine y, Affine z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    [Differentiable]
    public __init(Affine x) {
        this.x = x;
        this.y = x;
        this.z = x;
    }

    [Differentiable]
    public __init(float x) {
        this.x = Affine(x);
        this.y = Affine(x);
        this.z = Affine(x);
    }

    [Differentiable]
    public __init(float3 x) {
        this.x = Affine(x.x);
        this.y = Affine(x.y);
        this.z = Affine(x.z);
    }

    public bool equals(Affine3 a) {
        return this.x == a.x && this.y == a.y && this.z == a.z;
    }

    public bool lessThan(Affine3 a) {
        return this.x < a.x && this.y < a.y && this.z < a.z;
    }

    public bool lessThanOrEquals(Affine3 a) {
        return this.x <= a.x && this.y <= a.y && this.z <= a.z;
    }

    [Differentiable]
    public Affine3 add(Affine3 b) {
        return Affine3(this.x + b.x, this.y + b.y, this.z + b.z);
    }

    static DifferentialPair<Affine3> fwdSub(DifferentialPair<Affine3> dpa, DifferentialPair<Affine3> dpb) {
        return diffPair(dpa.p.sub(dpb.p), dpa.d.sub(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdSub)]
    public Affine3 sub(Affine3 b) {
        return Affine3(this.x - b.x, this.y - b.y, this.z - b.z);
    }

    [Differentiable]
    public Affine3 mul(Affine3 b) {
        return Affine3(this.x * b.x, this.y * b.y, this.z * b.z);
    }

    [Differentiable]
    public Affine3 div(Affine3 b) {
        return Affine3(this.x / b.x, this.y / b.y, this.z / b.z);
    }

    [Differentiable]
    public Affine3 neg() {
        return Affine3(this.x.neg(), this.y.neg(), this.z.neg());
    }

    [Differentiable]
    public Affine3 max(Affine3 b) {
        return Affine3(max(this.x, b.x), max(this.y, b.y), max(this.z, b.z));
    }

    [Differentiable]
    public Affine3 min(Affine3 b) {
        return Affine3(min(this.x, b.x), min(this.y, b.y), min(this.z, b.z));
    }

    public float3 mid() {
        return float3(this.x.mid(), this.y.mid(), this.z.mid());
    }

    [Differentiable]
    public Affine3 abs() {
        return Affine3(abs(this.x), abs(this.y), abs(this.z));
    }

    [Differentiable]
    public Affine dot(Affine3 b) {
        return this.x * b.x + this.y * b.y + this.z * b.z;
    }
}

#define MAKE_BINARY_OPERATORS(RT, OP_NAME, METHOD) \
    [Differentiable] public RT OP_NAME(Affine3 a, Affine3 b) { return a.METHOD(b); } \
    [Differentiable] public RT OP_NAME(Affine3 a, float3 b) { return a.METHOD(Affine3(b)); } \
    [Differentiable] public RT OP_NAME(float3 a, Affine3 b) { return Affine3(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Affine3 a, float b) { return a.METHOD(Affine3(b)); } \
    [Differentiable] public RT OP_NAME(float a, Affine3 b) { return Affine3(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Affine3 a, Affine b) { return a.METHOD(Affine3(b)); } \
    [Differentiable] public RT OP_NAME(Affine a, Affine3 b) { return Affine3(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(float3 a, Affine b) { return Affine3(a).METHOD(Affine3(b)); } \
    [Differentiable] public RT OP_NAME(Affine a, float3 b) { return Affine3(a).METHOD(Affine3(b)); }

#define MAKE_UNARY_OPERATORS(RT, OP_NAME, METHOD) \
    [Differentiable] public RT OP_NAME(Affine3 a) { return a.METHOD(); }

// MAKE_BINARY_OPERATORS(bool, operator==, equals);
// MAKE_BINARY_OPERATORS(bool, operator<, lessThan);
// MAKE_BINARY_OPERATORS(bool, operator<=, lessThanOrEquals);
MAKE_BINARY_OPERATORS(Affine3, operator+, add)
MAKE_BINARY_OPERATORS(Affine3, operator-, sub)
MAKE_BINARY_OPERATORS(Affine3, operator*, mul)
MAKE_BINARY_OPERATORS(Affine3, operator/, div)
MAKE_BINARY_OPERATORS(Affine3, max, max)
MAKE_BINARY_OPERATORS(Affine3, min, min)
MAKE_BINARY_OPERATORS(Affine, dot, dot)

// MAKE_UNARY_OPERATORS(Affine3, operator-, neg)
MAKE_UNARY_OPERATORS(Affine3, abs, abs)

[Differentiable]
public Affine length(Affine3 n) {
    return sqrt(pow(n.x, 2) + pow(n.y, 2) + pow(n.z, 2));
}

[Differentiable]
public Affine norm(Affine3 n) {
    return length(n);
}

[Differentiable]
public Affine3 normalize(Affine3 v) {
    return v / norm(v);
}

[Differentiable]
public Affine3 mul(float3x3 m, Affine3 v) {
    return Affine3(
        dot(v, m[0]),
        dot(v, m[1]),
        dot(v, m[2])
    );
}
