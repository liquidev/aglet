import std/tables

import gl
import uniform
import window

type
  Program*[V] = ref object
    window*: Window
    gl*: OpenGl  ## do not use these fields
    id*: GlUint
    uniformLocationCache*: Table[string, GlInt]

proc IMPL_use*(program: Program) =
  ## **Implementation detail, do not use.**
  program.window.IMPL_makeCurrent()
  program.gl.useProgram(program.id)

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
    program.gl.uniform(location, value)
