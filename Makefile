# Variables
CC = gcc
CFLAGS = -Iinclude
LIBS = -lglfw -lGL -ldl -lpthread
SRC = src/main.c src/glad.c
OUT = bin/app

# Build rule
all:
	mkdir -p bin
	$(CC) $(SRC) $(CFLAGS) $(LIBS) -o $(OUT)

# Clean rule
clean:
	rm -rf bin/
