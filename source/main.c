#include "engineCore.h"

#include "state.h"

void reload(struct EngineCore *engine, enum state *state) {
    vkDeviceWaitIdle(engine->graphics.device);
    cleanupResourcesOrg(&engine->resource);
    engine->resource = (struct ResourceManager) {};

    state[0] = LOAD_RESOURCES;
}

int main() {
    struct EngineCore engine = setup("Engine Tester", NULL);
    void (*const state[])(struct EngineCore *engine, enum state *state) = {
        [TEST] = test,
        [LOAD_TEST] = loadTest,
        [LOAD_RESOURCES] = loadResources,
        [RELOAD] = reload
    };

    enum state stateID[] = {
        LOAD_RESOURCES
    };

    do {
        state[stateID[0]](&engine, stateID);
    } while (stateID[0] != EXIT && !shouldWindowClose(engine.window));

    cleanup(engine);

    return 0;
}
