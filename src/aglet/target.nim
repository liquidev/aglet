## Base render target. Used by windows and framebuffer objects.

import glm/vec

import gl

type
  Target* = ref object of RootObj
    useImpl*: proc (target: Target, gl: OpenGl)
    gl*: OpenGl ## do not use directly

proc use(target: Target) =
  target.useImpl(target, target.gl)

proc clearColor*(target: Target, col: Vec4f) =
  target.use()
  target.gl.clearColor(col.r, col.g, col.b, col.a)

proc clearDepth*(target: Target, depth: float64) =
  target.use()
  target.gl.clearDepth(depth)

proc clearStencil*(target: Target, stencil: int) =
  target.use()
  target.gl.clearStencil(stencil.GlInt)
