module Affine;

import Intervals;

public struct Affine : IDifferentiable {
    public float3 raf;

    [Differentiable]
    public __init(int val) {
        this.raf = float3(float(val), 0.0, 0.0);
    }

    [Differentiable]
    public __init(Interval i) {
        this.raf.x = i.maxVal + i.minVal;
        this.raf.y = i.maxVal - i.minVal;
        this.raf.z = 0;

        this.raf.xy *= 0.5;
    }

    [Differentiable]
    public __init(float min, float max) {
        this.raf.x = max + min;
        this.raf.y = max - min;
        this.raf.z = 0.0;

        this.raf.xy *= 0.5;
    }

    [Differentiable]
    public __init(float val) {
        this.raf = float3(val, 0.0, 0.0);
    }

    [Differentiable]
    internal __init(float3 i) {
        this.raf = i;
    }

    [Differentiable]
    public __init(Affine i) {
        this.raf = i.raf;
    }

    [Differentiable]
    float radius() {
        return abs(this.raf.y) + this.raf.z;
    }

    public bool contains(float a) {
        float r = this.radius();
        return (this.raf.x - r) <= a && a <= (this.raf.x + r);
    }

    public bool contains(Affine a) {
        float rThis = this.radius();
        float rA = a.radius();
        return (this.raf.x - rThis) <= (a.raf.x - rA) && (a.raf.x + rA) <= (this.raf.x + rThis);
    }

    public bool intersects(Affine a) {
        return abs(this.raf.x - a.raf.x) <= this.radius() + a.radius();
    }

    public Affine intersection(Affine a) {
        float rThis = this.radius();
        float rA = a.radius();
        float newMin = max(this.raf.x - rThis, a.raf.x - rA);
        float newMax = min(this.raf.x + rThis, a.raf.x + rA);
        return Affine(newMin, newMax);
    }

    public Affine hull(Affine a) {
        float rThis = this.radius();
        float rA = a.radius();
        float newMin = min(this.raf.x - rThis, a.raf.x - rA);
        float newMax = max(this.raf.x + rThis, a.raf.x + rA);
        return Affine(newMin, newMax);
    }

    public float mid() {
        return this.raf.x;
    }

    public float length() {
        return this.radius() * 2.0;
    }

    public bool equals(Affine a) {
        return all(this.raf == a.raf);
    }

    public bool lessThan(Affine a) {
        return (this.raf.x + this.radius()) < (a.raf.x - a.radius());
    }

    public bool lessThanOrEquals(Affine a) {
        return (this.raf.x + this.radius()) <= (a.raf.x + a.radius());
    }

    public Interval toInterval() {
        const float rad = radius();

        return Interval(this.raf.x - rad, this.raf.x + rad);
    }

