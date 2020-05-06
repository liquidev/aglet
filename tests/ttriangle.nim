import aglet/[
  arraybuffers,
  input,
  shaders,
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
    #vertex 330 core

    in vec2 position;

    void main(void) {
      gl_Position = vec4(position, 0.0, 1.0);
    }
  """
  FragmentShaderSrc = """
    #vertex 330 core

    out vec4 fragmentColor;

    void main(void) {
      fragmentColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
  """

var program = win.newProgram(VertexShaderSrc, FragmentShaderSrc)

while not win.closeRequested:
  var frame = win.render()
  frame.clearColor(vec4f(0.0, 0.0, 1.0, 1.0))
  frame.finish()

  win.pollEvents do (ev: InputEvent):
    echo ev
