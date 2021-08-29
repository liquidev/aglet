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

  ClearParams = object
    color*: Option[Rgba32f]
    depth*: Option[float32]
    stencil*: Option[int32]
    scissor*: Option[Recti]

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

proc scissor(target: Target, scissor: Option[Recti]) =
  if scissor.isSome():
    let scissor = scissor.get
    target.gl.scissor(scissor.x, scissor.y, scissor.width, scissor.height)
  else:
    target.gl.scissor(0, 0, target.size.x, target.size.y)

proc defaultClearParams*(): ClearParams =
  ClearParams(
    color: rgba(0.0, 0.0, 0.0, 1.0).some(),
    depth: some(1.0.float32),
    stencil: int32.none(),
    scissor: Recti.none()
  )

proc withColor*(clearParams: ClearParams, color: Rgba32f): ClearParams =
  ## Modifies the `color` field of ClearParams and returns it.
  var clearParams = clearParams
  clearParams.color = color.some()
  clearParams

proc withDepth*(clearParams: ClearParams, depth: float32): ClearParams =
  ## Modifies the `depth` field of ClearParams and returns it.
  var clearParams = clearParams
  clearParams.depth = depth.some()
  clearParams

proc withStencil*(clearParams: ClearParams, stencil: int32): ClearParams =
  ## Modifies the `stencil` field of ClearParams and returns it.
  var clearParams = clearParams
  clearParams.stencil = stencil.some()
  clearParams

proc withScissor*(clearParams: ClearParams, scissor: Recti): ClearParams =
  ## Modifies the `scissor` field of ClearParams and returns it.
  var clearParams = clearParams
  clearParams.scissor = scissor.some()
  clearParams

proc clear*(target: Target, clearParams: ClearParams) {.inline.} =
  ## Clears the target depending on the values in the provided `ClearParams`.
  target.use()
  target.scissor(clearParams.scissor)
  
  if clearParams.color.isSome():
    let color = clearParams.color.get()
    target.gl.clearColor(color.r, color.g, color.b, color.a)

  if clearParams.depth.isSome():
    let depth = clearParams.depth.get()
    target.gl.clearDepth(depth)

  if clearParams.stencil.isSome():
    let stencil = clearParams.stencil.get()
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
