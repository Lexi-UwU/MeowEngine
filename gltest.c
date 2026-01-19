#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stdio.h>

int main() {
    // 1. Initialize GLFW
    glfwInit();
    
    // 2. Create a Window
    GLFWwindow* window = glfwCreateWindow(800, 600, "OpenGL in C", NULL, NULL);
    glfwMakeContextCurrent(window);

    // 3. Load OpenGL functions via GLAD
    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    // 4. The Render Loop
    while (!glfwWindowShouldClose(window)) {
        // Clear the screen with a color
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // Swap buffers (display what was drawn)
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}
