import random

import aglet
import aglet/window/glfw
import glm/mat_transform
import glm/noise

type
  Vertex = object
    position: Vec3f
    textureCoords: Vec3f

var agl = initAglet()
agl.initWindow()

const
  VertexSource = """
    #version 330 core

    in vec3 position;
    in vec3 textureCoords;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    out vec3 fragTextureCoords;

    void main(void) {
      gl_Position = projection * view * model * vec4(position, 1.0);
      fragTextureCoords = textureCoords;
    }
  """
  FragmentSource = """
    #version 330 core

    in vec3 fragTextureCoords;

    uniform sampler3D volume;

    out vec4 color;

    void main(void) {
      float intensity = texture(volume, fragTextureCoords).r;
      if (intensity > 0.5) {
        discard;
      } else {
        color = vec4(0.01);
      }
    }
  """

var
  win = agl.newWindowGlfw(800, 600, "tcloud",
                          winHints(resizable = false,
                                   msaaSamples = 1))
  prog = win.newProgram[:Vertex](VertexSource, FragmentSource)

const
  Density = 128
  TextureDensity = 16
  Noise = 0.02
  NoiseRange = -Noise..Noise

var volumePoints: seq[Vertex]
for iz in -Density..Density:
  for iy in -Density..Density:
    for ix in -Density..Density:
      let position =
        vec3f(ix / Density, iy / Density, iz / Density) +
        vec3f(rand(NoiseRange), rand(NoiseRange), rand(NoiseRange))
      var texture = (position + 1) / 2
      volumePoints.add(Vertex(position: position, textureCoords: texture))
echo "point count: ", volumePoints.len

var volumePixels: seq[Red32f]
for iz in 0..<TextureDensity:
  for iy in 0..<TextureDensity:
    for ix in 0..<TextureDensity:
      let
        x = ix / TextureDensity
        y = iy / TextureDensity
        z = iz / TextureDensity
        noise = (simplex(vec3f(x, y, z) * 3) + 1) / 2
      volumePixels.add(noise.red32f)

var
  mesh = win.newMesh(dpPoints, volumePoints)
  volume = win.newTexture3D(vec3i(TextureDensity), volumePixels)

const
  Fov = Pi / 2
  CameraRadius = 2.0

var
  lastMousePos: Vec2[float]
  dragging = false
  rotationX = 0.0
  rotationY = 0.0
  zoom = 1.0

const
  Origin = vec3f(0.0)
  Up = vec3f(0.0, 1.0, 0.0)

let
  additiveBlending = blendMode(blendAdd(bfOne, bfOne), blendAdd(bfOne, bfZero))
  drawParams = defaultDrawParams().derive:
    blend additiveBlending

while not win.closeRequested:
  var target = win.render()

  target.clearColor(vec4f(0.0, 0.0, 0.0, 1.0))
  target.clearDepth(1.0)

  let
    aspect = target.dimensions.x / target.dimensions.y
    projection = perspective(Fov.float32, aspect, 0.01, 100.0)
  target.draw(prog, mesh, uniforms {
    model: mat4f(),
    view: lookAt(eye = vec3f(0.0, 0.0, CameraRadius),
                 center = Origin,
                 up = Up)
      .rotateX(rotationX)
      .rotateY(rotationY)
      .scale(zoom),
    projection: projection,
    ?volume: volume.sampler(magFilter = tfLinear,
                            wrapS = twClampToEdge,
                            wrapT = twClampToEdge,
                            wrapR = twClampToEdge),
  }, drawParams)

  target.finish()

  win.pollEvents do (event: InputEvent):
    if event.kind in {iekMousePress, iekMouseRelease}:
      dragging = event.kind == iekMousePress
    elif event.kind == iekMouseMove:
      if dragging:
        let delta = event.mousePos - lastMousePos
        rotationX += delta.y / 100
        rotationY += delta.x / 100
      lastMousePos = event.mousePos
    elif event.kind == iekMouseScroll:
      zoom += event.scrollPos.y * 0.1
