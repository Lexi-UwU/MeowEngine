#version 330 core

out vec4 FragColor;

uniform vec2 u_resolution; // Passed from C code



uniform vec4 sdf_locations[512];



float sdfSphere(vec3 point,vec4 data){
	return distance(data.xyz, point) - data.w;
}

void main() {
    // 1. gl_FragCoord.xy gives the pixel position (0 to Width, 0 to Height)
    // 2. Dividing by resolution gives normalized coordinates (0.0 to 1.0)
    vec2 st = gl_FragCoord.xy / u_resolution;
    
    float ratio = u_resolution.x/u_resolution.y; // X/Y
    // Example: Visualize the coordinates
    // X-axis becomes Red, Y-axis becomes Green
    
    float travelled = 0.0f;
    vec3 ray_pos = vec3(0,0,0);
    vec3 direction = normalize(vec3((st.x-0.5)*ratio,(st.y-0.5),1));
    
    
    bool collided = false;
    
    float step_size = 0.1;
    
    while (travelled < 20.0f){
    	float dis = sdfSphere(ray_pos,vec4(0,0,6,2));
    	
    	if (dis > 0.02){
    	step_size = dis;
    	}else{
    		step_size = 0.1;
    		collided = true;
    		break;
    	}
    
    	ray_pos += direction*step_size;
    	travelled += step_size;
    	
    	

    	
    }
    
    if (collided){
    FragColor = vec4(travelled/20, travelled/20, travelled/20, 1.0);
    }

}
