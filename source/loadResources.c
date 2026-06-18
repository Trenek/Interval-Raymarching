#include <cglm/cglm.h>

#include "bufferObj.h"
#include "engineCore.h"
#include "imageObj.h"
#include "state.h"
#include "texture.h"

#include "model.h"
#include "entity.h"
#include "rectangleBuilder.h"
#include "defaultInstance.h"
#include "defaultCamera.h"

#include "renderPassCore.h"

#include "descriptorSetLayoutObj.h"
#include "graphicsPipelineLayout.h"
#include "graphicsPipelineObj.h"

#include "rectangle.h"

#include "screenEnum.h"
#include "camera.h"

static void addModelData(struct EngineCore *this) {
    struct ResourceManager *modelData = calloc(1, sizeof(struct ResourceManager));

    addResource(modelData, MODEL_1, loadModel("model.scr", &this->graphics), destroyActualModel);

    addResource(&this->resource, MODEL, modelData, cleanupResourceManager);
}

static void addRenderPassCoreData(struct EngineCore *this) {
    struct ResourceManager *renderPassCoreData = calloc(1, sizeof(struct ResourceManager));

    addResource(renderPassCoreData, RENDER_PASS_CLEAN, createRenderPassCore((struct renderPassCoreBuilder) {
        .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
        .initLayout = VK_IMAGE_LAYOUT_UNDEFINED
    }, &this->graphics), freeRenderPassCore);
    addResource(renderPassCoreData, RENDER_PASS_STAY, createRenderPassCore((struct renderPassCoreBuilder) {
        .loadOp = VK_ATTACHMENT_LOAD_OP_LOAD,
        .initLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
    }, &this->graphics), freeRenderPassCore);

    addResource(&this->resource, RENDER_PASS, renderPassCoreData, cleanupResourceManager);
}

static void addObjectLayout(struct EngineCore *this) {
    struct ResourceManager *objectLayoutData = calloc(1, sizeof(struct ResourceManager));

    addResource(objectLayoutData, OBJECT_LAYOUT_OBJECT,
        defaultScreenDescriptorSetLayout(this->graphics.device),
        destroyDescriptorSetLayout
    );
    addResource(objectLayoutData, OBJECT_LAYOUT_CAMERA, 
        defaultCameraDescriptorSetLayout(this->graphics.device),
        destroyDescriptorSetLayout
    );

    addResource(objectLayoutData, OBJECT_LAYOUT_COMPUTE, createDescriptorSetLayoutObj(1, (VkDescriptorSetLayoutBinding[]) {
        [0] = {
            .binding = 0,
            .descriptorCount = 1,
            .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
            .pImmutableSamplers = NULL,
            .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT
        }
    }, this->graphics.device), destroyDescriptorSetLayout);

    addResource(objectLayoutData, OBJECT_LAYOUT_TEXTURE, createDescriptorSetLayoutObj(1, (VkDescriptorSetLayoutBinding[]) {
        [0] = {
            .binding = 0,
            .descriptorCount = 1,
            .descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .pImmutableSamplers = NULL,
            .stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT
        }
    }, this->graphics.device), destroyDescriptorSetLayout);

    addResource(&this->resource, OBJECT_LAYOUT, objectLayoutData, cleanupResourceManager);
}

static void createGraphicPipelineLayouts(struct EngineCore *this) {
    struct ResourceManager *graphicPipelinesData = calloc(1, sizeof(struct ResourceManager));

    struct ResourceManager *objectLayoutManager = findResource(&this->resource, OBJECT_LAYOUT);

    struct DescriptorSetLayout *cameraLayout = findResource(objectLayoutManager, OBJECT_LAYOUT_CAMERA);
    struct DescriptorSetLayout *textureLayout = findResource(objectLayoutManager, OBJECT_LAYOUT_TEXTURE);
    struct DescriptorSetLayout *computeLayout = findResource(objectLayoutManager, OBJECT_LAYOUT_COMPUTE);

    addResource(graphicPipelinesData, PIPELINE_LAYOUT_GRAPHICS, createPipelineLayout((struct PipelineLayoutBuilder) {
        .descriptorSetLayout = (VkDescriptorSetLayout []){
            textureLayout->descriptorSetLayout,
        },
        .qDescriptorSetLayout = 1,
        .debugName = "Uklad Potoku Graficznego",
    }, &this->graphics), destroyPipelineLayoutObj);
    addResource(graphicPipelinesData, PIPELINE_LAYOUT_COMPUTE, createPipelineLayout((struct PipelineLayoutBuilder) {
        .descriptorSetLayout = (VkDescriptorSetLayout []){
            computeLayout->descriptorSetLayout,
            cameraLayout->descriptorSetLayout,
        },
        .qDescriptorSetLayout = 2,
        .debugName = "Uklad Potoku Obliczeniowego",
    }, &this->graphics), destroyPipelineLayoutObj);

    addResource(&this->resource, GRAPHIC_PIPELINE_LAYOUTS, graphicPipelinesData, cleanupResourceManager);
}

