## Vertex/fragment/geometry shaders and shader programs.

import std/macros
import std/options
import std/tables

import gl
import uniform
import window

import program_base
export program_base

type
  ShaderError* = object of ValueError

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

proc newProgram[V](gl: OpenGl, vertexSrc, fragmentSrc: string,
                   geometrySrc = ""): Program[V] =

  new(result) do (program: Program[V]):
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

proc newProgram*[V](win: Window, vertexSrc, fragmentSrc: string,
                    geometrySrc = ""): Program[V] =
  ## Creates a new shader program from the given vertex and fragment shader
  ## source code. If the geometry shader's source code is not empty, it will
  ## also be compiled and linked.
  ## This can raise a ``ShaderError`` if any of the shaders fails to compile, or
  ## the program fails to link.
  var gl = win.IMPL_getGlContext()
  result = gl.newProgram[:V](vertexSrc, fragmentSrc, geometrySrc)
