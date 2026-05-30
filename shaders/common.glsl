bool between(float a, float min, float max) {
    return a >= min && a <= max;
}

#define prepareScene(x) \
    vec3 getNormal##x(vec3 p) { \
        float d = x(p); \
        vec2 e = vec2(0.00001, 0.0); \
        vec3 n = d - vec3( \
            x(p - e.xyy), \
            x(p - e.yxy), \
            x(p - e.yyx) \
        ); \
        return normalize(n); \
    } \
    \
    float rayMarch##x(vec3 ro, vec3 rd) { \
        float t = 0; \
        float distanceTraveled = 1; \
        \
        for (int i = 0; between(distanceTraveled, 0.001, 10000) && i < 80; i += 1) { \
            t += distanceTraveled = x(ro + rd * t); \
        } \
        \
        return t; \
    }
#define getNormal(x, y) getNormal##x(y)
#define getRayMarch(x, y, z) rayMarch##x(y, z)

mat3 rot3D(vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    axis = normalize(axis);

    return mat3(
        oc * axis.x * axis.x + c,
        oc * axis.x * axis.y - axis.z * s,
        oc * axis.x * axis.z + axis.y * s,
        oc * axis.y * axis.x + axis.z * s,
        oc * axis.y * axis.y + c,
        oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s,
        oc * axis.z * axis.y + axis.x * s,
        oc * axis.z * axis.z + c
    );
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

float getLightning(vec3 normal, vec3 lightDirection) {
    float diffuse = clamp(dot(normal, lightDirection), 0.0, 1.0);
    
    return diffuse + 0.15;
}
