import aglet
import aglet/window/glfw
import glm/noise
from nimPNG import decodePng32

type
  Vertex = object
    position: Vec2f
    textureCoords: Vec2f

var agl = initAglet()
agl.initWindow()

const
  VertexSource = glsl"""
    #version 330 core

    layout (location = 0) in vec2 position;
    layout (location = 1) in vec2 textureCoords;

    out vec2 fragTextureCoords;

    void main(void) {
      gl_Position = vec4(position, 0.0, 1.0);
      fragTextureCoords = textureCoords;
    }
  """
  FragmentSource = glsl"""
    #version 330 core

    in vec2 fragTextureCoords;

    uniform sampler1D noise;
    uniform sampler2D bricks;

    out vec4 color;

    void main(void) {
      float intensity = texture(noise, fragTextureCoords.x).r;
      vec2 uv = vec2(fragTextureCoords.x, 1.0 - fragTextureCoords.y);
      color = texture(bricks, fragTextureCoords) + vec4(vec3(intensity), 0.0);
    }
  """

var
  win = agl.newWindowGlfw(800, 600, "ttextures",
                          winHints(resizable = false))
  prog = win.newProgram[:Vertex](VertexSource, FragmentSource)
  rect = win.newMesh(
    primitive = dpTriangles,
    vertices = [
      Vertex(position: vec2f(-0.5,  0.5), textureCoords: vec2f(0.0, 1.0)),
      Vertex(position: vec2f( 0.5,  0.5), textureCoords: vec2f(1.0, 1.0)),
      Vertex(position: vec2f( 0.5, -0.5), textureCoords: vec2f(1.0, 0.0)),
      Vertex(position: vec2f(-0.5, -0.5), textureCoords: vec2f(0.0, 0.0)),
    ],
    indices = [uint32 0, 1, 2, 2, 3, 0],
  )
  noiseMap: seq[Red32f]

for i in 0..<128:
  noiseMap.add(red32f((perlin(vec2f(0.0, i / 128 * 10)) + 1) / 2))

const
  BricksPng = slurp("data/bricks.png")

var
  noiseTex = win.newTexture1D(noiseMap)
  bricksTex = win.newTexture2D(Rgba8, decodePng32(BricksPng))

let drawParams = defaultDrawParams()

while not win.closeRequested:
  var target = win.render()
  target.clear(clearParams().withColor(rgba(0.0, 0.0, 0.0, 1.0)))
  target.draw(prog, rect, uniforms {
    ?noise: noiseTex.sampler(),
    ?bricks: bricksTex.sampler(magFilter = fmNearest),
  }, drawParams)
  target.finish()

  win.pollEvents do (event: InputEvent):
    discard