    static DifferentialPair<Affine> fwdAdd(DifferentialPair<Affine> dpa, DifferentialPair<Affine> dpb) {
        return diffPair(dpa.p.add(dpb.p), dpa.d.add(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdAdd)]
    // (a + b)' = a' + b'
    Affine add(Affine b) {
        return Affine(this.raf + b.raf);
    }

    static DifferentialPair<Affine> fwdSub(DifferentialPair<Affine> dpa, DifferentialPair<Affine> dpb) {
        return diffPair(dpa.p.sub(dpb.p), dpa.d.sub(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdSub)]
    // (a - b)' = a' - b'
    Affine sub(Affine b) {
        return Affine(float3(this.raf.xy - b.raf.xy, this.raf.z + b.raf.z));
    }

    static DifferentialPair<Affine> fwdMul(DifferentialPair<Affine> dpa, DifferentialPair<Affine> dpb) {
        Affine t0 = dpa.p.mul(dpb.d);
        Affine t1 = dpb.p.mul(dpa.d);
        return diffPair(dpa.p.mul(dpb.p), t0.add(t1));
    }

    [Differentiable]
    [ForwardDerivative(fwdMul)]
    // (a * b)' = a' * b + a * b'
    Affine mul(Affine b) {
        return Affine(float3(
            this.raf.x * b.raf.x,
            this.raf.x * b.raf.y + b.raf.x * this.raf.y,
            abs(this.raf.x * b.raf.z) + abs(b.raf.x * this.raf.z) + this.radius() * b.radius()
        ));
    }

    [Differentiable]
    // (a / b)' = (a' * b - a * b') / b^2
    Affine div(Affine b) {
        float bRad = b.radius();

        float invX = 1.0 / b.raf.x;
        float invY = -invX * invX * b.raf.y;

        float minInv = 1.0 / (b.raf.x + bRad);
        float maxInv = 1.0 / (b.raf.x - bRad);

        float approxRad = abs(invY) + abs(invX * invX * b.raf.z);
        float remainder = max(abs(minInv - (invX - approxRad)), abs(maxInv - (invX + approxRad)));

        Affine invB = Affine(float3(invX, invY, remainder));
        return this.mul(invB);
    }

    [Differentiable]
    public Affine neg() {
        return Affine(float3(-this.raf.x, -this.raf.y, this.raf.z));
    }

    static DifferentialPair<Affine> fwdSqrt(DifferentialPair<Affine> dpa) {
        Affine t0 = dpa.p.sqrt();
        float maxVal = t0.raf.x + abs(t0.raf.y) + t0.raf.z;
        Affine invT0_2 = Affine(1.0 / (2.0 * maxVal));
        return diffPair(t0, dpa.d.mul(invT0_2));
    }

    [Differentiable]
    [ForwardDerivative(fwdSqrt)]
    Affine sqrt() {
        float r = this.radius();
        float left = max(0.0f, this.raf.x - r);
        float right = max(0.0f, this.raf.x + r);

        float sqrtL = sqrt(left);
        float sqrtR = sqrt(right);

        float denom = right - left;
        float alpha = (denom > 0.00001f) ? (sqrtR - sqrtL) / denom : 0.5f / max(0.00001f, sqrtL);

        float delta = 0.0f;
        if (alpha > 0.0f && denom > 0.00001f) {
            float x_max_error = 1.0f / (4.0f * alpha * alpha);
            if (x_max_error > left && x_max_error < right) {
                float max_exact = sqrt(x_max_error);
                float max_approx = alpha * x_max_error + (sqrtL - alpha * left);
                delta = abs(max_exact - max_approx);
            }
        }

        return Affine(alpha * this.raf + float3(
            (sqrtL - alpha * left) + (delta * 0.5f),
            0.0,
            delta * 0.5f,
        ));
    }

    static DifferentialPair<Affine> fwdAbs(DifferentialPair<Affine> dpa) {
        Affine val = dpa.p.abs();

        float r = dpa.p.radius();
        float left = dpa.p.raf.x - r;
        float right = dpa.p.raf.x + r;

        float alpha = 0.0f;
        if (left >= 0.0f) {
            alpha = 1.0f;
        } else if (right <= 0.0f) {
            alpha = -1.0f;
        } else {
            alpha = (right + left) / (right - left);
        }

        Affine der = dpa.d.mul(Affine(alpha));

        return diffPair(val, der);
    }

    [Differentiable]
    [ForwardDerivative(fwdAbs)]
    public Affine abs() {
        float r = this.radius();
        float left = this.raf.x - r;
        float right = this.raf.x + r;

        if (left >= 0.0f) return this;
        if (right <= 0.0f) return this.neg();

        float denom = 1.0f / (right - left);
        float alpha = (right + left) * denom;
        float delta = (-left * right) * denom;

        float3 newRaf;
        newRaf.x = alpha * this.raf.x + (2.0f * delta);
        newRaf.y = alpha * this.raf.y;
        newRaf.z = abs(alpha) * this.raf.z + delta;

        return Affine(newRaf);
    }

    static DifferentialPair<Affine> fwdMax(DifferentialPair<Affine> dpa, DifferentialPair<Affine> dpb) {
        float rA = dpa.p.radius();
        float rB = dpb.p.radius();
        
        Affine der = ((dpa.p.raf.x - rA) > (dpb.p.raf.x + rB)) ? dpa.d : dpb.d; 
        return diffPair(max(dpa.p, dpb.p), der);
    }

    [Differentiable]
    [ForwardDerivative(fwdMax)]
    Affine max(Affine a) {
        Affine diff = this - a;
        return (this + a + diff.abs()) * 0.5;
    }

    static DifferentialPair<Affine> fwdMin(DifferentialPair<Affine> dpa, DifferentialPair<Affine> dpb) {
        float rA = dpa.p.radius();
        float rB = dpb.p.radius();

        Affine der = ((dpa.p.raf.x + rA) < (dpb.p.raf.x - rB)) ? dpa.d : dpb.d; 
        return diffPair(min(dpa.p, dpb.p), der);
    }

    [Differentiable]
    [ForwardDerivative(fwdMin)]
    public Affine min(Affine b) {
        Affine diff = this - b;
        return (this + b - diff.abs()) * 0.5;
    }

    static DifferentialPair<Affine> fwdPow(DifferentialPair<Affine> dpa, int dpb) {
        Affine t0 = dpa.p.pow(dpb - 1);
        Affine t1 = t0.mul(dpa.d).mul(Affine(dpb));

        return diffPair(dpa.p.pow(dpb), t1);
    }

    [Differentiable]
    [ForwardDerivative(fwdPow)]
    public Affine pow(int b) {
        Affine result = this;

        [MaxIters(10)]
        for (int i = 1; i < b; i += 1) {
            result = result.mul(this);
        }

        return result;
    }
}

#define MAKE_BINARY_OPERATORS(RT, OP_NAME, METHOD) \
    [Differentiable] public RT OP_NAME(Affine a, Affine b) { return a.METHOD(b); } \
    [Differentiable] public RT OP_NAME(float a, Affine b) { return Affine(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Affine a, float b) { return a.METHOD(Affine(b)); }

#define MAKE_UNARY_OPERATOR(OP_NAME, METHOD) \
    [Differentiable] public Affine OP_NAME(Affine a) { return a.METHOD(); } \

#define MAKE_UNARY_OPERATOR_POW(OP_NAME, METHOD) \
    [Differentiable] public Affine OP_NAME(Affine a, int b) { return a.METHOD(b); } \

MAKE_BINARY_OPERATORS(bool, operator==, equals)
MAKE_BINARY_OPERATORS(bool, operator<, lessThan)
MAKE_BINARY_OPERATORS(bool, operator<=, lessThanOrEquals)
MAKE_BINARY_OPERATORS(Affine, operator+, add)
MAKE_BINARY_OPERATORS(Affine, operator-, sub)
MAKE_BINARY_OPERATORS(Affine, operator*, mul)
MAKE_BINARY_OPERATORS(Affine, operator/, div)
MAKE_BINARY_OPERATORS(Affine, max, max)
MAKE_BINARY_OPERATORS(Affine, min, min)

MAKE_UNARY_OPERATOR(sqrt, sqrt)
MAKE_UNARY_OPERATOR(abs, abs)

MAKE_UNARY_OPERATOR_POW(pow, pow)