static void createGraphicPipelines(struct EngineCore *this) {
    struct ResourceManager *graphicPipelinesData = calloc(1, sizeof(struct ResourceManager));
    struct ResourceManager *renderPassCoreData = findResource(&this->resource, RENDER_PASS);
    struct ResourceManager *pipelineLayoutData = findResource(&this->resource, GRAPHIC_PIPELINE_LAYOUTS);

    struct PipelineLayout *graphicsPipelineLayout = findResource(pipelineLayoutData, PIPELINE_LAYOUT_GRAPHICS);
    struct PipelineLayout *computePipelineLayout = findResource(pipelineLayoutData, PIPELINE_LAYOUT_COMPUTE);

    struct renderPassCore *renderPass[] = {
        findResource(renderPassCoreData, RENDER_PASS_CLEAN),
        findResource(renderPassCoreData, RENDER_PASS_STAY)
    };
    size_t qRenderPass = sizeof(renderPass) / sizeof(struct renderPassCore *);

    addResource(graphicPipelinesData, GRAPHIC_PIPELINES_1, createGraphicsPipelineObj((struct GraphicsPipelineBuilder) {
        .pipelineLayout = graphicsPipelineLayout->pipelineLayout,
        .qRenderPassCore = qRenderPass,
        .renderPassCore = renderPass,
        .vertexShader = "shaders/screenV.spv",
        .fragmentShader = "shaders/screenF.spv",
        .minDepth = 0.0f,
        .maxDepth = 1.0f,
        .topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,

        .vert = defaultRectVert(),
        .operation = VK_COMPARE_OP_LESS,
        .cullFlags = VK_CULL_MODE_BACK_BIT,
        .debugName = "Potok Graficzny",
    }, &this->graphics), destroyPipelineObj);

    addResource(graphicPipelinesData, COMPUTE_PIPELINE, createComputePipelineObj((struct ComputePipelineBuilder) {
        .computeShader = "shaders/slangRaymarch.spv",
        .pipelineLayout = computePipelineLayout->pipelineLayout,
        .debugName = "Potok Obliczeniowy",
    }, &this->graphics), destroyPipelineObj);

    addResource(&this->resource, GRAPHIC_PIPELINES, graphicPipelinesData, cleanupResourceManager);
}

static void addEntities(struct EngineCore *this) {
    struct ResourceManager *entityData = calloc(1, sizeof(struct ResourceManager));
    struct ResourceManager *modelData = findResource(&this->resource, MODEL);

    struct DescriptorSetLayout *objectLayout = findResource(findResource(&this->resource, OBJECT_LAYOUT), OBJECT_LAYOUT_OBJECT);

    addResource(entityData, ENTITIES_1, createRec((struct RecBuilder) {
        .instanceCount = 1,
        .modelData = findResource(modelData, MODEL_1),
        .objectLayout = objectLayout->descriptorSetLayout,

        .instance = defaultInstance(),
    }, &this->graphics), destroyEntity);

    addResource(&this->resource, ENTITIES, entityData, cleanupResourceManager);
}

