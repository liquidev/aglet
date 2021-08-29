## Base render target. Used by windows and framebuffer objects.

import glm/vec

import drawparams
import gl
import pixeltypes
import program_base
import uniform
import rect
import std/options

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

proc scissor(target: Target, scissor: Option[Recti] = Recti.none) =
  if scissor.isSome():
    let scissor = scissor.get
    target.gl.scissor(scissor.x, scissor.y, scissor.width, scissor.height)
  else:
    target.gl.scissor(0, 0, target.size.x, target.size.y)

proc clearColor*(target: Target, color: Rgba32f, scissor: Option[Recti] = Recti.none) {.inline.} =
  ## Clear the target's color with a solid color.
  ## 
  ## Optionally pass in a scissor rect to control the cleared region.
  ## By default the entire target is cleared.
  target.use()
  target.scissor(scissor)
  target.gl.clearColor(color.r, color.g, color.b, color.a)

proc clearDepth*(target: Target, depth: float32, scissor: Option[Recti] = Recti.none) {.inline.} =
  ## Clear the target's depth buffer with a single value.
  ##
  ## Optionally pass in a scissor rect to control the cleared region.
  ## By default the entire target is cleared.
  target.use()
  target.scissor(scissor)
  target.gl.clearDepth(depth)

proc clearStencil*(target: Target, stencil: int32, scissor: Option[Recti] = Recti.none) {.inline.} =
  ## Clear the target's stencil buffer with a single value.
  ##
  ## Optionally pass in a scissor rect to control the cleared region.
  ## By default the entire target is cleared.
  target.use()
  target.scissor(scissor)
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
