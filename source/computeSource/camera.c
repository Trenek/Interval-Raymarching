#include <string.h>
#include <vulkan/vulkan.h>

#include "camera.h"

void updateMyBuffer(void *uniformBuffersMapped, VkExtent2D, void *cameraPtr) {
    memcpy(uniformBuffersMapped, cameraPtr, sizeof(struct MyBuffer));
}
