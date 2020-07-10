## Vertex/fragment/geometry shaders and shader programs.

import std/macros
import std/options
import std/tables

import gl
import window

import program_base
export program_base

type
  GlslSource* = distinct string
    ## GLSL source code type, for extra type safety.

  ShaderError* = object of Defect

macro bindAttribLocations(gl: OpenGl, program: GlUint, T: typedesc): untyped =
  result = newStmtList()

  var index = 0
  let impl = T.getTypeImpl[1].getTypeImpl
  for identDefs in impl[2]:
    for name in identDefs[0..^3]:
      let
        indexLit = newLit(index)
        nameLit = newLit(name.repr)
      result.add(quote do:
        bindAttribLocation(`gl`, `program`, `indexLit`, `nameLit`))
      inc(index)

proc glsl*(source: string): GlslSource {.inline.} =
  ## Shorthand for constructing GLSL source code.
  result = GlslSource(source)

proc newProgram*[V](window: Window, vertexSrc, fragmentSrc: GlslSource,
                    geometrySrc = glsl""): Program[V] =
  ## Creates a new shader program from the given vertex and fragment shader
  ## source code. If the geometry shader's source code is not empty, it will
  ## also be compiled and linked.
  ## This can raise a ``ShaderError`` if any of the shaders fails to compile, or
  ## the program fails to link.

  window.IMPL_makeCurrent()

  var gl = window.IMPL_getGlContext()

  new(result) do (program: Program[V]):
    # delete the program when its lifetime is over
    program.gl.deleteProgram(program.id)

  result.gl = gl
  result.id = gl.createProgram()

  # compile all the shaders
  var errorMsg: string

  let vertex = gl.createShader(GL_VERTEX_SHADER, vertexSrc.string, errorMsg)
  if vertex.isNone:
    raise newException(ShaderError, "vertex compile failed: " & errorMsg)
  gl.attachShader(result.id, vertex.get)

  let fragment = gl.createShader(GL_FRAGMENT_SHADER,
                                 fragmentSrc.string, errorMsg)
  if fragment.isNone:
    raise newException(ShaderError, "fragment compile failed: " & errorMsg)
  gl.attachShader(result.id, fragment.get)

  let hasGeometry = geometrySrc.string.len > 0
  var geometry: GlUint
  if hasGeometry:
    let maybeShader = gl.createShader(GL_GEOMETRY_SHADER,
                                      geometrySrc.string, errorMsg)
    if maybeShader.isNone:
      raise newException(ShaderError, "geometry compile failed: " & errorMsg)
    geometry = maybeShader.get
    gl.attachShader(result.id, maybeShader.get)

  # bind attribute locations
  gl.bindAttribLocations(result.id, V)

  # link the program
  let linkError = gl.linkProgram(result.id)

  # we don't need the shaders anymore after linking, so delete them
  gl.deleteShader(vertex.get)
  gl.deleteShader(fragment.get)
  if hasGeometry:
    gl.deleteShader(geometry)

  if linkError.isSome:
    raise newException(ShaderError, "link failed: " & linkError.get)
