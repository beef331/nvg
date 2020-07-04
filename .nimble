# Package

version = "0.1.0"
author = "Your Name"
description = "./"
license = "?"

# Deps
requires "nim >= 1.2.0"
requires "nico >= 0.2.6"

srcDir = "src"

task runr, "Runs ./ for current platform":
 exec "nim c -r -d:release -o:./ src/main.nim"

task rund, "Runs debug ./ for current platform":
 exec "nim c -r -d:debug -o:./ src/main.nim"

task release, "Builds ./ for current platform":
 exec "nim c -d:release -o:./ src/main.nim"

task debug, "Builds debug ./ for current platform":
 exec "nim c -d:debug -o:./_debug src/main.nim"

task web, "Builds ./ for current web":
 exec "nim js -d:release -o:./.js src/main.nim"

task webd, "Builds debug ./ for current web":
 exec "nim js -d:debug -o:./.js src/main.nim"

task deps, "Downloads dependencies":
 exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x64.zip -o SDL2_x64.zip"
 exec "unzip SDL2_x64.zip"
 #exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x86.zip -o SDL2_x86.zip"
