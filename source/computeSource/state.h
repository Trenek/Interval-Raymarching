#ifndef STATE_H
#define STATE_H

enum state {
    LOAD_RESOURCES,
    LOAD_TEST,
    TEST,
    RELOAD,
    STATE_Q,

    EXIT
};

struct EngineCore;

void test(struct EngineCore *engine, enum state *state);
void loadResources(struct EngineCore *engine, enum state *state);
void loadTest(struct EngineCore *engine, enum state *state);
#endif
