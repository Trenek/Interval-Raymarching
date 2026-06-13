module Intervals;

public struct Interval : IDifferentiable {
    public float minVal;
    public float maxVal;

    public typealias This = Interval;

    [Differentiable]
    public __init(int val) {
        this.minVal = val;
        this.maxVal = val;
    }

    [Differentiable]
    public __init(Interval val) {
        this.minVal = val.minVal;
        this.maxVal = val.maxVal;
    }

    [Differentiable]
    public __init(float min, float max) {
        this.minVal = min;
        this.maxVal = max;
    }

    [Differentiable]
    public __init(float val) {
        this.minVal = val;
        this.maxVal = val;
    }

    public bool contains(float a) {
        return this.minVal <= a && this.maxVal >= a;
    }

    public bool contains(Interval a) {
        return this.minVal <= a.minVal && a.maxVal <= this.maxVal;
    }

    public bool intersects(Interval a) {
        return this.minVal <= a.maxVal && a.minVal <= this.maxVal;
    }

    public Interval intersection(Interval a) {
        return Interval(max(this.minVal, a.minVal), min(this.maxVal, a.maxVal));
    }

    public float mid() {
        return (this.maxVal + this.minVal) * 0.5;
    }

    public float length() {
        return this.maxVal - this.minVal;
    }

    public bool equals(Interval a) {
        return this.minVal == a.minVal && this.maxVal == a.maxVal;
    }

    public bool lessThan(Interval a) {
        return this.maxVal < a.minVal;
    }

    public bool lessThanOrEquals(Interval a) {
        return this.maxVal <= a.maxVal;
    }

    static DifferentialPair<Interval> fwdAdd(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        return diffPair(dpa.p.add(dpb.p), dpa.d.add(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdAdd)]
    // (a + b)' = a' + b'
    Interval add(Interval b) {
        return Interval(this.minVal + b.minVal, this.maxVal + b.maxVal);
    }

    static DifferentialPair<Interval> fwdSub(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        return diffPair(dpa.p.sub(dpb.p), dpa.d.sub(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdSub)]
    // (a - b)' = a' - b'
    Interval sub(Interval b) {
        return Interval(this.minVal - b.maxVal, this.maxVal - b.minVal);
    }

    static DifferentialPair<Interval> fwdMul(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        Interval t0 = dpa.p.mul(dpb.d);
        Interval t1 = dpb.p.mul(dpa.d);

        return diffPair(dpa.p.mul(dpb.p), t0.add(t1));
    }

    [Differentiable]
    [ForwardDerivative(fwdMul)]
    // (a * b)' = a' * b + a * b'
    Interval mul(Interval b) {
        float a0 = this.minVal * b.minVal;
        float a1 = this.minVal * b.maxVal;
        float a2 = this.maxVal * b.minVal;
        float a3 = this.maxVal * b.maxVal;

        float minVal = min(min(a0, a1), min(a2, a3));
        float maxVal = max(max(a0, a1), max(a2, a3));

        return Interval(minVal, maxVal);
    }

    [Differentiable]
    // (a / b)' = (a' * b - a * b') / b^2
    Interval div(Interval b) {
        return mul(Interval(1 / b.maxVal, 1 / b.minVal));
    }

    [Differentiable]
    public Interval neg() {
        return Interval(-this.maxVal, -this.minVal);
    }

    static DifferentialPair<Interval> fwdSqrt(DifferentialPair<Interval> dpa) {
        Interval t0 = dpa.p.sqrt();
        Interval t1 = dpa.d.div(t0).div(Interval(2.0));

        return diffPair(dpa.p.sqrt(), t1);
    }

    [Differentiable]
    [ForwardDerivative(fwdSqrt)]
    // (a ^ 0.5)' = a' / (a ^ 0.5) / 2
    Interval sqrt() {
        return Interval(sqrt(this.minVal), sqrt(this.maxVal));
    }

    static DifferentialPair<Interval> fwdAbs(DifferentialPair<Interval> dpa) {
        Interval val = dpa.p.abs();
        Interval der = dpa.d.mul(dpa.p.div(dpa.p.abs()));

        return diffPair(val, der);
    }

    [Differentiable]
    [ForwardDerivative(fwdAbs)]
    // (|x|)'
    Interval abs() {
        float absMin = abs(this.minVal);
        float absMax = abs(this.maxVal);

        float actualMin = 0.0;
        if (false == this.contains(0.0)) {
            actualMin = min(absMin, absMax);
        }

        return Interval(actualMin, max(absMin, absMax));
    }

    static DifferentialPair<Interval> fwdMax(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        return diffPair(max(dpa.p, dpb.p), max(dpa.d, dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdMax)]
    Interval max(Interval a) {
        return Interval(max(this.minVal, a.minVal), max(this.maxVal, a.maxVal));
    }

    static DifferentialPair<Interval> fwdMin(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        return diffPair(min(dpa.p, dpb.p), min(dpa.d, dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdMin)]
    public Interval min(Interval b) {
        return Interval(min(this.minVal, b.minVal), min(this.maxVal, b.maxVal));
    }

    static DifferentialPair<Interval> fwdPow(DifferentialPair<Interval> dpa, int dpb) {
        Interval t0 = dpa.p.pow(dpb - 1);
        Interval t1 = t0.mul(dpa.d).mul(Interval(dpb));

        return diffPair(dpa.p.pow(dpb), t1);
    }

    [Differentiable]
    [ForwardDerivative(fwdPow)]
    // (a ^ 2) = 2 * a^1 * a'
    public Interval pow(int b) {
        float minB = pow(this.minVal, b);
        float maxB = pow(this.maxVal, b);

        return (b % 2 != 0) ? 
            Interval(minB, maxB) :
            Interval(
                this.contains(0.0) ? 0.0 : min(minB, maxB),
                max(minB, maxB)
            );
    }
}

#define MAKE_BINARY_OPERATORS(RT, OP_NAME, METHOD) \
    [Differentiable] public RT OP_NAME(Interval a, Interval b) { return a.METHOD(b); } \
    [Differentiable] public RT OP_NAME(float a, Interval b) { return Interval(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Interval a, float b) { return a.METHOD(Interval(b)); }

#define MAKE_UNARY_OPERATOR(OP_NAME, METHOD) \
    [Differentiable] public Interval OP_NAME(Interval a) { return a.METHOD(); } \

#define MAKE_UNARY_OPERATOR_POW(OP_NAME, METHOD) \
    [Differentiable] public Interval OP_NAME(Interval a, int b) { return a.METHOD(b); } \

MAKE_BINARY_OPERATORS(bool, operator==, equals)
MAKE_BINARY_OPERATORS(bool, operator<, lessThan)
MAKE_BINARY_OPERATORS(bool, operator<=, lessThanOrEquals)
MAKE_BINARY_OPERATORS(Interval, operator+, add)
MAKE_BINARY_OPERATORS(Interval, operator-, sub)
MAKE_BINARY_OPERATORS(Interval, operator*, mul)
MAKE_BINARY_OPERATORS(Interval, operator/, div)
MAKE_BINARY_OPERATORS(Interval, max, max)
MAKE_BINARY_OPERATORS(Interval, min, min)

MAKE_UNARY_OPERATOR(sqrt, sqrt)
MAKE_UNARY_OPERATOR(abs, abs)

MAKE_UNARY_OPERATOR_POW(pow, pow)
