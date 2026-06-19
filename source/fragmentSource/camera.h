#include <vulkan/vulkan.h>
#include <cglm/cglm.h>

#include "cameraBuilder.h"
#include "descriptorSetLayoutObj.h"

struct MyBuffer {
    vec2 iResolution;
    float iTime;
    float iTimeDelta;
};

void updateMyBuffer(void *uniformBuffersMapped, VkExtent2D, void *cameraPtr);

static inline struct cameraBuilder myCameraInfo(const struct MyBuffer * const restrict data) {
    return (struct cameraBuilder) {
        .updateBuffer = updateMyBuffer,
        .size = sizeof(struct MyBuffer),
        .bufferSize = sizeof(struct MyBuffer),
        .mapped = data
    };
}

static inline struct DescriptorSetLayout *myCameraDescriptorSetLayout(VkDevice device) {
    return createDescriptorSetLayoutObj(1, (VkDescriptorSetLayoutBinding []){
            {
                .binding = 0,
                .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                .descriptorCount = 1,
                .stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT,
                .pImmutableSamplers = NULL
            }
        },
        device
    );
}
