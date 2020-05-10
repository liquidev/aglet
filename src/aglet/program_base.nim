import std/tables

import gl

type
  Program*[V] = ref object
    gl*: OpenGl  ## do not use these fields
    id*: GlUint
    uniformLocationCache*: Table[string, GlInt]

proc IMPL_use*(program: Program) =
  ## **Implementation detail, do not use.**
  program.gl.useProgram(program.id)
