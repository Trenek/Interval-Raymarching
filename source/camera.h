#include <vulkan/vulkan.h>
#include <cglm/cglm.h>

#include "cameraBuilder.h"

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
