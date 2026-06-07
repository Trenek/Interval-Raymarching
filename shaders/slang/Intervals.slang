module Intervals;

public struct Interval : IDifferentiable, IArithmetic {
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

    [Differentiable]
    public bool contains(float a) {
        return this.minVal <= a && this.maxVal >= a;
    }

    [Differentiable]
    public bool contains(Interval a) {
        return this.minVal <= a.minVal && a.maxVal <= this.maxVal;
    }

    [Differentiable]
    public bool intersects(Interval a) {
        return this.minVal <= a.maxVal && a.minVal <= this.maxVal;
    }

    [Differentiable]
    public Interval intersection(Interval a) {
        return Interval(
            max(this.minVal, a.minVal),
            min(this.maxVal, a.maxVal)
        );
    }

    [Differentiable]
    public float mid() {
        return (this.maxVal - this.minVal) * 0.5 + this.minVal;
    }

    [Differentiable]
    public float length() {
        return this.maxVal - this.minVal;
    }

    [Differentiable]
    public bool equals(Interval a) {
        return this.minVal == a.minVal && this.maxVal == a.maxVal;
    }

    [Differentiable]
    public bool lessThan(Interval a) {
        return this.maxVal < a.minVal;
    }

    [Differentiable]
    public bool lessThanOrEquals(Interval a) {
        return this.maxVal <= a.maxVal;
    }

    [Differentiable]
    public Interval add(Interval b) {
        return Interval(this.minVal + b.minVal, this.maxVal + b.maxVal);
    }

    [Differentiable]
    public Interval sub(Interval b) {
        return Interval(this.minVal - b.maxVal, this.maxVal - b.minVal);
    }

    [Differentiable]
    public Interval mul(Interval b) {
        float a0 = this.minVal * b.minVal;
        float a1 = this.minVal * b.maxVal;
        float a2 = this.maxVal * b.minVal;
        float a3 = this.maxVal * b.maxVal;

        float minVal = min(min(a0, a1), min(a2, a3));
        float maxVal = max(max(a0, a1), max(a2, a3));

        return Interval(minVal, maxVal);
    }

    [Differentiable]
    public Interval div(Interval b) {
        return mul(Interval(1 / b.maxVal, 1 / b.minVal));
    }

    [Differentiable]
    public Interval mod(Interval b) {
        float m1 = this.minVal % b.minVal;
        float m2 = this.minVal % b.maxVal;
        float m3 = this.maxVal % b.minVal;
        float m4 = this.maxVal % b.maxVal;

        float minRes = min(min(m1, m2), min(m3, m4));
        float maxRes = max(max(m1, m2), max(m3, m4));

        if (this.maxVal - this.minVal >= b.maxVal) {
            return Interval(0.0f, b.maxVal);
        }

        return Interval(minRes, maxRes);
    }

    [Differentiable]
    public Interval neg() {
        return Interval(-this.maxVal, -this.minVal);
    }

    [Differentiable]
    public Interval operator-() {
        return neg();
    }
}

#define MAKE_OPERATORS(RT, OP_NAME, METHOD) \
    [Differentiable] public RT OP_NAME(Interval a, Interval b) { return a.METHOD(b); } \
    [Differentiable] public RT OP_NAME(float a, Interval b) { return Interval(a).METHOD(b); } \
    [Differentiable] public RT OP_NAME(Interval a, float b) { return a.METHOD(Interval(b)); }

MAKE_OPERATORS(bool, operator==, equals)
MAKE_OPERATORS(bool, operator<, lessThan)
MAKE_OPERATORS(bool, operator<=, lessThanOrEquals)
MAKE_OPERATORS(Interval, operator+, add)
MAKE_OPERATORS(Interval, operator-, sub)
MAKE_OPERATORS(Interval, operator*, mul)
MAKE_OPERATORS(Interval, operator/, div)
MAKE_OPERATORS(Interval, operator%, mod)

[Differentiable]
public Interval sqrt(Interval a) {
    return Interval(sqrt(a.minVal), sqrt(a.maxVal));
}

[Differentiable]
public Interval abs(Interval a) {
    float absMin = abs(a.minVal);
    float absMax = abs(a.maxVal);

    float actualMin = 0.0;
    if (false == a.contains(0.0)) {
        actualMin = min(absMin, absMax);
    }

    return Interval(actualMin, max(absMin, absMax));
}

[Differentiable]
public Interval pow(Interval a, int b) {
    float minB = pow(a.minVal, b);
    float maxB = pow(a.maxVal, b);

    return (b % 2 != 0) ? 
        Interval(minB, maxB) :
        Interval(
            (a.minVal <= 0.0 && a.maxVal >= 0.0) ? 0.0 : min(minB, maxB),
            max(minB, maxB)
        );
}

[Differentiable]
public Interval max(Interval a, Interval b) {
    return Interval(max(a.minVal, b.minVal), max(a.maxVal, b.maxVal));
}

[Differentiable]
public Interval max(Interval a, float b) {
    return Interval(max(a.minVal, b), max(a.maxVal, b));
}

[Differentiable]
public Interval min(Interval a, float b) {
    return Interval(min(a.minVal, b), min(a.maxVal, b));
}

[Differentiable]
public Interval min(Interval a, Interval b) {
    return Interval(min(a.minVal, b.minVal), min(a.maxVal, b.maxVal));
}
