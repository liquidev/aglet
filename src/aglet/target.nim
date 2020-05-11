## Base render target. Used by windows and framebuffer objects.

import std/macros
import std/tables

import glm/vec

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
                                          arrays: D, uniforms: U) =
  ## Draw vertices to the target, using the given shader program,
  ## using vertices from the given ``Drawable`` (most commonly a ``MeshSlice``),
  ## passing the uniforms from the provided source to the shader program.

  mixin draw
  mixin getUniforms

  target.use()

  program.IMPL_use()
  for key, value in getUniforms(uniforms):
    program.IMPL_setUniform(key, value)

  arrays.draw(target.gl)

macro uniforms*(pairs: untyped): untyped =
  ## Helper macro that transforms a table constructor to a
  ## ``UniformSource``-compatible tuple. This macro is mainly useful to avoid
  ## repetitive noise by ``toUniform``, and not have to worry about remembering
  ## to add ``.toUniform`` to the end of your value.

  runnableExamples:
    let
      a = uniforms {
        constant: 10.0,
        offsetPerInstance: vec2f(2.0, 0.0),
      }
      b = (
        constant: 10'f32.toUniform,
        offsetPerInstance: vec2f(2.0, 0.0).toUniform,
      )
    assert a == b

  if pairs.kind != nnkTableConstr:
    error("table constructor expected", pairs)
  result = newPar()
  for pair in pairs:
    if pair.kind != nnkExprColonExpr:
      error("uniform pair 'a: b' expected", pair)
    let
      key = pair[0]
      value = pair[1]
    if key.kind != nnkIdent:
      error("invalid uniform name: '" & key.repr & "'", key)
    result.add(newColonExpr(key, newCall(bindSym"toUniform", value)))

iterator getUniforms*(rec: tuple | object): (string, Uniform) =
  ## Built-in helper iterator for the ``uniforms`` macro. This also allows for
  ## user-defined object types to be used as ``UniformSource``s.
  for key, value in fieldPairs(rec):
    assert value is Uniform, "all fields must be Uniforms"
    yield (key, value)

iterator getUniforms*(table: Table[string, Uniform]): (string, Uniform) =
  ## Built-in helper for ``Table``s containing ``Uniform``s.
  for key, value in table:
    yield (key, value)
