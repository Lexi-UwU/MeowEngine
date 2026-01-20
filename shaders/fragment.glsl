#version 330 core

out vec4 FragColor;

uniform vec2 u_resolution; // Passed from C code



uniform vec4 sdf_locations[8];

uniform float sdf_count;

uniform vec3 player_pos;

uniform vec3 camera_rot;


uniform int sdf_material_type[8];




//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+10.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}



//Snoise end


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


// circular
float smin( float a, float b, float k )
{
    k *= 1.0/(1.0-sqrt(0.5));
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
}


float minFunc(float x, float y){
	return smin(x,y,0.5);
	//if (x<y){return x;}
	//return y;
}

float calculateSdfDistance(float distances[8]){
	float dis =  100000;
	for (int i = 0; i < sdf_count; i++){
		float dis1 = distances[i];
		dis = minFunc(dis,dis1);
	}
	return dis;
}

int getSDFMaterial(float distances[8]){
	
	int material = 0;
	
	float dis =  100000;
	
	for (int i = 0; i < sdf_count; i++){
		float dis1 = distances[i];
		
		

		if (dis1<dis){
		dis = dis1;
		material = sdf_material_type[i];
		
		}

	}

	return material;
}

vec3 calculateSdfNormal(float distances[8], vec3 point) {
    vec3 normal = vec3(0.0);
    float totalWeight = 0.0;
    float epsilon = 0.0001; // Prevent division by zero

    for (int i = 0; i < sdf_count; i++) {
        float d = distances[i];
        
        // Use a power for sharper transitions (Inverse Square Law)
        // This makes the nearest object much more dominant
        float weight = 1.0 / (d * d + epsilon);
        
        normal += sdfSphereNormal(point, sdf_locations[i]) * weight;
        totalWeight += weight;

        // Early exit if we are inside or touching an object
        if (d < epsilon) {
            return sdfSphereNormal(point, sdf_locations[i]);
        }
    }
    
    return normalize(normal / totalWeight);
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


#define MAX_STEPS 128
#define SURF_DIST 0.001
#define MAX_DIST 100.0


float terrainCalc(vec3 p){
    float height = snoise(p.xz) * 0.1;
    height = 0;
    
    float totalSize = 0.0f;
    
    for (int octave = 1; octave < 16; octave ++){
    	float strength = pow(0.5,octave);
    	height += snoise(p.xz*pow(2,octave)*0.01f) * strength;
    	totalSize+= strength;
    }
    // Distance from the point's y-coord to the noise surface
    height = height / totalSize;
    return (p.y - ((height*5) - 4.0));
    }

// The function to march the ray through the noise field
float rayMarchFloor(vec3 ro, vec3 rd) {

// Noise height (scaled by 0.1)

    return terrainCalc(ro);

/*

    float dO = 0.0; // Total distance traveled
    
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = (snoise(vec2(p.x,p.z))*0.1f)-p.y-2;
        
        // 1. We take a conservative step (0.5x) to account for 
        // the non-Euclidean nature of noise displacement.
        // 2. We use abs(dS) so the ray doesn't get "stuck" if it 
        // accidentally enters the ground.
        dO += abs(dS) * 0.5; 
        
        // Safety exit: if we hit the surface or go too far
        if(dO > MAX_DIST || abs(dS) < SURF_DIST) break;
    }
    
    return dO;
    */

}


vec3 calulateLighting(vec3 normal){
	vec3 color = vec3(0,0,0);
	color+= vec3(dot(normal,vec3(1.0f,0.1f,0.1f))) * vec3(1.0,0.0,0.0);
	color+= vec3(dot(normal,vec3(0.5f,1.0f,0.5f))) * vec3(0.0,1.0,1.0);
	color+= vec3(abs(dot(normal,vec3(-0.5f,0.5f,1.0f)))) * 0.2f;
	return vec3(distance(color,vec3(0,0,0)));


}


// Assuming your noise function is: float snoise(vec2 v);
vec3 getTerrainNormal(vec3 p) {
    // Epsilon - very small displacement
    //const float h = 0.001;
    const float h = 0.01;
 
    const vec2 k = vec2(1, -1);
    
    // Four samples in a tetrahedral shape
    return normalize(
        k.xyy * terrainCalc(p + k.xyy * h) + 
        k.yyx * terrainCalc(p + k.yyx * h) + 
        k.yxy * terrainCalc(p + k.yxy * h) + 
        k.xxx * terrainCalc(p + k.xxx * h)
    );
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
    
    float min_step = 0.01f;
    
    float distances[8];
    
    
    int bounce_count = 0;
    
    vec4 bounceData[16];
    
    
    vec3 normal = vec3(0,0,0);
    
    
    float view_distance = 50.0f;
    
    
    while (travelled < 880.0f){
    	distances = calculateSdfDistances(ray_pos);
    	
    	float dis = calculateSdfDistance(distances);
    	
    	float floorDis = rayMarchFloor(ray_pos,direction)*0.1;
    	
	//floorDis = 1000000;
    	
    	
    	if (dis > floorDis){dis = floorDis;}
    	
    	if (dis > -(distance(player_pos,ray_pos)-view_distance)){
    	dis = -(distance(player_pos,ray_pos)-view_distance);
    	
    	}
    	
    	
    	
    	if (dis > min_step){
    	step_size = dis;
    	}else{
    		step_size = min_step;

    	}
    	
    	if (distance(player_pos,ray_pos) >= view_distance){
    		collided = true;
    		bounceData[bounce_count] =vec4(vec3(2.0), 1.0 );
    		bounce_count += 1;
    		//bounceData[0] = vec4(getTerrainNormal(ray_pos),1.0);
    		break;
    	
    	}
    	
    	
    	
    	if (floorDis <= 0){
    		//direction.y = abs(direction.y);
    		
    		collided = true;
    		normal = getTerrainNormal(ray_pos);
    		direction = reflect(direction,normal);
    		bounceData[bounce_count] = vec4(calulateLighting(vec3(0.2,0.2,0.2))*calulateLighting(normal),0.0);
    		//bounceData[bounce_count] = vec4(vec3(0.1,1.0,0.1),0.8);
    		bounce_count += 1;
    		ray_pos += direction;
    		
    		break;
    	} 
    	else if (dis <= 0){
    		collided = true;
    		int material = getSDFMaterial(distances);
    		if (material == 1){
    		normal = calculateSdfNormal(distances,ray_pos);
    		bounceData[bounce_count] = vec4(vec3(0.9,0.9,0.9), 0.5 );
    		bounce_count += 1;
    		direction = reflect(direction,normal);
    		ray_pos += direction * 0.1;
    		
    		
    		} else if (material == 2){
    		
    		normal = calculateSdfNormal(distances,ray_pos);
    		bounceData[bounce_count] = vec4(vec3(10.0), 1.0 );
    		bounce_count += 1;
    		direction = reflect(direction,normal);
    		ray_pos += direction;
    		break;
    		}
    		//
    	}
    	

    	if (bounce_count > 8){break;}
    	

    
    	ray_pos += direction*step_size;
    	travelled += step_size;
    	
    	
    	
    	

    	
    }
    
    if (collided){
    
    
    
    
    FragColor = vec4(travelled/64, travelled/64, travelled/64, 1.0);
    //FragColor = vec4(calculateSdfNormal(distances,ray_pos),1.0);
    FragColor = vec4(normal,1.0);
    //FragColor = vec4(vec3(dot(normal,vec3(1.0f,0.1f,0.1f))),1.0);
    //FragColor = vec4(sumBounces(bounceData,bounce_count)/(travelled*0.4),1.0);
    FragColor = vec4(sumBounces(bounceData,bounce_count),1.0);
    }else{
    FragColor = vec4(1.0,0.0,0.0,1.0);
}
//FragColor = vec4(1.0,0.0,0.0,1.0);
}