static void createTextures(struct EngineCore *this) {
    struct DescriptorSetLayout *textureLayoutComp = findResource(findResource(&this->resource, OBJECT_LAYOUT), OBJECT_LAYOUT_COMPUTE);
    struct DescriptorSetLayout *textureLayoutFrag = findResource(findResource(&this->resource, OBJECT_LAYOUT), OBJECT_LAYOUT_TEXTURE);

    addResource(&this->resource, WRITE_TEXTURE, createImageObj((struct ImageBuilder) {
        .extent = this->graphics.swapChain.extent,
        .mipLevels = 1,
        .arrayLayers = 1,
        .format = VK_FORMAT_R8G8B8A8_UNORM,
        .usage = VK_IMAGE_USAGE_STORAGE_BIT |
                 VK_IMAGE_USAGE_SAMPLED_BIT
    }, &this->graphics), destroyImageObj);
    struct ImageObj *image = findResource(&this->resource, WRITE_TEXTURE);
    completeImageObj(image, &this->graphics);

    createImageSampler(image, this->graphics.device, this->graphics.physicalDevice, (struct SamplerBuilder) {
        .magFilter = VK_FILTER_LINEAR,
        .asinotropyEnable = VK_FALSE,
        .mipMapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .mipLevels = 0.0,
    });

    addResource(&this->resource, DESCRIPTOR_COMP, createDescriptorSetsObj(&this->graphics, &(struct DescriptorObjBuilder) {
        .layout = textureLayoutComp->descriptorSetLayout,
        .qDescriptorPoolSize = 1,
        .descriptorPoolSize = (VkDescriptorPoolSize []) {
            {
                .type = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                .descriptorCount = MAX_FRAMES_IN_FLIGHT
            },
        }
    }), destroyDescriptorSets);
    addResource(&this->resource, DESCRIPTOR_FRAG, createDescriptorSetsObj(&this->graphics, &(struct DescriptorObjBuilder) {
        .layout = textureLayoutFrag->descriptorSetLayout,
        .qDescriptorPoolSize = 1,
        .descriptorPoolSize = (VkDescriptorPoolSize []) {
            {
                .type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = MAX_FRAMES_IN_FLIGHT
            },
        }
    }), destroyDescriptorSets);

    struct DescriptorObj *descriptorComp = findResource(&this->resource, DESCRIPTOR_COMP);
    struct DescriptorObj *descriptorFrag = findResource(&this->resource, DESCRIPTOR_FRAG);

    bindImagesToDescriptorSets(descriptorFrag->descriptorSets, this->graphics.device, (struct ImageBinder) {
        .qImage = 1,
        .image = &image,
        .layout = VK_IMAGE_LAYOUT_GENERAL,
        .descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    });

    bindImagesToDescriptorSets(descriptorComp->descriptorSets, this->graphics.device, (struct ImageBinder) {
        .qImage = 1,
        .image = &image,
        .layout = VK_IMAGE_LAYOUT_GENERAL,
        .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
    });
    struct DescriptorSetLayout *cameraLayout = findResource(findResource(&this->resource, OBJECT_LAYOUT), OBJECT_LAYOUT_CAMERA);

    // .camera = myCameraInfo(&(struct MyBuffer) {
    //     .iResolution = { 
    //         engine->graphics.swapChain.extent.width, 
    //         engine->graphics.swapChain.extent.height, 
    //     },
    //     .iTime = 0,
    //     .iTimeDelta = 0
    // }),
    // .cameraDescriptorSetLayout = cameraLayout->descriptorSetLayout,
    addResource(&this->resource, CAMERA_BUFFER, createBufferObj((struct BufferBuilder) {
        .bufferUsage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
        .memoryProperty = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                          VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        .size = sizeof(struct MyBuffer),
        .repetitions = MAX_FRAMES_IN_FLIGHT
    }, &this->graphics), destroyBufferObj);
    struct BufferObj *cameraBuffer = findResource(&this->resource, CAMERA_BUFFER);

    void *cameraMapped[2] = {};
    vkMapMemory(this->graphics.device, cameraBuffer->memory, 0, cameraBuffer->range, 0, cameraMapped);

    for (size_t i = 1; i < MAX_FRAMES_IN_FLIGHT; i += 1) {
        cameraMapped[i] = (char *)cameraMapped[i - 1] + cameraBuffer->range;
    }

    vkUnmapMemory(this->graphics.device, cameraBuffer->memory);

    addResource(&this->resource, CAMERA_DESCRIPTOR, createDescriptorSetsObj(&this->graphics, &(struct DescriptorObjBuilder) {
        .layout = cameraLayout->descriptorSetLayout,
        .qDescriptorPoolSize = 1,
        .descriptorPoolSize = (VkDescriptorPoolSize []) {
            {
                .type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .descriptorCount = MAX_FRAMES_IN_FLIGHT
            }
        },
    }), destroyDescriptorSets);
    struct DescriptorObj *cameraDescriptor = findResource(&this->resource, CAMERA_DESCRIPTOR);

    bindBuffersToDescriptorSets(
        cameraDescriptor, 
        this->graphics.device, 
        1, 
        (VkBuffer []) { cameraBuffer->buffer }, 
        (size_t []) { cameraBuffer->range }, 
        (bool []) { false },
        VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER
    );
}

void loadResources(struct EngineCore *engine, enum state *state) {
    addModelData(engine);

    addRenderPassCoreData(engine);
    addObjectLayout(engine);

    createTextures(engine);
    createGraphicPipelineLayouts(engine);
    createGraphicPipelines(engine);
    addEntities(engine);

    state[0] = LOAD_TEST;
}
