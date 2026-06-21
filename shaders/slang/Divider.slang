module Divider;

import Intervals;
import Stack;

public interface IDivider {
    public __init(float epsilon, float maxDistance);
    public __init(float epsilon, Interval initInterval);

    bool lastingCondition();
    bool acceptanceCondition();
    [[mutating]] Interval getNext();
    [[mutating]] void goDown();
    [[mutating]] void goUp();
}

public struct StackDivider : IDivider {
    Stack<Interval, 64> stack;
    Interval curr;
    float epsilon;

    public __init(float epsilon, float maxDistance) {
        this.curr = Interval(0);
        this.epsilon = epsilon;
        stack.push(Interval(0, maxDistance));
    }

    public __init(float epsilon, Interval initInterval) {
        this.curr = Interval(0);
        this.epsilon = epsilon;
        stack.push(initInterval);
    }

    [[mutating]]
    Interval getNext() {
        return curr = stack.pop();
    }

    bool lastingCondition() {
        return false == stack.isEmpty() && false == stack.isFull();
    }

    [[mutating]]
    void goDown() {
        Interval t = this.curr;
        float mid = t.mid();

        stack.push(Interval(mid, t.maxVal));
        stack.push(Interval(t.minVal, mid));
    }

    void goUp() {}

    bool acceptanceCondition() {
        return this.curr.length() < this.epsilon;
    }
}

public struct IntDivider : IDivider {
    uint32_t eps;
    uint32_t h = 1;
    uint32_t l = 1;

    float epsilon;
    float maxDistance;
    float start;

    public __init(float epsilon, float maxDistance) {
        this.epsilon = epsilon;
        this.maxDistance = maxDistance;
        this.start = 0;

        this.eps = uint32_t(floor(log2(maxDistance / epsilon)));
    }

    public __init(float epsilon, Interval initInterval) {
        this.epsilon = epsilon;
        this.maxDistance = initInterval.length();
        this.start = initInterval.minVal;

        this.eps = uint32_t(floor(log2(maxDistance / epsilon)));
    }

    Interval getNext() {
        return Interval(this.start + float2(
            (this.h - 1) * this.maxDistance / this.l, 
            this.h * this.maxDistance / this.l
        ));
    }

    bool lastingCondition() {
        return this.h <= this.l;
    }

    [[mutating]]
    void goDown() {
        this.h <<= 1;
        this.l <<= 1;

        this.h -= 1;
    }

    [[mutating]]
    void goUp() {
        uint shift = firstbitlow(h & (-h));

        this.h >>= shift;
        this.l >>= shift;

        this.h += 1;
    }

    bool acceptanceCondition() {
        return firstbithigh(this.l) >= this.eps;
    }
}

public struct FloatDivider : IDivider {
    int dlast;
    int d;

    float2 t;
    float tincr;

    float start;
    float maxDistance;

    public __init(float epsilon, float maxDistance) {
        this.dlast = int(round(log2(maxDistance / epsilon)));
        this.d = 0;
        this.start = 0;
        this.maxDistance = maxDistance;

        this.t = float2(0.0f, 1.0f);
        this.tincr = 0.5f;
    }

    public __init(float epsilon, Interval initInterval) {
        this.maxDistance = initInterval.length();
        this.dlast = int(round(log2(maxDistance / epsilon)));
        this.d = 0;
        this.start = initInterval.minVal;

        this.t = float2(0.0f, 1.0f);
        this.tincr = 0.5f;
    }

    Interval getNext() {
        return Interval(this.start + this.t * this.maxDistance);
    }

    bool lastingCondition() {
        return d != -1;
    }

    [[mutating]]
    void goDown() {
        this.d += 1;
        this.tincr *= 0.5f;
        this.t.y = this.t.x + tincr;
    }

    [[mutating]]
    void goUp() {
        t.x = t.y;

        float fp = frac(0.5f * t.x / tincr);

        if (fp < 1e-8) {
            for (int j = 0; j <= dlast; j += 1) {
                tincr *= 2;
                d--;
                fp = frac(0.5 * t.x / tincr);
                if (d == -1 || fp > 1e-8) break;
            }
        }
        this.t.y = this.t.x + tincr;
    }

    bool acceptanceCondition() {
        return this.d == this.dlast;
    }
}

