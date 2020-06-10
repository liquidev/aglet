import aglet
import aglet/window/glfw

type
  Vertex = object
    position: Vec2f
    color: Vec3f

var agl = initAglet()
agl.initWindow()

const
  VertexShader = glsl"""
    #version 330 core

    in vec2 position;
    in vec3 color;

    uniform mat4 model;
    uniform mat4 projection;
    uniform vec2 offsets[10];

    out vec3 vertexColor;

    void main(void) {
      vec2 pos = position + offsets[gl_InstanceID];
      gl_Position = projection * model * vec4(pos, 0.0, 1.0);
      vertexColor = color;
    }
  """
  FragmentShader = glsl"""
    #version 330 core

    in vec3 vertexColor;

    out vec4 color;

    void main(void) {
      color = vec4(vertexColor, 1.0);
    }
  """

var
  win = agl.newWindowGlfw(800, 600, "tinstancing",
                          winHints(resizable = false, msaaSamples = 8))
  prog = win.newProgram[:Vertex](VertexShader, FragmentShader)
  circle: Mesh[Vertex]
  offsets: seq[Vec2f]

block makeCircle:
  const Sides = 128
  var vertices = @[
    Vertex(position: vec2f(0, 0), color: vec3f(1, 1, 1)),
  ]
  for i in 0..Sides:
    let
      angle = (i mod Sides) / Sides * (2 * Pi)

      x = cos(angle)
      y = sin(angle)

      r = cos(angle)
      g = sin(angle)
      b = cos(angle + Pi)

    vertices.add(Vertex(position: vec2f(x, y), color: vec3f(r, g, b)))
  circle = win.newMesh(dpTriangleFan, vertices)

const InstanceCount = 9

block makeOffsets:
  let
    first = -(InstanceCount div 2)
    last = first + InstanceCount
  for i in first..last:
    offsets.add(vec2f(2.25 * i.float, 0))

let dpDefault = defaultDrawParams().derive:
  multisample on

while not win.closeRequested:
  var frame = win.render()
  frame.clearColor(rgba(0, 0, 0, 0))
  frame.draw(prog, circle.instanced(InstanceCount), uniforms {
    model: mat4f()
      .translate(win.width / 2, win.height / 2, 0)
      .scale(24, 24, 1),
    projection: ortho(top = 0'f32, left = 0'f32,
                      right = win.width.float32, bottom = win.height.float32,
                      zNear = -1, zFar = 1),
    offsets: offsets,
  }, dpDefault)
  frame.finish()

  win.pollEvents do (event: InputEvent):
    discard
