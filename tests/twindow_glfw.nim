import glm/vec
import aglet/[
  input,
  state,
  target,
  window,
  window/glfw,
]

var agl = initAglet()
agl.initWindow()

var win = agl.newWindowGlfw(800, 600, "GLFW window test",
                            winHints(resizable = false))

while not win.closeRequested:
  var frame = win.render()
  frame.clearColor(vec4f(0.0, 0.0, 1.0, 1.0))
  frame.finish()

  win.pollEvents do (ev: InputEvent):
    echo ev
