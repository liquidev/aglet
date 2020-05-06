import aglet/[
  arraybuffer,
  input,
  program,
  state,
  target,
  window,
  window/glfw,
]
import glm/vec

var agl = initAglet()
agl.initWindow()

var win = agl.newWindowGlfw(800, 600, "GLFW window test",
                            winHints(resizable = false))

const
  VertexShaderSrc = """
    #version 330 core

    in vec2 position;

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
    x, y: float32

var
  prog = win.newProgram(VertexShaderSrc, FragmentShaderSrc)
  mesh = win.newArrayBuffer[:Vertex](abuStatic)

mesh.uploadVertices [
  Vertex(x: 1.0, y: 1.0),
  Vertex(x: 0.0, y: 1.0),
  Vertex(x: 1.0, y: 0.0),
]

while not win.closeRequested:
  var frame = win.render()
  frame.clearColor(vec4f(0.0, 0.0, 1.0, 1.0))
  frame.finish()

  win.pollEvents do (ev: InputEvent):
    discard
