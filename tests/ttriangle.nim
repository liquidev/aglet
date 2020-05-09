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

    layout (location = 0) in vec2 position;

    void main(void) {
      gl_Position = vec4(position, 0.0, 1.0);
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
    position: Vec2f

var
  prog = win.newProgram(VertexShaderSrc, FragmentShaderSrc)
  mesh = win.newMesh[:Vertex](abuStatic, dpTriangles)

mesh.uploadVertices [
  Vertex(position: vec2f(0.0,  0.5)),
  Vertex(position: vec2f(-0.5, -0.5)),
  Vertex(position: vec2f(0.5,  -0.5)),
]

while not win.closeRequested:
  var frame = win.render()

  frame.clearColor(vec4f(0.0, 0.0, 1.0, 1.0))
  frame.draw(prog, mesh)

  frame.finish()

  win.pollEvents do (ev: InputEvent):
    discard
