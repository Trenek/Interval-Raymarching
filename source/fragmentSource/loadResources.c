#include <cglm/cglm.h>

#include "engineCore.h"
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
#include "camera.h"

#include "rectangle.h"

#include "screenEnum.h"

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
        myCameraDescriptorSetLayout(this->graphics.device),
        destroyDescriptorSetLayout
    );

    addResource(&this->resource, OBJECT_LAYOUT, objectLayoutData, cleanupResourceManager);
}

static void createGraphicPipelineLayouts(struct EngineCore *this) {
    struct ResourceManager *graphicPipelinesData = calloc(1, sizeof(struct ResourceManager));

    struct DescriptorSetLayout *cameraLayout = findResource(findResource(&this->resource, OBJECT_LAYOUT), OBJECT_LAYOUT_CAMERA);

    addResource(graphicPipelinesData, GRAPHIC_PIPELINE_LAYOUT_1, createPipelineLayout((struct PipelineLayoutBuilder) {
        .descriptorSetLayout = (VkDescriptorSetLayout []){
            cameraLayout->descriptorSetLayout,
        },
        .qDescriptorSetLayout = 1,
    }, &this->graphics), destroyPipelineLayoutObj);

    addResource(&this->resource, GRAPHIC_PIPELINE_LAYOUTS, graphicPipelinesData, cleanupResourceManager);
}

static void createGraphicPipelines(struct EngineCore *this) {
    struct ResourceManager *graphicPipelinesData = calloc(1, sizeof(struct ResourceManager));
    struct ResourceManager *renderPassCoreData = findResource(&this->resource, RENDER_PASS);

    struct PipelineLayout *pipelineLayout = findResource(findResource(&this->resource, GRAPHIC_PIPELINE_LAYOUTS), GRAPHIC_PIPELINE_LAYOUT_1);

    struct renderPassCore *renderPass[] = {
        findResource(renderPassCoreData, RENDER_PASS_CLEAN),
        findResource(renderPassCoreData, RENDER_PASS_STAY)
    };
    size_t qRenderPass = sizeof(renderPass) / sizeof(struct renderPassCore *);

    addResource(graphicPipelinesData, GRAPHIC_PIPELINES_1, createGraphicsPipelineObj((struct GraphicsPipelineBuilder) {
        .pipelineLayout = pipelineLayout->pipelineLayout,
        .qRenderPassCore = qRenderPass,
        .renderPassCore = renderPass,
        .vertexShader = "../../shaders/screenV.spv",
        .fragmentShader = "../../shaders/slangRaymarchF.spv",
        .minDepth = 0.0f,
        .maxDepth = 1.0f,
        .topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,

        .vert = defaultRectVert(),
        .operation = VK_COMPARE_OP_LESS,
        .cullFlags = VK_CULL_MODE_BACK_BIT,
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

void loadResources(struct EngineCore *engine, enum state *state) {
    addModelData(engine);

    addRenderPassCoreData(engine);
    addObjectLayout(engine);

    createGraphicPipelineLayouts(engine);
    createGraphicPipelines(engine);
    addEntities(engine);

    state[0] = LOAD_TEST;
}
