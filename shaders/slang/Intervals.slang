module Intervals;

public struct Interval : IDifferentiable {
    public float2 i;

    public typealias This = Interval;

    public property float minVal { get { return this.i.x; } }
    public property float maxVal { get { return this.i.y; } }

    [Differentiable]
    public __init(int val) {
        this.i = float2(val, val);
    }

    [Differentiable]
    public __init(Interval val) {
        this.i = val.i;
    }

    [Differentiable]
    public __init(float min, float max) {
        this.i = float2(min, max);
    }

    [Differentiable]
    public __init(float val) {
        this.i = float2(val, val);
    }

    [Differentiable]
    public __init(float2 i) {
        this.i = i;
    }

    public bool contains(float a) {
        return this.i.x <= a && this.i.y >= a;
    }

    public bool contains(Interval a) {
        return this.i.x <= a.i.x && a.i.y <= this.i.y;
    }

    public bool intersects(Interval a) {
        return this.i.x <= a.i.y && a.i.x <= this.i.y;
    }

    public Interval intersection(Interval a) {
        return Interval(max(this.i.x, a.i.x), min(this.i.y, a.i.y));
    }

    public Interval sum(Interval a) {
        return Interval(min(this.i.x, a.i.x), max(this.i.y, a.i.y));
    }

    public float mid() {
        return (this.i.y + this.i.x) * 0.5;
    }

    public float length() {
        return this.i.y - this.i.x;
    }

    public bool equals(Interval a) {
        return all(this.i == a.i);
    }

    public bool lessThan(Interval a) {
        return this.i.y < a.i.x;
    }

    public bool lessThanOrEquals(Interval a) {
        return this.i.y <= a.i.y;
    }

    static DifferentialPair<Interval> fwdAdd(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        return diffPair(dpa.p.add(dpb.p), dpa.d.add(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdAdd)]
    // (a + b)' = a' + b'
    Interval add(Interval b) {
        return Interval(this.i + b.i);
    }

    static DifferentialPair<Interval> fwdSub(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        return diffPair(dpa.p.sub(dpb.p), dpa.d.sub(dpb.d));
    }

    [Differentiable]
    [ForwardDerivative(fwdSub)]
    // (a - b)' = a' - b'
    Interval sub(Interval b) {
        return Interval(this.i.xy - b.i.yx);
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
        float4 r = this.i.xxyy * b.i.xyxy;

        return Interval(
            min(min(min(r.x, r.y), r.z), r.w),
            max(max(max(r.x, r.y), r.z), r.w)
        );
    }

    [Differentiable]
    // (a / b)' = (a' * b - a * b') / b^2
    Interval div(Interval b) {
        return mul(Interval(1 / b.i.yx));
    }

    [Differentiable]
    public Interval neg() {
        return Interval(-this.i.yx);
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
        return Interval(sqrt(this.i.xy));
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
        float2 absI = abs(this.i);

        float actualMin = 0.0;
        if (false == this.contains(0.0)) {
            actualMin = min(absI.x, absI.y);
        }

        return Interval(actualMin, max(absI.x, absI.y));
    }

    static DifferentialPair<Interval> fwdMax(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        Interval der = (dpa.p.i.x > dpb.p.i.y) ? dpa.d :
                       (dpb.p.i.x > dpa.p.i.y) ? dpb.d :
                                                 dpa.d.sum(dpb.d); 

        return diffPair(max(dpa.p, dpb.p), der);
    }

    [Differentiable]
    [ForwardDerivative(fwdMax)]
    Interval max(Interval a) {
        return Interval(max(this.i, a.i));
    }

    static DifferentialPair<Interval> fwdMin(DifferentialPair<Interval> dpa, DifferentialPair<Interval> dpb) {
        Interval der = (dpa.p.i.x > dpb.p.i.y) ? dpb.d :
                       (dpb.p.i.x > dpa.p.i.y) ? dpa.d :
                                                 dpa.d.sum(dpb.d); 

        return diffPair(min(dpa.p, dpb.p), der);
    }

    [Differentiable]
    [ForwardDerivative(fwdMin)]
    public Interval min(Interval b) {
        return Interval(min(this.i, b.i));
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
        float2 powI = pow(this.i, b);

        return (b % 2 != 0) ? 
            Interval(powI) :
            Interval(
                this.contains(0.0) ? 0.0 : min(powI.x, powI.y),
                max(powI.x, powI.y)
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
