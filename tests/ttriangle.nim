import aglet
import aglet/window/glfw
import glm/vec

var agl = initAglet()
agl.initWindow()

var win = agl.newWindowGlfw(800, 600, "GLFW window test",
                            winHints(resizable = false))

win.swapInterval = 1

const
  VertexShaderSrc = """
    #version 330 core

    layout (location = 0) in float x;
    layout (location = 1) in float y;

    void main(void) {
      gl_Position = vec4(x, y, 0.0, 1.0);
    }
  """
  FragmentShaderSrc = """
    #version 330 core

    out vec4 fragmentColor;

    void main(void) {
      fragmentColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
  """

type
  Vertex* = object
    x, y: float32

var
  prog = win.newProgram(VertexShaderSrc, FragmentShaderSrc)
  mesh = win.newMesh[:Vertex](abuStatic, dpTriangles)

mesh.uploadVertices [
  Vertex(x: 0.0,  y: 0.5),
  Vertex(x: -0.5, y: -0.5),
  Vertex(x: 0.5,  y: -0.5),
]

while not win.closeRequested:
  var frame = win.render()

  frame.clearColor(vec4f(0.0, 0.0, 1.0, 1.0))
  frame.draw(prog, mesh)

  frame.finish()

  win.pollEvents do (ev: InputEvent):
    discard
