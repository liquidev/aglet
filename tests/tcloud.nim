import std/monotimes
import std/random
import std/strutils
import std/times

import aglet
import aglet/window/glfw
import glm/mat_transform
import glm/noise
from nimPNG import savePng32

type
  Vertex = object
    position: Vec3f
    textureCoords: Vec3f
  Vertex2D = object
    position: Vec2f
    textureCoords: Vec2f

var agl = initAglet()
agl.initWindow()

const
  BlurVertex = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 textureCoords;

    out vec2 fragTextureCoords;

    void main(void) {
      gl_Position = vec4(position, 0.0, 1.0);
      fragTextureCoords = textureCoords;
    }
  """
  BlurFragment = glsl"""
    #version 330 core

    in vec2 fragTextureCoords;

    uniform sampler2D source;
    uniform vec2 blurDirection;
    uniform int blurSamples;
    uniform vec2 windowSize;

    out vec4 color;

    vec4 pixel(vec2 position) {
      vec2 normalized = position / windowSize;
      normalized.y = 1.0 - normalized.y;
      return texture(source, normalized);
    }

    float gaussian(float x) {
      return pow(2.71828, -(x*x / 0.125));
    }

    void main(void) {
      vec2 uv = fragTextureCoords * windowSize;

      float start = -floor(float(blurSamples) / 2.0);
      float end = start + float(blurSamples);
      vec4 sum = vec4(0.0);
      float total = 0.0;
      for (float i = start; i <= end; ++i) {
        vec2 offset = blurDirection * i;
        float factor = gaussian(i / -start);
        sum += pixel(uv + offset) * factor;
        total += factor;
      }
      sum /= total;

      color = sum;
    }
  """
  VolumeVertex = glsl"""
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
  VolumeFragment = glsl"""
    #version 330 core

    in vec3 fragTextureCoords;

    uniform sampler3D volume;

    out vec4 color;

    void main(void) {
      float intensity = texture(volume, fragTextureCoords).r;
      if (intensity > 0.5) {
        discard;
      } else {
        color = vec4(vec3(0.01), 1.0);
      }
    }
  """

var
  win = agl.newWindowGlfw(800, 600, "tcloud",
                          winHints(resizable = false,
                                   msaaSamples = 1))
  defaultFb = win.defaultFramebuffer
  volumeProgram = win.newProgram[:Vertex](VolumeVertex, VolumeFragment)
  blurProgram = win.newProgram[:Vertex](BlurVertex, BlurFragment)
  blurBufferA, blurBufferB: SimpleFramebuffer
  fullScreen = win.newMesh(
    primitive = dpTriangles,
    vertices = [
      Vertex2D(position: vec2f(-1.0, -1.0), textureCoords: vec2f(0.0, 1.0)),
      Vertex2D(position: vec2f( 1.0, -1.0), textureCoords: vec2f(1.0, 1.0)),
      Vertex2D(position: vec2f(-1.0,  1.0), textureCoords: vec2f(0.0, 0.0)),
      Vertex2D(position: vec2f( 1.0,  1.0), textureCoords: vec2f(1.0, 0.0)),
    ],
    indices = [uint8 0, 1, 2, 1, 2, 3],
  )

proc updateBlurBuffer() =
  blurBufferA = win.newTexture2D[:Rgba8](win.size).toFramebuffer
  blurBufferB = win.newTexture2D[:Rgba8](win.size).toFramebuffer
updateBlurBuffer()

proc saveScreenshot(data: ptr UncheckedArray[Rgba8], len: Natural) =
  var counter {.global.} = 0

  echo "data retrieved, inverting Y axis"
  var pngData = newString(len * sizeof(Rgba8))
  let pitch = win.width * sizeof(Rgba8)
  for y in 0..<win.height:
    copyMem(pngData[y * win.width * sizeof(Rgba8)].addr,
            data[(win.height - y) * win.width].addr,
            pitch)
  let filename = "tcloud_" & $counter & ".png"
  echo "data downloaded, saving screenshot to ", filename
  echo "status: ", savePng32(filename, pngData, win.width, win.height)
  inc(counter)

