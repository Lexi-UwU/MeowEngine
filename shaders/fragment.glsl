#version 330 core

out vec4 FragColor;

uniform vec2 u_resolution; // Passed from C code



uniform vec4 sdf_locations[8];

uniform float sdf_count;

uniform vec3 player_pos;

uniform vec3 camera_rot;





mat3 rotate3D(vec3 angles) {
    vec3 c = cos(angles);
    vec3 s = sin(angles);

    // Rotation matrix for each axis
    mat3 rotX = mat3(
        1.0, 0.0, 0.0,
        0.0, c.x, s.x,
        0.0, -s.x, c.x
    );

    mat3 rotY = mat3(
        c.y, 0.0, -s.y,
        0.0, 1.0, 0.0,
        s.y, 0.0, c.y
    );

    mat3 rotZ = mat3(
        c.z, s.z, 0.0,
        -s.z, c.z, 0.0,
        0.0, 0.0, 1.0
    );

    // Combine them (Z * Y * X order)
    return rotX * rotY * rotZ;
}


float sdfSphere(vec3 point,vec4 data){
	return distance(data.xyz, point) - data.w;
}

vec3 sdfSphereNormal(vec3 point,vec4 data){
	return normalize(data.xyz- point);
}

float minFunc(float x, float y){
	if (x<y){return x;}
	return y;
}

float calculateSdfDistance(float distances[8]){
	float dis =  100000;
	for (int i = 0; i < sdf_count; i++){
		float dis1 = distances[i];
		dis = minFunc(dis,dis1);
	}
	return dis;
}

vec3 calculateSdfNormal(float distances[8],vec3 point){
	vec3 normal = vec3(0,0,0);
	float dis =  100000;
	for (int i = 0; i < sdf_count; i++){
		float dis1 = distances[i];
		if (dis1<dis){
		dis = dis1;
		normal = sdfSphereNormal(point,sdf_locations[i]);
		
		}
	}
	return normal;
}



float[8] calculateSdfDistances(vec3 point){
	float distances[8];
	for (int i = 0; i < sdf_count; i++){
		distances[i] = sdfSphere(point,sdf_locations[i]);
	}
	return distances;
}



vec3 sumBounces(vec4 bounceData[16], int numBounces){

	vec3 finalColor = vec3(0.0);
	int lastIndex = numBounces - 1;

	// Start with the color of the very last thing hit (the "emissive" or background)
	finalColor = bounceData[lastIndex].xyz;

	for (int i = lastIndex - 1; i >= 0; i--) {
		vec3 surfaceColor = bounceData[i].xyz;
	    	float roughness = bounceData[i].w;

	    	// 1. Simple Multiplicative Blending
	    	// The current surface reflects the 'finalColor' coming from the next surfaces
	    	// We scale by (1.0 - roughness) because rougher surfaces scatter light away
	    	finalColor = surfaceColor * (finalColor * (1.0 - roughness));
	    
	   
		}
 	return finalColor;


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
    ray_pos = player_pos;
    vec3 direction = normalize(vec3((st.x-0.5)*ratio,(st.y-0.5),1));
    
    direction = direction * rotate3D(camera_rot);
    
    
    bool collided = false;
    
    float step_size = 0.1;
    
    float min_step = 0.00001f;
    
    float distances[8];
    
    
    int bounce_count = 0;
    
    vec4 bounceData[16];
    
    
    while (travelled < 20.0f){
    	distances = calculateSdfDistances(ray_pos);
    	
    	float dis = calculateSdfDistance(distances);
    	
    	float floorDis = ray_pos.y + 2;
    	
    	if (dis > floorDis){dis = floorDis;}
    	
    	
    	
    	if (dis > min_step){
    	step_size = dis;
    	}else{
    		step_size = min_step;

    	}
    	
    	
    	if (ray_pos.y < -2){
    		direction.y = abs(direction.y);
    		collided = true;
    		bounceData[bounce_count] = vec4(0.5,0.1,0,0.0);
    		bounce_count += 1;
    		//break;
    	} else if (dis < 0){
    		collided = true;
    		vec3 normal = calculateSdfNormal(distances,ray_pos);
    		bounceData[bounce_count] = vec4(normal, 1.0 );
    		bounce_count += 1;
    		break;
    	}
    	

    
    	ray_pos += direction*step_size;
    	travelled += step_size;
    	
    	

    	
    }
    
    if (collided){
    
    
    
    
    FragColor = vec4(travelled/20, travelled/20, travelled/20, 1.0);
    FragColor = vec4(calculateSdfNormal(distances,ray_pos),1.0);
    FragColor = vec4(sumBounces(bounceData,bounce_count),1.0);
    }

}
