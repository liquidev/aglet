import std/times

import aglet
import aglet/window/glfw

var agl = initAglet()
agl.initWindow()

var win = agl.newWindowGlfw(800, 600, "GLFW window test",
                            winHints(resizable = false))

win.swapInterval = 1

const
  VertexShaderSrc = glsl"""
    #version 330 core

    uniform float time;

    in vec2 position;
    in vec4 color;

    out vec4 vertexColor;

    void main(void) {
      gl_Position = vec4(position + vec2(0.0, sin(time)), 0.0, 1.0);
      vertexColor = color;
    }
  """
  FragmentShaderSrc = glsl"""
    #version 330 core

    in vec4 vertexColor;

    out vec4 fragmentColor;

    void main(void) {
      fragmentColor = vertexColor;
    }
  """

type
  Vertex* = object
    position: Vec2f
    color: Vec4f

var
  prog = win.newProgram[:Vertex](VertexShaderSrc, FragmentShaderSrc)
  mesh = win.newMesh[:Vertex](muStatic, dpTriangles)

const
  red = vec4f(1.0, 0.0, 0.0, 1.0)
  green = vec4f(0.0, 1.0, 0.0, 1.0)
  blue = vec4f(0.0, 0.0, 1.0, 1.0)

mesh.uploadVertices [
  Vertex(position: vec2f(0.0,  0.5),  color: red),
  Vertex(position: vec2f(-0.5, -0.5), color: green),
  Vertex(position: vec2f(0.5,  -0.5), color: blue),
]

let drawParams = defaultDrawParams()

let startTime = epochTime()
while not win.closeRequested:
  var frame = win.render()

  frame.clear(clearParams().withColor(rgba(0.0, 0.0, 0.0, 1.0)))

  frame.draw(prog, mesh, uniforms {
    time: float32(epochTime() - startTime),
  }, drawParams)

  frame.finish()

  win.pollEvents do (ev: InputEvent):
    discard
