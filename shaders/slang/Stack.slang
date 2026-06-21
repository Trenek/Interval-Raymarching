public struct Stack <T, let N : int> {
    public T stack[N];
    public int currentSize;

    public __init() {
        this.currentSize = 0;
    }

    [mutating]
    public T pop() {
        this.currentSize -= 1;
        return this.stack[this.currentSize];
    }

    public T top() {
        return this.stack[this.currentSize - 1];
    }

    public bool isEmpty() {
        return this.currentSize <= 0;
    }

    public bool isFull() {
        return this.currentSize == N - 1;
    }

    [mutating]
    public void push(T val) {
        if (false == isFull()) {
            this.stack[this.currentSize] = val;
            this.currentSize += 1;
        }
    }

    public static int getMaxSize() {
        return N;
    }
};
