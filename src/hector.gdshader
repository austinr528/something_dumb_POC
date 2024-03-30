shader_type canvas_item;

float map_val(float val, float inrng_min, float inrng_max, float outrng_min, float outrng_max) {
	return (val - inrng_min) / (inrng_max - inrng_min) * (outrng_max - outrng_min) + outrng_min;
}

uniform float curve_length = 2.0;

uniform float strength: hint_range(-10.0, 10.0) = 0.0;
uniform vec2 deformation = vec2(0, 0);
uniform float sideways_deform_factor = 0.05;
uniform float height = 64.0;
uniform float new_width = 10.0;

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float attenuation : hint_range(0.0, 5.0) = 0.1;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
void vertex() {
	//if (VERTEX_ID == 0 || VERTEX_ID == 3) {
		//UV.x += TEXTURE_PIXEL_SIZE.x * UV.y;
	//}
	//if (VERTEX_ID == 1 || VERTEX_ID == 2) {
		//UV.x -=  0.01;
	//}
	
	//if (UV.y > 0.06249999813735483) {
		//UV.x += sin(UV.y * strength) * 0.3;
		//UV.x = clamp(UV.x, -1.0, 1.0);
	//}
	// Funnel like skew
	float max_witdth = new_width / 2.0;
	if (VERTEX.y > 5.0 && abs(VERTEX.x) > max_witdth) {
		// VERTEX.x = sign(VERTEX.x) * (((abs(VERTEX.x) - max_witdth) / (2.0 * -VERTEX.y)) + max_witdth);
	}
	
	VERTEX.x += pow(UV.y * TEXTURE_PIXEL_SIZE.y, strength);
}


void fragment() {
	
}

//uniform float outline_width = 1.0;
//uniform vec4 outline_color = vec4(0.0, 1.0, 1.0, 1);
//void fragment() {
	//// Called for every pixel the material is visible on.
	//vec4 col = texture(TEXTURE, UV);
	//vec2 ps = TEXTURE_PIXEL_SIZE * outline_width; // multiply only once instead of eight times.
	//float a;
	//float maxa = col.a;
    //float mina = col.a;
	//// Use 8-way kernel for smoothness
	////------------------//
	////    X   X   X     //
	////      \ | /       //
	////    X - O - X     //
	////      / | \       //
	////    X   X   X     //
	////------------------//
	//for (float y = -1.0; y <= 1.0; y++) {
		//for (float x = -1.0; x <= 1.0; x++) {
			//if (vec2(x, y) == vec2(0.0)) {
				//continue; // ignore the center of kernel
			//}
			//a = texture(TEXTURE, UV + vec2(x,y) * ps).a;
			//maxa = max(a, maxa); 
			//mina = min(a, mina);
		//}
	//}
	//// Fill transparent pixels only, don't overlap texture
	//if (col.a == 0.0) {
		//vec4 tmp = outline_color;
		//tmp.b = map_val(VERTEX.y, 0.0, 1.0 / TEXTURE_PIXEL_SIZE.y, 0.0, 1.0);
		//// TODO: this should work I really don't get it
		//tmp.g = map_val(VERTEX.x, 0.0, 1.0 / TEXTURE_PIXEL_SIZE.x, 0.0, 0.7);
		//tmp.a = maxa - mina;
		//COLOR = tmp;
	//} else {
		//COLOR = col;
	//}
//}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
