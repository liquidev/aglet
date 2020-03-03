## Abstract API for OpenGL.

import macros
import strutils

type
  # opengl types
  GlBitfield* = uint32
  GlBool* = bool
  Glbyte* = int8
  GlChar* = char
  GlCharArb* = byte
  GlClampd* = float64
  GlClampf* = float32
  GlClampx* = int32
  GlDouble* = float64
  GlEglImageOes* = distinct pointer
  GlEnum* = uint32
  GlFixed* = int32
  GlFloat* = float32
  GlHalf* = uint16
  GlHalfArb* = uint16
  GlHalfNv* = uint16
  GlHandleArb* = uint32
  GlInt* = int32
  GlInt64* = int64
  GlInt64Ext* = int64
  GlIntptr* = int
  GlIntptrArb* = int
  GlShort* = int16
  GlSizei* = int32
  GlSizeiptr* = int
  GlSizeiptrArb* = int
  GlSync* = distinct pointer
  GlUbyte* = uint8
  GlUint* = uint32
  GlUint64* = uint64
  GlUint64Ext* = uint64
  GlUshort* = uint16
  GlVdpauSurfaceNv* = int32
  GlVoid* = pointer

  OpenGl* = ref object  ## the opengl API and state
    sClearColor: tuple[r, g, b, a: GlClampf]
    sClearDepth: GlClampd
    sClearStencil: GlInt
    sFramebuffers: tuple[read, draw: GlUint]
    sViewport: tuple[x, y: GlInt, w, h: GlSizei]

    glBindFramebuffer: proc (target: GLenum, framebuffer: GLuint) {.cdecl.}
    glClear: proc (targets: GlBitfield) {.cdecl.}
    glClearColor: proc (r, g, b, a: GlClampf) {.cdecl.}
    glClearDepth: proc (depth: GlClampd) {.cdecl.}
    glClearStencil: proc (stencil: GlInt) {.cdecl.}
    glViewport: proc (x, y: GlInt, width, height: GlSizei) {.cdecl.}
  FramebufferTarget* = enum
    ftRead, ftDraw

const
  GL_DEPTH_BUFFER_BIT* = 0x100
  GL_STENCIL_BUFFER_BIT* = 0x400
  GL_COLOR_BUFFER_BIT* = 0x4000
  GL_READ_FRAMEBUFFER* = 0x8CA8
  GL_DRAW_FRAMEBUFFER* = 0x8CA9

when not defined(js):
  # desktop platforms

  proc load*(gl: OpenGl, getProcAddr: proc (name: string): pointer) =
    ## Loads OpenGL procs to the given GL instance.
    ## aglet uses a custom loader because as far as I could tell, glad doesn't
    ## support loading procs to an object.
    ## This unfortunately means that the code will need to list each and
    ## every one of the GL procs it uses, but it's a good opportunity to use
    ## some macro magic so it's not that bad.

    macro genLoader(gl: OpenGl): untyped =
      result = newStmtList()
      var fields = bindSym"OpenGl".getImpl[2][0][2]
      for defs in fields:
        let
          procNameSym = defs[0]
          procName = procNameSym.repr
          procTy = defs[1]
        if procName.startsWith("gl"):
          let
            dot = newDotExpr(gl, procNameSym)
            getAddrCall = newCall("getProcAddr", newLit(procName))
            conv = newTree(nnkCast, procTy, getAddrCall)
            asgn = newAssignment(dot, conv)
          result.add(asgn)

    genLoader(gl)

else:
  discard # TODO: webgl

proc newGl*(): OpenGl =
  new(result)

template updateDiff(a, b, action: untyped) =
  if a != b:
    a = b
    action

proc viewport*(gl: OpenGl, x, y: GlInt, width, height: GlSizei) =
  updateDiff gl.sViewport, (x, y, width, height):
    gl.glViewport(x, y, width, height)

proc clearColor*(gl: OpenGl, r, g, b, a: GlClampf) =
  updateDiff gl.sClearColor, (r, g, b, a):
    gl.glClearColor(r, g, b, a)
  gl.glClear(GL_COLOR_BUFFER_BIT)

proc clearDepth*(gl: OpenGl, depth: GlClampd) =
  updateDiff gl.sClearDepth, depth:
    gl.glClearDepth(depth)
  gl.glClear(GL_DEPTH_BUFFER_BIT)

proc clearStencil*(gl: OpenGl, stencil: GlInt) =
  updateDiff gl.sClearStencil, stencil:
    gl.glClearStencil(stencil)
  gl.glClear(GL_DEPTH_BUFFER_BIT)

proc bindFramebuffer*(gl: OpenGl, targets: set[FramebufferTarget],
                      buffer: GlUint) =
  if ftRead in targets:
    updateDiff gl.sFramebuffers.read, buffer:
      gl.glBindFramebuffer(GL_READ_FRAMEBUFFER, buffer)
  if ftDraw in targets:
    updateDiff gl.sFramebuffers.draw, buffer:
      gl.glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buffer)
