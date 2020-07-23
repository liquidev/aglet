import std/tables

import gl
import uniform

type
  Program*[V] = ref object
    gl*: OpenGl  ## do not use these fields
    id*: GlUint
    uniformLocationCache: Table[string, GlInt]
    uniformValueCache: seq[Uniform]  # maps from locations to values

proc IMPL_use*(program: Program) =
  ## **Implementation detail, do not use.**
  program.gl.useProgram(program.id)

proc uniformDifferent(program: Program, location: GlInt,
                      newValue: Uniform): bool =
  ## Checks if the cached uniform value differs from the new value.

  # we don't check arrays because they may potentially be really big, which
  # can be even slower than just sending the uniform directly
  # also, we cannot cache utUSampler uniforms as using them has side effects
  if newValue.ty in utArrays + {utUSampler}:
    return true

  # value not yet cached
  if program.uniformValueCache.len <= location:
    return true

  result = program.uniformValueCache[location] != newValue

proc IMPL_setUniform*(program: Program, name: string, value: Uniform) =
  program.IMPL_use()
  let
    optional = name[0] == '?'
    name =
      if optional: name[1..^1]
      else: name
    location =
      if name in program.uniformLocationCache:
        program.uniformLocationCache[name]
      else:
        let i = program.gl.getUniformLocation(program.id, name)
        if not optional:
          assert i != -1, "uniform '" & name & "' does not exist"
        program.uniformLocationCache[name] = i
        i
  if not (optional and location == -1):
    if program.uniformDifferent(location, value):
      program.gl.uniform(location, value)
    if program.uniformValueCache.len <= location:
      program.uniformValueCache.setLen(location + 1)
    program.uniformValueCache[location] = value
