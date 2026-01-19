#version 330 core

out vec4 FragColor;

uniform vec2 u_resolution; // Passed from C code



uniform vec4 sdf_locations[512];

void main() {
    // 1. gl_FragCoord.xy gives the pixel position (0 to Width, 0 to Height)
    // 2. Dividing by resolution gives normalized coordinates (0.0 to 1.0)
    vec2 st = gl_FragCoord.xy / u_resolution;
    
    float ratio = u_resolution.y/u_resolution.x; // Y/X
    // Example: Visualize the coordinates
    // X-axis becomes Red, Y-axis becomes Green
    
    float travelled = 0.0f;
    vec3 ray_pos = vec3(0,0,0);
    vec3 direction = normalize(vec3((st.x-0.5),(st.y-0.5)*ratio,1));
    
    
    bool collided = false;
    while (travelled < 20.0f){
    	ray_pos += direction;
    	travelled += 1.0;
    	
    	
    	if (distance(vec3(0,0,6), ray_pos) < 2){
    		collided = true;
    		break;
    	}
    	
    }
    

    FragColor = vec4(travelled/20, travelled/20, travelled/20, 1.0);

}
