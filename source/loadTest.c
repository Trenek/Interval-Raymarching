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
#include "camera.h"

static void createScreens(struct EngineCore *engine) {
    struct ResourceManager *entityData = findResource(&engine->resource, ENTITIES);
    struct ResourceManager *graphicPipelineData = findResource(&engine->resource, GRAPHIC_PIPELINES);

    struct Pipeline *pipe[] = { 
        findResource(graphicPipelineData, GRAPHIC_PIPELINES_1),
    };
    struct DescriptorSetLayout *cameraLayout = findResource(findResource(&engine->resource, OBJECT_LAYOUT), OBJECT_LAYOUT_CAMERA);

    struct Entity *entity[] = {
        findResource(entityData, ENTITIES_1)
    };
    
    struct ResourceManager *screenData = calloc(1, sizeof(struct ResourceManager));

    struct ResourceManager *renderPassCoreData = findResource(&engine->resource, RENDER_PASS);
    struct renderPassCore *clean = findResource(renderPassCoreData, RENDER_PASS_CLEAN);

    addResource(screenData, SCREEN_1,
        createRenderPassObj((struct renderPassBuilder){
            .coordinates = { 0.0, 0.0, 1.0, 1.0 },
            .color = { 0.5f, 0.5f, 0.5f, 1.0f },
            .renderPass = clean,
            .data = (struct pipelineConnectionBuilder[]) {
                {
                    .pipe = pipe[0],
                    .entity = (struct Entity *[]) {
                        entity[0],
                    },
                    .qEntity = 1
                },
            },
            .qData = 1,
            .camera = myCameraInfo(&(struct MyBuffer) {
                .iResolution = { 
                    engine->graphics.swapChain.extent.width, 
                    engine->graphics.swapChain.extent.height, 
                },
                .iTime = 0,
                .iTimeDelta = 0
            }),
            .cameraDescriptorSetLayout = cameraLayout->descriptorSetLayout,
            .drawRenderPass = drawRenderPass,
        }, &engine->graphics),
        destroyRenderPassObj
    );

    addResource(&engine->resource, SCREEN, screenData, cleanupResourceManager);
}

static void createCommandQueues(struct EngineCore *engine) {
    struct ResourceManager *queueData = calloc(1, sizeof(struct ResourceManager));

    addResource(queueData, COMMAND_QUEUE_GRAPHICS, createCommandQueue(&engine->graphics, "Graphics Buffer"), destroyCommandQueue);

    addResource(&engine->resource, COMMAND_QUEUE, queueData, cleanupResourceManager);
}

void loadTest(struct EngineCore *engine, enum state *state) {
    createScreens(engine);
    createCommandQueues(engine);

    state[0] = TEST;
}
