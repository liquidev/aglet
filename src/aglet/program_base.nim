import std/tables

import gl
import uniform

type
  Program*[V] = ref object
    gl*: OpenGl  ## do not use these fields
    id*: GlUint
    uniformLocationCache*: Table[string, GlInt]

proc IMPL_use*(program: Program) =
  ## **Implementation detail, do not use.**
  program.gl.useProgram(program.id)

proc IMPL_setUniform*(program: Program, name: string, value: Uniform) =
  program.IMPL_use()
  let location =
    if name in program.uniformLocationCache:
      program.uniformLocationCache[name]
    else:
      let i = program.gl.getUniformLocation(program.id, name)
      assert i != -1, "uniform '" & name & "' does not exist"
      program.uniformLocationCache[name] = i
      i
  program.gl.uniform(location, value)
