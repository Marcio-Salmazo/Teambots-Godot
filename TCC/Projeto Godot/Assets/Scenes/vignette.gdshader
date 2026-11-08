
shader_type canvas_item;

uniform sampler2D screen_texture :
    hint_screen_texture, repeat_disable, filter_nearest;

uniform float darkness : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.75;
uniform float vignette_radius : hint_range(0.1, 1.0) = 0.48;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.45;

uniform vec4 shadow_tint : source_color =
    vec4(0.035, 0.015, 0.055, 1.0);

void fragment() {
    vec3 scene = texture(screen_texture, SCREEN_UV).rgb;

    scene *= 1.0 - darkness;

    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

    vec2 centered_uv =
        (SCREEN_UV - vec2(0.5)) * vec2(aspect, 1.0);

    float dist = length(centered_uv);

    float vignette = smoothstep(
        vignette_radius,
        vignette_radius + vignette_softness,
        dist
    );

    scene *= 1.0 - vignette * vignette_strength;

    scene = mix(
        scene,
        scene * shadow_tint.rgb,
        vignette * 0.35
    );
	
	float grayscale = dot(scene, vec3(0.299, 0.587, 0.114));
	scene = vec3(grayscale);

    COLOR = vec4(scene, 1.0);
}
