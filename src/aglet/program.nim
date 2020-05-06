## Vertex/fragment/geometry shaders and shader programs.

import std/options

import gl
import window

type
  Program* = ref object
    gl: OpenGl
    id: GlUint
  ShaderError* = object of ValueError

proc newProgram(gl: OpenGl, vertexSrc, fragmentSrc: string,
                geometrySrc = ""): Program =

  new(result) do (program: Program):
    # delete the program when its lifetime is over
    program.gl.deleteProgram(program.id)

  result.gl = gl
  result.id = gl.createProgram()

  # compile all the shaders
  var errorMsg: string

  let vertex = gl.createShader(GL_VERTEX_SHADER, vertexSrc, errorMsg)
  if vertex.isNone:
    raise newException(ShaderError, "vertex compile failed: " & errorMsg)
  gl.attachShader(result.id, vertex.get)

  let fragment = gl.createShader(GL_FRAGMENT_SHADER, fragmentSrc, errorMsg)
  if fragment.isNone:
    raise newException(ShaderError, "fragment compile failed: " & errorMsg)
  gl.attachShader(result.id, fragment.get)

  let hasGeometry = geometrySrc.len > 0
  var geometry: GlUint
  if hasGeometry:
    let maybeShader = gl.createShader(GL_GEOMETRY_SHADER, geometrySrc, errorMsg)
    if maybeShader.isNone:
      raise newException(ShaderError, "geometry compile failed: " & errorMsg)
    geometry = maybeShader.get
    gl.attachShader(result.id, maybeShader.get)

  # link the program
  let linkError = gl.linkProgram(result.id)

  # we don't need the shaders anymore after linking, so delete them
  gl.deleteShader(vertex.get)
  gl.deleteShader(fragment.get)
  if hasGeometry:
    gl.deleteShader(geometry)

  if linkError.isSome:
    raise newException(ShaderError, "link failed: " & linkError.get)

proc newProgram*(win: Window, vertexSrc, fragmentSrc: string,
                 geometrySrc = ""): Program =
  ## Creates a new shader program from the given vertex and fragment shader
  ## source code. If the geometry shader's source code is not empty, it will
  ## also be compiled and linked.
  ## This can raise a ``ShaderError`` if any of the shaders fails to compile, or
  ## the program fails to link.
  var gl = win.IMPL_getGlContext()
  result = gl.newProgram(vertexSrc, fragmentSrc, geometrySrc)
