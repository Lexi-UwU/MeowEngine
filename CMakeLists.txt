cmake_minimum_required(VERSION 3.10)

# Project metadata
project(MyOpenGLApp LANGUAGES C)

# Set the output directory for the executable (matches your bin/ folder)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# 1. Search for required packages
find_package(OpenGL REQUIRED)
find_package(Threads REQUIRED)

# 2. Define the executable and source files
# (Includes main.c and glad.c as per your SRC variable)
add_executable(app 
    src/main.c 
    src/glad.c
)

# 3. Include directories (Matches -Iinclude)
target_include_directories(app PRIVATE include)

# 4. Link Libraries (Matches -lglfw -lGL -ldl -lpthread -lm)
# We use ${CMAKE_DL_LIBS} for -ldl and m for math
target_link_libraries(app 
    PRIVATE 
    glfw 
    OpenGL::GL 
    Threads::Threads
    ${CMAKE_DL_LIBS}
    m
)
