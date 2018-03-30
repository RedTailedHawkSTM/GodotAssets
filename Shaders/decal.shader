shader_type spatial;
render_mode cull_front, depth_test_disable;

uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
//uniform sampler2D texture_normal : hint_normal;
//uniform float normal_scale : hint_range(-16.0,16.0);

uniform vec2 uv_scale = vec2(1.0,1.0);
uniform float wrap = 0.5;

bool clip(vec3 v,float d){
	return v.x < d || v.y < d || v.z < d;
}


void fragment(){
	
	mat4 CAMERA_MATRIX = inverse(INV_CAMERA_MATRIX);
	float depth = texture(DEPTH_TEXTURE,SCREEN_UV).r;
	
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth*2.0-1.0,1.0);
	view_pos.xyz/=view_pos.w;
	vec4 world_pos = CAMERA_MATRIX * vec4(view_pos.xyz,1.0);
	world_pos.xyz/=world_pos.w;
	vec4 obj_pos = inverse(WORLD_MATRIX) * vec4(world_pos.xyz,1.0);
	obj_pos.xyz/=obj_pos.w;
	
	/*vec3 dx = dFdx(view_pos.xyz);
	vec3 dy = dFdy(view_pos.xyz);
	
	vec3 pixel_normal = normalize(cross(dx,dy));
	vec3 pixel_binormal = normalize(dx);
	vec3 pixel_tangent = normalize(dy);
	
	mat3 TANGENT_MATRIX = mat3(
	(inverse(WORLD_MATRIX) * vec4(pixel_tangent,1.0)).xyz,
	(inverse(WORLD_MATRIX) * vec4(pixel_binormal,1.0)).xyz,
	(inverse(WORLD_MATRIX) * vec4(pixel_normal,1.0)).xyz
	);*/
	
	vec2 depth_uv = -obj_pos.xy*uv_scale+0.5;
	
	vec4 tex_albedo = textureLod(texture_albedo,depth_uv,0.0);
	vec4 screen_color = texture(SCREEN_TEXTURE,SCREEN_UV);
	ALBEDO = tex_albedo.rgb * albedo.rgb * screen_color.rgb;
	ALPHA = albedo.a * tex_albedo.a;
	//ALPHA = 0.5;

	//vec3 normal_map = textureLod(texture_normal,depth_uv,0.0).rgb;
	//NORMALMAP = normal_map;
	//NORMALMAP_DEPTH = normal_scale;

	//NORMAL = pixel_normal;
	//TANGENT = pixel_tangent;
	//BINORMAL = pixel_binormal;
	
	//ALBEDO = NORMAL;
	if(clip((wrap-obj_pos.xyz),0.0) || clip(wrap+obj_pos.xyz,0.0) || depth == 1.0){
		discard;
	}
	
}

void light(){
	//float light_amount = clamp(dot(LIGHT,NORMAL),0.0,1.0);
	DIFFUSE_LIGHT = ALBEDO;
}