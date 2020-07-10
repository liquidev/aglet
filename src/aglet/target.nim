## Base render target. Used by windows and framebuffer objects.

import glm/vec

import drawparams
import gl
import pixeltypes
import program_base
import uniform

type
  Target* = object of RootObj
    ## Rendering target interface.
    size*: Vec2i
    useImpl*: proc (target: Target, gl: OpenGl) {.nimcall.}
    gl*: OpenGl

  Drawable* = concept x
    x.draw(OpenGl)

  UniformSource* = concept x
    for k, v in getUniforms(x):
      k is string
      v is Uniform

proc use(target: Target) {.inline.} =
  target.useImpl(target, target.gl)

proc width*(target: Target): int {.inline.} =
  ## Returns the width of the target.
  target.size.x

proc height*(target: Target): int {.inline.} =
  ## Returns the height of the target.
  target.size.y

proc clearColor*(target: Target, color: Rgba32f) {.inline.} =
  ## Clear the target's color with a solid color.
  target.use()
  target.gl.clearColor(color.r, color.g, color.b, color.a)

proc clearDepth*(target: Target, depth: float32) {.inline.} =
  ## Clear the target's depth buffer with a single value.
  target.use()
  target.gl.clearDepth(depth)

proc clearStencil*(target: Target, stencil: int32) {.inline.} =
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
