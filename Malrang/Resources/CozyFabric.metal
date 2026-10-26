#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

kernel void cozyExtractLight(texture2d<float, access::read> source [[texture(0)]],
                             texture2d<float, access::write> target [[texture(1)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x >= target.get_width() || p.y >= target.get_height()) return;
    uint2 q = p * 2;
    uint2 edge = uint2(source.get_width() - 1, source.get_height() - 1);
    float4 averaged = (source.read(min(q, edge)) + source.read(min(q + uint2(1, 0), edge))
                     + source.read(min(q + uint2(0, 1), edge)) + source.read(min(q + uint2(1, 1), edge))) * 0.25;
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
    float softness = params.uniforms().custom_parameter().y;
    float3 local = params.geometry().model_position() * params.uniforms().custom_parameter().x;
    // Derive model-space projection weights, including rotated furniture.
    float3 n = abs(normalize(cross(dfdx(local), dfdy(local))));
    float3 weights = pow(n, float3(4.0));
    weights /= max(0.0001, weights.x + weights.y + weights.z);
    half3 fiber = params.textures().base_color().sample(fabricSampler, local.yz).rgb * half(weights.x)
        + params.textures().base_color().sample(fabricSampler, local.xz).rgb * half(weights.y)
        + params.textures().base_color().sample(fabricSampler, local.xy).rgb * half(weights.z);
    float2 uv = n.y > max(n.x, n.z) ? local.xz : (n.x > n.z ? local.yz : local.xy);
    half3 tint = half3(params.material_constants().base_color_tint());
    half3 fleece = clamp((fiber - 0.90h) * 1.85h + 0.91h, 0.75h, 1.0h);
    fiber = mix(fiber, fleece, half(softness));
    // A second, lower-frequency layer gives wool small tufts instead of uniform grain.
    half3 tufts = params.textures().base_color().sample(fabricSampler, local.yz * 0.43).rgb * half(weights.x)
        + params.textures().base_color().sample(fabricSampler, local.xz * 0.43).rgb * half(weights.y)
        + params.textures().base_color().sample(fabricSampler, local.xy * 0.43).rgb * half(weights.z);
    fiber *= clamp(1.0h + (tufts - 0.92h) * half(softness * 1.8), 0.92h, 1.04h);
    float fiberMesh = params.uniforms().custom_parameter().w;
    fiber = mix(fiber, half3(0.92h), half(fiberMesh));
    params.surface().set_base_color(tint * fiber);
    float3 detail = float3(realitykit::unpack_normal(params.textures().normal().sample(fabricSampler, uv).rgb));
    params.surface().set_normal(normalize(float3(detail.xy * mix(0.20, 0.80, softness) * (1.0 - fiberMesh), mix(detail.z, 1.0, fiberMesh))));
    params.surface().set_roughness(half(mix(0.88, 0.98, softness)));
    params.surface().set_metallic(0.0h);
    params.surface().set_specular(0.04h);
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
    half glow = half(aperture * mix(0.18, 1.0, bars) * 1.55
        * smoothstep(0.08, 0.20, travel));
    // Soft light from the rear side of the window reaches the desk. Keep it
    // spatial, so custom furniture moving through this area receives it too.
    float deskWindowZ = p.z + travel * 0.30;
    float deskWindowY = p.y + travel * 0.40;
    float deskAperture = (1.0 - smoothstep(0.19, 0.34, abs(deskWindowZ)))
        * smoothstep(0.64, 0.77, deskWindowY)
        * (1.0 - smoothstep(1.08, 1.21, deskWindowY));
    float deskPane = mix(0.24, 1.0, smoothstep(0.014, 0.055, abs(deskWindowZ - 0.045)));
    glow += half(deskAperture * deskPane * smoothstep(0.80, 1.10, travel) * 0.90);
    glow *= half(1.0 - smoothstep(1.25, 1.65, travel) * smoothstep(0.06, 0.18, p.y) * 0.55);
    float wallBounce = exp(-pow((p.y - 0.92 + p.x * 0.24) / 0.48, 2.0)) * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 0.60;
    float3 worldNormal = normalize(params.geometry().normal());
    float sunFacing = max(0.0, dot(worldNormal, normalize(float3(-1.0, 0.65, -0.30))));
    glow *= half(0.22 + 1.10 * sunFacing);
    float grazing = pow(1.0 - abs(dot(worldNormal, normalize(params.geometry().view_direction()))), 3.0);
    half3 velvet = tint * half3(1.0h, 0.82h, 0.72h) * half(grazing * softness * 0.15);
    // Broad reflected sunlight across the wallpaper, distinct from direct window light.
    float leftWall = 1.0 - smoothstep(-0.99, -0.96, p.x);
    float reflectedBand = exp(-pow((p.y - 1.65 - p.z * 0.75) / 0.115, 2.0)) * leftWall * 1.10;
    float backBand = exp(-pow((p.y - 0.90 + p.x * 0.40) / 0.075, 2.0)) * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 1.10;
    float lowerBackBand = exp(-pow((p.y - 0.46 + p.x * 0.35) / 0.075, 2.0)) * (1.0 - smoothstep(-0.99, -0.90, p.z)) * 0.85;
    float ceilingHeight = 1.495 + 0.2644 * (p.x + 1.0) + 0.3976 * (p.z + 1.0);
    float ceilingMask = 1.0 - smoothstep(0.01, 0.04, abs(p.y - ceilingHeight));
    float ceilingBounce = ceilingMask * exp(-pow((p.x + 0.85) / 0.24, 2.0) - pow((p.z + 0.30) / 0.75, 2.0)) * 2.0;
    half floorLight = half(1.0 - smoothstep(0.04, 0.10, p.y));
    half3 lightColor = mix(half3(1.0h, 0.76h, 0.22h), half3(1.0h, 0.47h, 0.08h), floorLight);
    glow *= 1.0h - floorLight * half(smoothstep(1.15, 1.90, p.z)) * 0.65h;
    half3 sunlight = mix(tint, half3(1.0h), 0.50h) * fiber * lightColor * glow;
    // Soft fabric retains warm diffuse light between the direct window patches.
    half3 clothFill = tint * fiber * half3(0.25h, 0.235h, 0.25h)
        * half(softness) * (1.0h - saturate(glow * 1.2h));
    half3 wallFill = tint * fiber * half3(0.12h, 0.046h, 0.024h) * half(leftWall);
    half3 bounce = tint * fiber * half3(1.0h, 0.57h, 0.33h) * half(wallBounce + reflectedBand + ceilingBounce + backBand + lowerBackBand);
    params.surface().set_emissive_color(sunlight + bounce + velvet + clothFill + wallFill
        + tint * fiber * half3(1.0h, 0.72h, 0.38h) * half(params.uniforms().custom_parameter().z));
}

// Premultiplied highlights keep the transparent preset preview free of dark halos.
kernel void plushExtractLight(texture2d<float, access::read> source [[texture(0)]],
                              texture2d<float, access::write> target [[texture(1)]], uint2 p [[thread_position_in_grid]]) {
    if (p.x >= target.get_width() || p.y >= target.get_height()) return;
    uint2 q = p * 2;
    uint2 edge = uint2(source.get_width() - 1, source.get_height() - 1);
    float4 averaged = (source.read(min(q, edge)) + source.read(min(q + uint2(1, 0), edge))
                     + source.read(min(q + uint2(0, 1), edge)) + source.read(min(q + uint2(1, 1), edge))) * 0.25;
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
