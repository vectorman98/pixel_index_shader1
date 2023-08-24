// PIXEL INDEX ELEMENT (PIXIE) SHADER
// This applies a simple 3-color palette to everything underneath, to create similar effect to additive blending with as few colors as possible

// CREDITS:
// Original code by Vaethor
//   based on code by MartialArtsTetherball (https://www.reddit.com/r/godot/comments/gz2led/wrote_a_shader_that_maps_a_pixel_art_color/)
//   https://pastebin.com/mhEF5wK5

shader_type canvas_item; 
uniform vec3 bias = vec3(1.0, 0.25, 1.5); // Hue, Saturation (Saturation * Value), and Lightness (From LAB)
uniform vec4 silhouette_color : hint_color; // Allows you to control the output color in the Shader Params in the Inspector.

void fragment() {
	// We sample the screen texture at this point, which has the Mask node's pixels
	// rendered on it.
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color;

	// If the pixel's value is lower than the Mask's output color, it means the
	// mask is being occluded, so we draw the silhouette instead.
	if (screen_color.r < 10.0){
		COLOR.rgb = silhouette_color.rgb;
	}
}



// Color Parameters
uniform vec4 col_00: hint_color; // Color 0
uniform vec4 col_01: hint_color; // Color 1
uniform vec4 col_02: hint_color; // Color 2
uniform vec4 col_03: hint_color; // Color 3
uniform vec4 col_04: hint_color; // Color 4
uniform vec4 col_05: hint_color; // Color 5
uniform vec4 col_06: hint_color; // Color 6
uniform vec4 col_07: hint_color; // Color 7
uniform vec4 col_08: hint_color; // Color 8
uniform vec4 col_09: hint_color; // Color 9
uniform vec4 col_0A: hint_color; // Color A
uniform vec4 col_0B: hint_color; // Color B
uniform vec4 col_0C: hint_color; // Color C
uniform vec4 col_0D: hint_color; // Color D
uniform vec4 col_0E: hint_color; // Color E
uniform vec4 col_0F: hint_color; // Color F

vec3 rgb(vec3 input_data) {
    return input_data / vec3(255.0, 255.0, 255.0);
}
 
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
 
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
 
vec3 rgb2xyz(vec3 c) {
  vec3 tmp = vec3(
    (c.r>.04045)?pow((c.r+.055)/1.055,2.4):c.r/12.92,
    (c.g>.04045)?pow((c.g+.055)/1.055,2.4):c.g/12.92,
    (c.b>.04045)?pow((c.b+.055)/1.055,2.4):c.b/12.92
    );
    mat3 mat = mat3(
        vec3(0.4124, 0.3576, 0.1805),
        vec3(0.2126,0.7152,0.0722),
        vec3(0.0193,0.1192,0.9505)
    );
    return 100.*(tmp*mat);
}
 
vec3 xyz2lab(vec3 c) {
    vec3 n = c/vec3(95.047,100.,108.883),
         v = vec3(
        0,//(n.x>.008856)?pow(n.x,1./3.):(7.787*n.x)+(16./116.),                // cutting these bits out
        (n.y>.008856)?pow(n.y,1./3.):(7.787*n.y)+(16./116.),
    0//(n.z>.008856)?pow(n.z,1./3.):(7.787*n.z)+(16./116.)                      // to save on operations
    );
    return vec3((116.*v.y)-16., 0.0, 0.0);//500.*(v.x-v.y),200.*(v.y-v.z));     // since we only need lightness
}
 
vec3 rgb2lab(vec3 c) {
  vec3 lab=xyz2lab(rgb2xyz(c));
  return vec3(lab.x/100., 0.0, 0.0); //.5+.5*(lab.y/127.),.5+.5*(lab.z/127.));  // here too
}
 
float magnitude(vec3 color) {
    return sqrt(pow(color.x, 2) + pow(color.y, 2) + pow(color.z, 2));
}
 
float distance_with_hue_consideration(vec3 col_a, vec3 col_b) {
    float a = magnitude((col_a - col_b));
    float b = magnitude(((col_a - vec3(1.0, 0, 0)) - col_b));
    float c = magnitude(((col_a + vec3(1.0, 0, 0)) - col_b));
 
    a = min(a, b);
    return min(a, c);
}
 
float find_weighted_distance(vec3 color_a, vec3 color_b) {
    vec3 a_as_hsv = rgb2hsv(color_a);
    vec3 b_as_hsv = rgb2hsv(color_b);
    vec3 a_as_lab = rgb2lab(color_a);
    vec3 b_as_lab = rgb2lab(color_b);
 
    vec3 col1 = vec3(a_as_hsv.x, a_as_hsv.y * a_as_hsv.z, a_as_lab.r);
    vec3 col2 = vec3(b_as_hsv.x, b_as_hsv.y * b_as_hsv.z, b_as_lab.r);
 
    return distance_with_hue_consideration(
        col1 * bias,
        col2 * bias
    );
}

void fragment() {
    vec3 color_targets[16] = { // colors we compare each pixel to
		col_00.rgb,
        col_01.rgb,
        col_02.rgb,
        col_03.rgb,
		col_04.rgb,
        col_05.rgb,
        col_06.rgb,
        col_07.rgb,
		col_08.rgb,
        col_09.rgb,
        col_0A.rgb,
        col_0B.rgb,
		col_0C.rgb,
        col_0D.rgb,
        col_0E.rgb,
        col_0F.rgb
    };
 
    COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
 
    int index_of_closest;
    float distance_to_closest = 666.0;
    vec3 c = COLOR.rgb;
 
    for (int i = 0; i < color_targets.length(); i++) {
        float d = find_weighted_distance(color_targets[i], c);
        if (d < distance_to_closest) {
            index_of_closest = i;
            distance_to_closest = d;
        }
    }
 
    COLOR.rgb = color_targets[index_of_closest];
}
