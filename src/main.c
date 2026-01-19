#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>

// Function to read shader files from disk
char* readFile(const char* filename) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "Error: Could not open shader file %s\n", filename);
        return NULL;
    }

    fseek(f, 0, SEEK_END);
    long length = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *buffer = malloc(length + 1);
    if (!buffer) {
        fprintf(stderr, "Error: Memory allocation failed for shader %s\n", filename);
        fclose(f);
        return NULL;
    }

    fread(buffer, 1, length, f);
    fclose(f);
    buffer[length] = '\0';
    return buffer;
}

// Function to check shader compilation errors
void checkCompileErrors(unsigned int shader, const char* type) {
    int success;
    char infoLog[1024];
    if (type != "PROGRAM") {
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success) {
            glGetShaderInfoLog(shader, 1024, NULL, infoLog);
            fprintf(stderr, "ERROR::SHADER_COMPILATION_ERROR of type: %s\n%s\n", type, infoLog);
        }
    } else {
        glGetProgramiv(shader, GL_LINK_STATUS, &success);
        if (!success) {
            glGetProgramInfoLog(shader, 1024, NULL, infoLog);
            fprintf(stderr, "ERROR::PROGRAM_LINKING_ERROR of type: %s\n%s\n", type, infoLog);
        }
    }
}

int main() {
    // 1. Initialize GLFW and tell it we want to use OpenGL 3.3 Core Profile
    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        return -1;
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // 2. Create the window
    int width = 800, height = 600;
    GLFWwindow* window = glfwCreateWindow(800, 600, "OpenGL Fullscreen Fragment Shader", NULL, NULL);
    if (!window) {
        fprintf(stderr, "Failed to create GLFW window\n");
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);

    // 3. Load GLAD to find OpenGL function pointers
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        fprintf(stderr, "Failed to initialize GLAD\n");
        return -1;
    }

    // 4. Load, Compile, and Link Shaders
    char* vertexSource = readFile("shaders/vertex.glsl");
    char* fragmentSource = readFile("shaders/fragment.glsl");

    if (!vertexSource || !fragmentSource) return -1;

    // Vertex Shader
    unsigned int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, (const char**)&vertexSource, NULL);
    glCompileShader(vertexShader);
    checkCompileErrors(vertexShader, "VERTEX");

    // Fragment Shader
    unsigned int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, (const char**)&fragmentSource, NULL);
    glCompileShader(fragmentShader);
    checkCompileErrors(fragmentShader, "FRAGMENT");

    // Shader Program
    unsigned int shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    checkCompileErrors(shaderProgram, "PROGRAM");

    // Free memory and delete shaders (they are linked in the program now)
    free(vertexSource);
    free(fragmentSource);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    // 5. Define a Full-Screen Quad (Two Triangles)
    // Covers the entire screen from -1.0 to 1.0
    float vertices[] = {
        // First triangle
         1.0f,  1.0f, 0.0f,  // Top Right
         1.0f, -1.0f, 0.0f,  // Bottom Right
        -1.0f,  1.0f, 0.0f,  // Top Left 
        // Second triangle
         1.0f, -1.0f, 0.0f,  // Bottom Right
        -1.0f, -1.0f, 0.0f,  // Bottom Left
        -1.0f,  1.0f, 0.0f   // Top Left
    };

    unsigned int VBO, VAO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);

    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Tell OpenGL how to interpret the vertex data (at location 0)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // Unbind (Optional)
    glBindBuffer(GL_ARRAY_BUFFER, 0); 
    glBindVertexArray(0); 
    
    
    // Get the location of the uniform
    int resLocation = glGetUniformLocation(shaderProgram, "u_resolution");    
    
    int sdfPosLocation = glGetUniformLocation(shaderProgram, "sdf_locations");    
    
    int sdfCountLocation = glGetUniformLocation(shaderProgram, "sdf_count");    
    
    
    int playerPosLocation = glGetUniformLocation(shaderProgram, "player_pos");    
    
    
    
    
    
    
    
    float sdfData[] = {
        // First triangle
         0.0f,  0.0f, 6.0f, 1.0f, 
         1.0f,  0.0f, 6.0f, 1.0f, 
    };
    
    
    float player_pos[] = {0.0f,0.0f,0.0f}; //TODO: Replace with struct
    
    
    

    // 6. Main Render Loop
    while (!glfwWindowShouldClose(window)) {
        // Input
        if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS){
            glfwSetWindowShouldClose(window, 1);
        }
        
          if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS){
            player_pos[2] += 0.1;
        }
                  if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS){
            player_pos[2] -= 0.1;
        }
        
                  if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS){
            player_pos[0] -= 0.1;
        }
                  if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS){
            player_pos[0] += 0.1;
        }
        
        
        // Rendering commands
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f); 
        glClear(GL_COLOR_BUFFER_BIT);

        // Draw our full-screen quad
        glUseProgram(shaderProgram);
        
        
        // Update resolution uniform (in case window was resized)
        glfwGetFramebufferSize(window, &width, &height);
        glViewport(0, 0, width, height);
        glUniform2f(resLocation, (float)width, (float)height);
        
        int numSDF = sizeof(sdfData) / (sizeof(float) * 4);
        //printf("Count: %d \n",numSDF);
        //fflush(stdout);
        
        glUniform4fv(sdfPosLocation, numSDF, sdfData);
        
        
        glUniform3f(playerPosLocation, player_pos[0],player_pos[1],player_pos[2]);
        
        

        glUniform1f(sdfCountLocation, (float)numSDF);
        
        
        
        
        glBindVertexArray(VAO);
        // Draw 6 vertices (2 triangles) instead of 3
        glDrawArrays(GL_TRIANGLES, 0, 6);

        // Swap buffers and poll IO events
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // 7. Cleanup Resources
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteProgram(shaderProgram);

    glfwTerminate();
    return 0;
}
