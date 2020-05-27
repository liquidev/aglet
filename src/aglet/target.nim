## Base render target. Used by windows and framebuffer objects.

import glm/vec

import drawparams
import gl
import program_base
import uniform

type
  Target* = ref object of RootObj
    useImpl*: proc (target: Target, gl: OpenGl)
    gl*: OpenGl  ## do not use directly

  Drawable* = concept x
    x.draw(OpenGl)

  UniformSource* = concept x
    for k, v in getUniforms(x):
      k is string
      v is Uniform

proc use(target: Target) =
  target.useImpl(target, target.gl)

proc clearColor*(target: Target, col: Vec4f) =
  ## Clear the target's color with a solid color.
  target.use()
  target.gl.clearColor(col.r, col.g, col.b, col.a)

proc clearDepth*(target: Target, depth: float32) =
  ## Clear the target's depth buffer with a single value.
  target.use()
  target.gl.clearDepth(depth)

proc clearStencil*(target: Target, stencil: int32) =
  ## Clear the target's stencil buffer with a single value.
  target.use()
  target.gl.clearStencil(stencil.GlInt)

proc draw*[D: Drawable, U: UniformSource](target: Target, program: Program,
                                          arrays: D, uniforms: U,
                                          params: DrawParams) =
  ## Draw vertices to the target, using the given shader program,
  ## using vertices from the given ``Drawable`` (most commonly a ``MeshSlice``),
  ## passing the uniforms from the provided source to the shader program.

  mixin draw
  mixin getUniforms

  target.use()

  params.IMPL_apply(target.gl)

  program.IMPL_use()
  for key, value in getUniforms(uniforms):
    program.IMPL_setUniform(key, value)

  arrays.draw(target.gl)

  target.gl.resetTextureUnitCounter()
