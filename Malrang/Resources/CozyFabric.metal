#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

kernel void cozyCopyColor(texture2d<float, access::read> source [[texture(0)]],
                          texture2d<float, access::write> target [[texture(1)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x < target.get_width() && p.y < target.get_height()) target.write(source.read(p), p);
}

kernel void cozyExtractLight(texture2d<float, access::read> source [[texture(0)]],
                             texture2d<float, access::write> target [[texture(1)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x >= target.get_width() || p.y >= target.get_height()) return;
    // Sample across each output pixel's footprint, including odd-sized render targets.
    float2 ratio = float2(source.get_width(), source.get_height()) / float2(target.get_width(), target.get_height());
    uint2 q = uint2((float2(p) + 0.25) * ratio);
    uint2 r = uint2((float2(p) + 0.75) * ratio);
    uint2 edge = uint2(source.get_width() - 1, source.get_height() - 1);
    float4 averaged = (source.read(min(q, edge)) + source.read(min(uint2(r.x, q.y), edge))
                     + source.read(min(uint2(q.x, r.y), edge)) + source.read(min(r, edge))) * 0.25;
    float3 color = averaged.rgb;
    float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));
    target.write(float4(color * smoothstep(0.62, 0.95, luminance), 1), p);
}

kernel void cozyCompositeLight(texture2d<float, access::read> source [[texture(0)]],
                               texture2d<float, access::sample> glow [[texture(1)]],
                               texture2d<float, access::write> target [[texture(2)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x >= source.get_width() || p.y >= source.get_height()) return;
    float4 color = source.read(p);
    constexpr sampler linearClamp(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = (float2(p) + 0.5) / float2(source.get_width(), source.get_height());
    color.rgb += glow.sample(linearClamp, uv).rgb * 0.075;
    target.write(color, p);
}

// Window-space fill stays attached to the room as furniture moves underneath it.
// Real lights still supply object shadows; this is the soft transmitted window glow.
[[visible]] void cozyFabric(realitykit::surface_parameters params) {
    constexpr sampler fabricSampler(coord::normalized, address::repeat, filter::linear, mip_filter::linear);
    float encodedSoftness = params.uniforms().custom_parameter().y;
    bool isWood = encodedSoftness < 0.0;
    bool isCutaway = params.uniforms().custom_parameter().x < 0.0;
    float softness = max(0.0, encodedSoftness);
    float encodedLight = params.uniforms().custom_parameter().w;
    bool isFiberMesh = encodedLight < 0.0;
    half3 tint = half3(params.material_constants().base_color_tint());
    half3 fiber = half3(0.92h);
    float3 surfaceNormal = float3(0.0, 0.0, 1.0);
    // Fiber triangles previously sampled seven textures and computed triplanar
    // derivatives, then discarded every result. Keep exactly the same constant
    // fiber color/normal and only sample fabric on the underlying surface.
    if (isWood && !isFiberMesh) {
        float3 local = params.geometry().model_position() * abs(params.uniforms().custom_parameter().x);
        float3 n = abs(normalize(cross(dfdx(local), dfdy(local))));
        float2 uv = n.y > max(n.x, n.z) ? local.zx : (n.x > n.z ? local.zy : local.xy);
        fiber = params.textures().base_color().sample(fabricSampler, uv * float2(0.18, 1.0)).rgb;
    } else if (!isFiberMesh) {
        float3 local = params.geometry().model_position() * abs(params.uniforms().custom_parameter().x);
        // Derive model-space projection weights, including rotated furniture.
        float3 n = abs(normalize(cross(dfdx(local), dfdy(local))));
        float3 weights = pow(n, float3(4.0));
        weights /= max(0.0001, weights.x + weights.y + weights.z);
        fiber = params.textures().base_color().sample(fabricSampler, local.yz).rgb * half(weights.x)
            + params.textures().base_color().sample(fabricSampler, local.xz).rgb * half(weights.y)
            + params.textures().base_color().sample(fabricSampler, local.xy).rgb * half(weights.z);
        float2 uv = n.y > max(n.x, n.z) ? local.xz : (n.x > n.z ? local.yz : local.xy);
        half3 fleece = clamp((fiber - 0.90h) * 1.85h + 0.91h, 0.75h, 1.0h);
        fiber = mix(fiber, fleece, half(softness));
        // A second, lower-frequency layer gives wool small tufts instead of uniform grain.
        half3 tufts = params.textures().base_color().sample(fabricSampler, local.yz * 0.43).rgb * half(weights.x)
            + params.textures().base_color().sample(fabricSampler, local.xz * 0.43).rgb * half(weights.y)
            + params.textures().base_color().sample(fabricSampler, local.xy * 0.43).rgb * half(weights.z);
        fiber *= clamp(1.0h + (tufts - 0.92h) * half(softness * 1.8), 0.92h, 1.04h);
        float3 detail = float3(realitykit::unpack_normal(params.textures().normal().sample(fabricSampler, uv).rgb));
        surfaceNormal = normalize(float3(detail.xy * mix(0.20, 0.80, softness), detail.z));
    }
    float daylight = isFiberMesh ? -encodedLight - 1.0 : encodedLight;
    half3 daylightTint = params.textures().custom().sample(fabricSampler, float2(0.5)).rgb;
    // The open dollhouse receives neutral studio fill in the reference. Retain
    // time-of-day color, with less amber spill than the enclosed room.
    if (isCutaway) daylightTint = mix(daylightTint, half3(1.0h), 0.65h);
    params.surface().set_base_color(tint * fiber);
    params.surface().set_normal(surfaceNormal);
    params.surface().set_roughness(isWood ? 0.78h : half(mix(0.88, 0.98, softness)));
    params.surface().set_metallic(0.0h);
    params.surface().set_specular(isWood ? 0.12h : 0.04h);
    params.surface().set_opacity(1.0h);

    float3 p = params.geometry().world_position();
    float travel = max(0.0, p.x + 0.94);
    // Broad window illumination fans toward the near floor; retain the
    // narrower projection on the bed and keep the foreground seat in shade.
    float floorSpread = max(0.0, 0.39 - p.y) * 1.8;
    float2 window = float2(p.z - travel * 0.30 - 0.05 - floorSpread,
                           p.y + travel * 0.65 - 0.46 + (1.0 - smoothstep(0.0, 0.30, p.y)) * 0.25);
    float edge = max(abs(window.x) - 0.40, -window.y);
    edge = max(edge, window.y > 0.69 ? length(float2(window.x, window.y - 0.69)) - 0.40 : -1.0);
    float blur = 0.018 + travel * 0.025 + (1.0 - smoothstep(0.01, 0.12, p.y)) * 0.025;
    float aperture = 1.0 - smoothstep(-blur, blur, edge);
    float bars = smoothstep(0.015, 0.015 + blur, abs(window.x)) * smoothstep(0.022, 0.022 + blur, abs(window.y - 0.42));
    half glow = half(aperture * mix(0.18, 1.0, bars) * 0.80
        * smoothstep(0.08, 0.20, travel));
    // Soft light from the rear side of the window reaches the desk. Keep it
    // spatial, so custom furniture moving through this area receives it too.
    float deskWindowZ = p.z + travel * 0.30;
    float deskWindowY = p.y + travel * 0.40;
    float deskAperture = (1.0 - smoothstep(0.19, 0.34, abs(deskWindowZ)))
        * smoothstep(0.64, 0.77, deskWindowY)
        * (1.0 - smoothstep(1.08, 1.21, deskWindowY));
    float deskPane = mix(0.24, 1.0, smoothstep(0.014, 0.055, abs(deskWindowZ - 0.045)));
    glow += half(deskAperture * deskPane * smoothstep(0.80, 1.10, travel) * 0.45);
    glow *= half(1.0 - smoothstep(1.25, 1.65, travel) * smoothstep(0.06, 0.18, p.y) * 0.55);
    float wallBounce = exp(-pow((p.y - 0.92 + p.x * 0.24) / 0.48, 2.0)) * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 0.60;
    float3 worldNormal = normalize(params.geometry().normal());
    float sunFacing = max(0.0, dot(worldNormal, normalize(float3(-1.0, 0.65, -0.30))));
    glow *= half(0.22 + 1.10 * sunFacing);
    float grazing = pow(1.0 - abs(dot(worldNormal, normalize(params.geometry().view_direction()))), 3.0);
    half3 velvet = tint * half3(1.0h, 0.82h, 0.72h) * half(grazing * softness * 0.15);
    // Broad reflected sunlight across the wallpaper, distinct from direct window light.
    float leftWall = 1.0 - smoothstep(-0.99, -0.96, p.x);
    float reflectedBand = exp(-pow((p.y - (isCutaway ? 0.98 : 1.65) - p.z * 0.75) / 0.115, 2.0)) * leftWall * 0.35;
    float backBand = exp(-pow((p.y - 0.90 + p.x * 0.40) / 0.075, 2.0)) * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 0.25;
    float lowerBackBand = exp(-pow((p.y - 0.46 + p.x * 0.35) / 0.075, 2.0)) * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 0.12;
    float upperBackBand = isCutaway ? 0.0 : exp(-pow((p.y - 1.80 + p.x * 0.45) / 0.12, 2.0))
        * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 0.35;
    float ceilingBounce = 0.0;
    half floorLight = half(1.0 - smoothstep(0.04, 0.10, p.y));
    half3 lightColor = isCutaway ? half3(1.0h, 0.98h, 1.0h)
        : mix(half3(1.0h, 0.94h, 0.82h), half3(1.0h, 0.88h, 0.68h), floorLight);
    glow *= 1.0h - floorLight * half(smoothstep(1.15, 1.90, p.z)) * 0.65h;
    half3 sunlight = mix(tint, half3(1.0h), 0.50h) * fiber * lightColor * glow;
    // Soft fabric retains warm diffuse light between the direct window patches.
    half3 clothFill = tint * fiber * (isCutaway ? half3(0.10h) : half3(0.12h, 0.12h, 0.13h))
        * half(softness) * (1.0h - saturate(glow * 1.2h));
    half3 wallFill = tint * fiber * (isCutaway ? half3(0.20h) : half3(0.06h, 0.055h, 0.05h)) * half(leftWall);
    half3 bounce = tint * fiber * half3(1.0h, 0.93h, 0.85h) * half(wallBounce + reflectedBand + ceilingBounce + backBand + lowerBackBand + upperBackBand);
    float surfaceGlow = params.uniforms().custom_parameter().z;
    // Upholstered chair fronts receive broad neutral studio bounce. Restrict
    // this to soft cutaway surfaces so timber and window light keep their tint.
    bool plushStudioBounce = isCutaway && softness > 0.9;
    float frontFacing = 1.0 - max(0.0, worldNormal.y);
    float bounceGain = plushStudioBounce ? 1.1 + 0.95 * frontFacing : 1.0;
    half3 bounceTint = plushStudioBounce ? mix(half3(1.0h, 1.0h, 0.98h), half3(1.0h, 0.72h, 0.68h), half(frontFacing)) : half3(1.0h, 0.72h, 0.38h);
    half3 lampGlow = half3(1.0h, 0.78h, 0.40h) * half(max(-surfaceGlow, 0.0) * (1.0 - daylight));
    params.surface().set_emissive_color(lampGlow + (sunlight + bounce + velvet + clothFill + wallFill) * half(daylight) * daylightTint
        + tint * fiber * bounceTint * half(max(surfaceGlow, 0.0) * daylight * bounceGain) * daylightTint);
}

// Premultiplied highlights keep the transparent preset preview free of dark halos.
kernel void plushExtractLight(texture2d<float, access::read> source [[texture(0)]],
                              texture2d<float, access::write> target [[texture(1)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x >= target.get_width() || p.y >= target.get_height()) return;
    // Sample across each output pixel's footprint, including odd-sized render targets.
    float2 ratio = float2(source.get_width(), source.get_height()) / float2(target.get_width(), target.get_height());
    uint2 q = uint2((float2(p) + 0.25) * ratio);
    uint2 r = uint2((float2(p) + 0.75) * ratio);
    uint2 edge = uint2(source.get_width() - 1, source.get_height() - 1);
    float4 averaged = (source.read(min(q, edge)) + source.read(min(uint2(r.x, q.y), edge))
                     + source.read(min(uint2(q.x, r.y), edge)) + source.read(min(r, edge))) * 0.25;
    float4 c = averaged;
    float strength = smoothstep(0.68, 0.98, dot(c.rgb, float3(0.2126, 0.7152, 0.0722)));
    target.write(float4(c.rgb * c.a, c.a) * strength, p);
}
kernel void plushCompositeLight(texture2d<float, access::read> source [[texture(0)]],
                                texture2d<float, access::sample> glow [[texture(1)]],
                                texture2d<float, access::write> target [[texture(2)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x >= source.get_width() || p.y >= source.get_height()) return;
    constexpr sampler linearClamp(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = (float2(p) + 0.5) / float2(source.get_width(), source.get_height());
    float4 c = source.read(p), bloom = glow.sample(linearClamp, uv);
    // Preserve coverage at fine fur edges; expanding alpha creates a white rim.
    float3 rgb = c.rgb + bloom.rgb * 0.045 * c.a;
    target.write(float4(rgb, c.a), p);
}

// Continuous sky evaluated per pixel; changing the time never rebuilds its mesh or texture.
[[visible]] void windowAtmosphere(realitykit::surface_parameters params) {
    constexpr sampler lookup(coord::normalized, address::clamp_to_edge, filter::linear);
    float hour = params.uniforms().custom_parameter().x;
    float weather = params.uniforms().custom_parameter().y;
    float u = fract(hour / 24.0);
    float3 zenith = float3(params.textures().custom().sample(lookup,float2(u,0.125)).rgb);
    float3 middle = float3(params.textures().custom().sample(lookup,float2(u,0.375)).rgb);
    float3 horizon = float3(params.textures().custom().sample(lookup,float2(u,0.625)).rgb);
    float3 cycle = float3(params.textures().custom().sample(lookup,float2(u,0.875)).rgb);
    float3 ray = normalize(params.geometry().model_position());
    float elevation = saturate(ray.y / 0.65);
    float3 color = elevation < 0.36 ? mix(horizon,middle,smoothstep(0.0,0.36,elevation))
                                    : mix(middle,zenith,smoothstep(0.36,1.0,elevation));
    float progress = saturate((hour - 5.5) / 14.5);
    float3 sun = normalize(float3(-0.75 + progress*1.45,0.56 + sin(progress*M_PI_F)*1.43,-3.5) - float3(0,0.68,2.15));
    float separation = max(0.0,1.0-dot(ray,sun));
    float glow = (exp(-separation*90.0)*0.22 + exp(-separation*580.0)*0.12) * cycle.x;
    float3 glowColor = mix(float3(1.0,0.98,0.9),float3(1.0,0.81,0.64),cycle.y);
    color = mix(color,glowColor,glow*(weather >= 3 ? 0.15 : 1.0));
    if (weather >= 3) color = mix(color,float3(0.67,0.74,0.79)*mix(0.38,1.0,cycle.x),0.55);
    // Sub-pixel dithering suppresses visible bands in the broad, smooth gradient.
    float grain = fract(sin(dot(params.geometry().uv0(),float2(1271.1,3117.7)))*43758.5453)-0.5;
    params.surface().set_emissive_color(half3(pow(clamp(color + grain/700.0,0.0,1.0),float3(2.2))));
}
