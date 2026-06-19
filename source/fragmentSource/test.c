#include <cglm/cglm.h>

#include "engineCore.h"
#include "state.h"

#include "defaultCamera.h"

#include "entity.h"

#include "renderPassObj.h"

#include "screenEnum.h"
#include "rectangle.h"
#include "commandQueue.h"
#include "windowManager.h"
#include "camera.h"

void test(struct EngineCore *engine, enum state *state) {
    struct ResourceManager *screenData = findResource(&engine->resource, SCREEN);
    struct ResourceManager *renderPassCoreData = findResource(&engine->resource, RENDER_PASS);
    struct ResourceManager *commandQueue = findResource(&engine->resource, COMMAND_QUEUE);

    struct renderPassObj *renderPass[] = {
        findResource(screenData, SCREEN_1),
    };
    size_t qRenderPass = sizeof(renderPass) / sizeof(struct renderPassObj *);

    struct renderPassCore *renderPassArr[] = { 
        findResource(renderPassCoreData, RENDER_PASS_CLEAN),
        findResource(renderPassCoreData, RENDER_PASS_STAY)
    };
    size_t qRenderPassArr = sizeof(renderPassArr) / sizeof(struct renderPassCore *);

    struct CommandQueue *graphics = findResource(commandQueue, COMMAND_QUEUE_GRAPHICS);
    struct CommandQueue *queue[] = {
        graphics,
    };
    size_t qQueue = sizeof(queue) / sizeof(struct CommandQueue *);

    bool running = true;

    while (TEST == state[0] && !shouldWindowClose(engine->window)) {
        struct MyBuffer *my = renderPass[0]->camera;

        if (isKeyJustPressed(&engine->window, GLFW_KEY_SPACE)) {
            running = !running;
        }
        if (running) {
            my->iTime += my->iTimeDelta;
            my->iTimeDelta = engine->deltaTime.deltaTime;
        }
        my->iResolution[0] = engine->graphics.swapChain.extent.width;
        my->iResolution[1] = engine->graphics.swapChain.extent.height;

        engineUpdate(engine, qRenderPass, renderPass);
        
        aquireNextImage(engine, graphics->inFlightFence, graphics->semaphore);

        queueDraw(graphics, engine, qRenderPass, renderPass, 1, 
            (VkSemaphore []) {
                graphics->semaphore[engine->currentFrame],
            },
            (VkPipelineStageFlags []) {
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            }
        );

        presentFrame(engine, qRenderPassArr, renderPassArr, qQueue, queue);

        if (isKeyJustPressed(&engine->window, GLFW_KEY_R)) {
            state[0] = RELOAD;
        }
    }
}
