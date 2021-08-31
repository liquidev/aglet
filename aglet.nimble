# Package

version       = "0.4.4"
author        = "liquid600pgm"
description   = "A safe, high-level, optimized OpenGL wrapper"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.6"
requires "https://github.com/liquid600pgm/nim-glm >= 1.1.1"
requires "https://github.com/nimgl/glfw >= 3.3.4"


# Tasks

from os import walkDirRec, splitFile

task buildDocs, "rebuilds documentation to the docs/ folder for GitHub Pages":
  echo "-- creating doc directory"
  rmDir "docs"
  mkDir "docs"

  echo "-- building docs for aglet.nim"
  selfExec "doc " &
    "--project --index:on -o:docs/ " &
    "--git.url:https://github.com/liquidev/aglet " &
    "--git.commit:" & version & " " &
    "src/aglet.nim"

  echo "-- creating index.html"
  cpFile "docs/aglet.html", "docs/index.html"

  echo "-- removing leftover .idx files"
  for name in walkDirRec "docs":
    let (_, _, ext) = name.splitFile
    if ext == ".idx":
      echo " : ", name
      rmFile name

  echo "-- done!"
