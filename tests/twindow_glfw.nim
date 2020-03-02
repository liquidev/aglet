import aglet/[
  input,
  state,
  window,
  window/glfw,
]

var agl = initAglet()
agl.initWindow()

var win = agl.newWindowGlfw(800, 600, "GLFW window test",
                            winHints(resizable = false))

while not win.closeRequested:
  win.pollEvents do (ev: InputEvent):
    echo ev
