#include "engineCore.h"
#include "state.h"

#include "entity.h"
#include "texture.h"

#include "defaultInstance.h"
#include "descriptorSetLayoutObj.h"

#include "graphicsPipelineObj.h"
#include "renderPassObj.h"
#include "commandQueue.h"

#include "screenEnum.h"

static void createScreens(struct EngineCore *engine) {
    struct ResourceManager *entityData = findResource(&engine->resource, ENTITIES);
    struct ResourceManager *graphicPipelineData = findResource(&engine->resource, GRAPHIC_PIPELINES);

    struct Pipeline *pipe[] = { 
        findResource(graphicPipelineData, GRAPHIC_PIPELINES_1),
    };

    struct Entity *entity[] = {
        findResource(entityData, ENTITIES_1)
    };
    
    struct ResourceManager *screenData = calloc(1, sizeof(struct ResourceManager));

    struct ResourceManager *renderPassCoreData = findResource(&engine->resource, RENDER_PASS);
    struct renderPassCore *clean = findResource(renderPassCoreData, RENDER_PASS_CLEAN);

    struct DescriptorObj *descriptorFrag = findResource(&engine->resource, DESCRIPTOR_FRAG);

    addResource(screenData, SCREEN_1,
        createRenderPassObj((struct renderPassBuilder){
            .coordinates = { 0.0, 0.0, 1.0, 1.0 },
            .color = { 0.5f, 0.5f, 0.5f, 1.0f },
            .renderPass = clean,
            .data = (struct pipelineConnectionBuilder[]) {
                {
                    .texture = descriptorFrag->descriptorSets,
                    .pipe = pipe[0],
                    .entity = (struct Entity *[]) {
                        entity[0],
                    },
                    .qEntity = 1
                },
            },
            .qData = 1,
            .drawRenderPass = drawRenderPass,
        }, &engine->graphics),
        destroyRenderPassObj
    );

    addResource(&engine->resource, SCREEN, screenData, cleanupResourceManager);
}

static void createCommandQueues(struct EngineCore *engine) {
    struct ResourceManager *queueData = calloc(1, sizeof(struct ResourceManager));

    addResource(queueData, COMMAND_QUEUE_GRAPHICS, createCommandQueue(&engine->graphics, "Graphics Buffer"), destroyCommandQueue);
    addResource(queueData, COMMAND_QUEUE_COMPUTE, createCommandQueue(&engine->graphics, "Command Buffer"), destroyCommandQueue);

    addResource(&engine->resource, COMMAND_QUEUE, queueData, cleanupResourceManager);
}

void loadTest(struct EngineCore *engine, enum state *state) {
    createScreens(engine);
    createCommandQueues(engine);

    state[0] = TEST;
}
