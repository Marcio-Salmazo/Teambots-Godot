shader_type canvas_item;

uniform float intensidade : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec2 tamanho = TEXTURE_PIXEL_SIZE * intensidade;
	vec4 soma = vec4(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			soma += texture(TEXTURE, UV + vec2(float(x), float(y)) * tamanho);
		}
	}
	COLOR = soma / 25.0;
}