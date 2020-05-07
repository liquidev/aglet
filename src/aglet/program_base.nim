import gl

type
  Program* = ref object
    gl*: OpenGl  ## do not use these fields
    id*: GlUint

proc IMPL_use*(program: Program) =
  ## **Implementation detail, do not use.**
  program.gl.useProgram(program.id)
