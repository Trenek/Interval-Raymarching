module Intervals3;

import Intervals;

public struct Interval3 : IDifferentiable, IArithmetic {
    public Interval x;
    public Interval y;
    public Interval z;

    [Differentiable]
    public __init(int val) {
        this.x = Interval(val);
        this.y = Interval(val);
        this.z = Interval(val);
    }

    [Differentiable]
    public __init(Interval3 val) {
        this.x = val.x;
        this.y = val.y;
        this.z = val.z;
    }

    [Differentiable]
    public __init(Interval x, Interval y, Interval z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    [Differentiable]
    public __init(Interval x) {
        this.x = x;
        this.y = x;
        this.z = x;
    }

    [Differentiable]
    public __init(float x) {
        this.x = Interval(x);
        this.y = Interval(x);
        this.z = Interval(x);
    }

    [Differentiable]
    public __init(float3 x) {
        this.x = Interval(x.x);
        this.y = Interval(x.y);
        this.z = Interval(x.z);
    }

    [Differentiable]
    public float3 mid() {
        return float3(this.x.mid(), this.y.mid(), this.z.mid());
    }

    [Differentiable]
    public bool equals(Interval3 a) {
        return this.x == a.x && this.y == a.y && this.z == a.z;
    }

    [Differentiable]
    public bool lessThan(Interval3 a) {
        return this.x < a.x && this.y < a.y && this.z < a.z;
    }

    [Differentiable]
    public bool lessThanOrEquals(Interval3 a) {
        return this.x <= a.x && this.y <= a.y && this.z <= a.z;
    }

    [Differentiable]
    public Interval3 add(Interval3 b) {
        return Interval3(this.x + b.x, this.y + b.y, this.z + b.z);
    }

    [Differentiable]
    public Interval3 sub(Interval3 b) {
        return Interval3(this.x - b.x, this.y - b.y, this.z - b.z);
    }

    [Differentiable]
    public Interval3 mul(Interval3 b) {
        return Interval3(this.x * b.x, this.y * b.y, this.z * b.z);
    }

    [Differentiable]
    public Interval3 div(Interval3 b) {
        return Interval3(this.x / b.x, this.y / b.y, this.z / b.z);
    }

    [Differentiable]
    public Interval3 mod(Interval3 b) {
        return Interval3(this.x % b.x, this.y % b.y, this.z % b.z);
    }

    [Differentiable]
    public Interval3 neg() {
        return Interval3(this.x.neg(), this.y.neg(), this.z.neg());
    }
}

#define MAKE_OPERATORS(RT, OP_NAME, METHOD) \
    [Differentiable] public RT OP_NAME(Interval3 a, Interval3 b) { return a.METHOD(b); } \
    [Differentiable] public RT OP_NAME(Interval3 a, float3 b) { return a.METHOD(Interval3(b)); } \
    [Differentiable] public RT OP_NAME(float3 a, Interval3 b) { return Interval3(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Interval3 a, float b) { return a.METHOD(Interval3(b)); } \
    [Differentiable] public RT OP_NAME(float a, Interval3 b) { return Interval3(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Interval3 a, Interval b) { return a.METHOD(Interval3(b)); } \
    [Differentiable] public RT OP_NAME(Interval a, Interval3 b) { return Interval3(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(float3 a, Interval b) { return Interval3(a).METHOD(Interval3(b)); } \
    [Differentiable] public RT OP_NAME(Interval a, float3 b) { return Interval3(a).METHOD(Interval3(b)); }

MAKE_OPERATORS(Interval3, operator+, add)
MAKE_OPERATORS(Interval3, operator-, sub)
MAKE_OPERATORS(Interval3, operator*, mul)
MAKE_OPERATORS(Interval3, operator/, div)
MAKE_OPERATORS(Interval3, operator%, mod)
MAKE_OPERATORS(bool, operator==, equals);
MAKE_OPERATORS(bool, operator<, lessThan);
MAKE_OPERATORS(bool, operator<=, lessThanOrEquals);

[Differentiable]
public Interval3 operator-(Interval3 a) {
    return a.neg();
}

[Differentiable]
public Interval3 max(Interval3 a, float b) {
    return Interval3(max(a.x, b), max(a.y, b), max(a.z, b));
}

[Differentiable]
public Interval3 min(Interval3 a, float b) {
    return Interval3(min(a.x, b), min(a.y, b), min(a.z, b));
}

[Differentiable]
public Interval3 abs(Interval3 a) {
    return Interval3(abs(a.x), abs(a.y), abs(a.z));
}

[Differentiable]
public Interval length(Interval3 n) {
    return sqrt(pow(n.x, 2) + pow(n.y, 2) + pow(n.z, 2));
}

[Differentiable]
public Interval norm(Interval3 n) {
    return length(n);
}

[Differentiable]
public Interval3 normalize(Interval3 v) {
    Interval n = norm(v);

    return Interval3(v.x / n, v.y / n, v.z / n);
}

[Differentiable]
public Interval dot(Interval3 a, Interval3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

[Differentiable]
public Interval dot(const Interval3 a, const float3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

[Differentiable]
public Interval3 mul(float3x3 m, Interval3 v) {
    return Interval3(
        dot(v, m[0]),
        dot(v, m[1]),
        dot(v, m[2])
    );
}
