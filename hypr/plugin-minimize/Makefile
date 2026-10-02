CXX      ?= g++
CXXFLAGS := -std=c++23 -fPIC -shared -O2 -fvisibility=hidden
CF       := $(shell pkg-config --cflags hyprland)
SRC      := main.cpp genie.cpp
OUT      := minimize-hooks.so

all: $(OUT)

$(OUT): main.cpp genie.cpp globals.hpp
	$(CXX) $(CXXFLAGS) $(CF) -o $@ $(SRC)

clean:
	rm -f $(OUT)
