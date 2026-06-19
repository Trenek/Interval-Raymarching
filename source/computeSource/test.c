#include <cglm/cglm.h>
#include <string.h>

#include "engineCore.h"
#include "state.h"

#include "defaultCamera.h"

#include "entity.h"

#include "renderPassObj.h"

#include "screenEnum.h"
#include "rectangle.h"
#include "commandQueue.h"
#include "computePass.h"
#include "windowManager.h"
#include "graphicsPipelineObj.h"
#include "camera.h"
#include "bufferObj.h"

int compare(const void *a, const void *b) {
    return *(float *)a - *(float *)b;
}

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

    struct Pipeline *pipeline = findResource(findResource(&engine->resource, GRAPHIC_PIPELINES), COMPUTE_PIPELINE);
    struct DescriptorObj *descriptorComp = findResource(&engine->resource, DESCRIPTOR_COMP);
    struct DescriptorObj *cameraDescriptor = findResource(&engine->resource, CAMERA_DESCRIPTOR);
    struct ComputePass computePass[] = {
        {
            .pipeline = pipeline->pipeline->pipeline,
            .pipelineLayout = pipeline->pipelineLayout,

            .qDescriptor = 2,
            .descriptor = (VkDescriptorSet*[]) {
                descriptorComp->descriptorSets,
                cameraDescriptor->descriptorSets,
            },
            .groupCountX = (engine->graphics.swapChain.extent.width + 15) / 16,
            .groupCountY = (engine->graphics.swapChain.extent.height + 15) / 16,
        }
    };
    size_t qComputePass = sizeof(computePass) / sizeof(struct ComputePass);

    struct CommandQueue *graphics = findResource(commandQueue, COMMAND_QUEUE_GRAPHICS);
    struct CommandQueue *compute = findResource(commandQueue, COMMAND_QUEUE_COMPUTE);
    struct CommandQueue *queue[] = {
        graphics,
        compute,
    };
    size_t qQueue = sizeof(queue) / sizeof(struct CommandQueue *);

    bool running = true;

    struct BufferObj *cameraBuffer = findResource(&engine->resource, CAMERA_BUFFER);
    void *cameraMapped[2] = {};

    vkMapMemory(engine->graphics.device, cameraBuffer->memory, 0, cameraBuffer->range, 0, cameraMapped);

    for (size_t i = 1; i < MAX_FRAMES_IN_FLIGHT; i += 1) {
        cameraMapped[i] = (char *)cameraMapped[i - 1] + cameraBuffer->range;
    }
    struct MyBuffer my = {};

    VkQueryPoolCreateInfo queryPoolInfo = {
        .sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO,
        .queryType = VK_QUERY_TYPE_TIMESTAMP,
        .queryCount = 2
    };
    VkQueryPool queryPool;
    vkCreateQueryPool(engine->graphics.device, &queryPoolInfo, NULL, &queryPool);

    VkPhysicalDeviceProperties deviceProperties;
    vkGetPhysicalDeviceProperties(engine->graphics.physicalDevice, &deviceProperties);

    double res = 0;
    int num = 0;
    float times[10'000] = {};
    size_t maxTime = 0;

    while (TEST == state[0] && !shouldWindowClose(engine->window)) {
        if (isKeyJustPressed(&engine->window, GLFW_KEY_SPACE)) {
            running = !running;
        }
        if (running) {
            my.iTime += my.iTimeDelta;
            my.iTimeDelta = engine->deltaTime.deltaTime;
        }
        my.iResolution[0] = engine->graphics.swapChain.extent.width;
        my.iResolution[1] = engine->graphics.swapChain.extent.height;

        memcpy(cameraMapped[engine->currentFrame], &my, sizeof(struct MyBuffer));

        engineUpdate(engine, qRenderPass, renderPass);
        
        aquireNextImage(engine, graphics->inFlightFence, graphics->semaphore);

        queueComputeQP(compute, engine, qComputePass, computePass, queryPool);
        queueDraw(graphics, engine, qRenderPass, renderPass, 2, 
            (VkSemaphore []) {
                compute->semaphore[engine->currentFrame],
                graphics->semaphore[engine->currentFrame],
            },
            (VkPipelineStageFlags []) {
                VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            }
        );

        presentFrame(engine, qRenderPassArr, renderPassArr, qQueue, queue);

        if (isKeyJustPressed(&engine->window, GLFW_KEY_R)) {
            state[0] = RELOAD;
        }

        uint64_t timestamps[2] = {};
        vkGetQueryPoolResults(
            engine->graphics.device, 
            queryPool, 
            0, 2, 
            sizeof(timestamps), 
            timestamps, 
            sizeof(uint64_t), 
            VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT
        );

        double nanoseconds = (double)(timestamps[1] - timestamps[0]) * (double)deviceProperties.limits.timestampPeriod;
        double milliseconds = nanoseconds / 1000000.0;
        if (maxTime < 10'000) {
            maxTime[times] = milliseconds;
            maxTime += 1;
            qsort(times, maxTime, sizeof(float), compare);
        }

        res += milliseconds;
        num += 1;

        printf("\r%f ms   median %f ms       ", res / num, times[maxTime / 2]);

    }
}