const
  Density = 128
  TextureDensity = 16
  Noise = 0.05
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
  lastMousePos: Vec2f
  dragging = false
  rotationX = 0.0
  rotationY = 0.0
  zoom = 1.0

const
  Origin = vec3f(0.0)
  Up = vec3f(0.0, 1.0, 0.0)

let
  additiveBlending = blendMode(blendAdd(bfOne, bfOne), blendAdd(bfOne, bfZero))
  dpDefault = defaultDrawParams()
  dpAdditiveBlend = defaultDrawParams().derive:
    blend additiveBlending

func sec(duration: Duration): float64 =
  duration.inNanoseconds.float64 * 1e-9

win.swapInterval = 0

var
  lastTime, lastTitleUpdate, lastFpsUpdate = getMonoTime()
  fpsCounter, fps = 0
while not win.closeRequested:
  let
    currentTime = getMonoTime()
    deltaTime = sec(currentTime - lastTime)
  lastTime = currentTime
  inc(fpsCounter)

  if inSeconds(currentTime - lastFpsUpdate) >= 1:
    fps = fpsCounter
    fpsCounter = 0
    lastFpsUpdate = getMonoTime()
  if inMilliseconds(currentTime - lastTitleUpdate) >= 250:
    let status =
      formatFloat(deltaTime * 1000, ffDecimal, precision = 1) & " ms" &
      " (" & $int(1 / deltaTime) & " \"fps\") · " & $fps & " fps"
    win.title = "tcloud — " & status
    echo status
    lastTitleUpdate = getMonoTime()

  var targetA = blurBufferA.render()
  let
    aspect = win.width / win.height
    projection = perspective(Fov.float32, aspect, 0.01, 100.0)

  targetA.clearColor(rgba(0.0, 0.0, 0.0, 1.0))
  targetA.clearDepth(1.0)
  targetA.draw(volumeProgram, mesh, uniforms {
    model: mat4f(),
    view: lookAt(eye = vec3f(0.0, 0.0, CameraRadius),
                 center = Origin,
                 up = Up)
      .rotateX(rotationX)
      .rotateY(rotationY)
      .scale(zoom),
    projection: projection,
    ?volume: volume.sampler(magFilter = fmLinear,
                            wrapS = twClampToEdge,
                            wrapT = twClampToEdge,
                            wrapR = twClampToEdge),
  }, dpAdditiveBlend)

  let blurStrength = zoom * 41.0

  var targetB = blurBufferB.render()
  targetB.clearColor(rgba(0.0, 0.0, 0.0, 1.0))
  targetB.draw(blurProgram, fullScreen, uniforms {
    source: blurBufferA.sampler(),
    blurDirection: vec2f(1.0, 0.0),
    blurSamples: blurStrength.int32,
    windowSize: win.size.vec2f,
  }, dpDefault)

  var frame = win.render()
  frame.clearColor(rgba(0.0, 0.0, 0.0, 1.0))
  frame.draw(blurProgram, fullScreen, uniforms {
    source: blurBufferB.sampler(),
    blurDirection: vec2f(0.0, 1.0),
    blurSamples: blurStrength.int32,
    windowSize: win.size.vec2f,
  }, dpDefault)

  frame.finish()

  win.pollEvents do (event: InputEvent):
    case event.kind
    of iekMousePress, iekMouseRelease:
      dragging = event.kind == iekMousePress
    of iekMouseMove:
      if dragging:
        let delta = event.mousePos - lastMousePos
        rotationX += delta.y / 100
        rotationY += delta.x / 100
      lastMousePos = event.mousePos
    of iekMouseScroll:
      zoom += event.scrollPos.y * 0.1
    of iekWindowFrameResize:
      updateBlurBuffer()
    of iekKeyPress:
      case event.key
      of keyS:
        echo "taking async screenshot…"
        defaultFb.download(rect(vec2i(0), win.size), saveScreenshot)
      else: discard
    else: discard
