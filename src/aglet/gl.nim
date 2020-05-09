## Abstract API for OpenGL.

import std/macros
import std/options
import std/strutils

import glm/vec

type
  # opengl types
  GlBitfield* = uint32
  GlBool* = bool
  GlByte* = int8
  GlChar* = char
  GlCharArb* = byte
  GlClampd* = float64
  GlClampf* = float32
  GlClampx* = int32
  GlDouble* = float64
  GlEglImageOes* = distinct pointer
  GlEnum* = distinct uint32
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

  FramebufferTarget* = enum
    ftRead, ftDraw
  BufferTarget* = enum
    btArray, btElementArray

  VertexArray* = object
    buffers: array[BufferTarget, GlUint]
    id*: GlUint

  OpenGl* = ref object  ## the opengl API and state
    # state
    sBuffers: array[BufferTarget, GlUint]
    sClearColor: tuple[r, g, b, a: GlClampf]
    sClearDepth: GlClampd
    sClearStencil: GlInt
    sFramebuffers: tuple[read, draw: GlUint]
    sProgram: GlUint
    sVertexArray: GlUint
    sViewport: tuple[x, y: GlInt, w, h: GlSizei]

    # state functions
    glBindBuffer: proc (target: GLenum, buffer: GlUint) {.cdecl.}
    glBindFramebuffer: proc (target: GlEnum, framebuffer: GlUint) {.cdecl.}
    glBindVertexArray: proc (array: GlUint) {.cdecl.}
    glClear: proc (targets: GlBitfield) {.cdecl.}
    glClearColor: proc (r, g, b, a: GlClampf) {.cdecl.}
    glClearDepth: proc (depth: GlClampd) {.cdecl.}
    glClearStencil: proc (stencil: GlInt) {.cdecl.}
    glUseProgram: proc (program: GlUint) {.cdecl.}
    glViewport: proc (x, y: GlInt, width, height: GlSizei) {.cdecl.}

    # commands
    glAttachShader: proc (program, shader: GlUint) {.cdecl.}
    glBindAttribLocation: proc (program, index: GlUint, name: cstring) {.cdecl.}
    glBufferData: proc (target: GlEnum, size: GlSizeiptr, data: pointer,
                        usage: GlEnum) {.cdecl.}
    glBufferSubData: proc (target: GlEnum, offset: GlIntptr, size: GlSizeiptr,
                           data: pointer) {.cdecl.}
    glCompileShader: proc (shader: GlUint) {.cdecl.}
    glCreateProgram: proc (): GlUint {.cdecl.}
    glCreateShader: proc (shaderType: GlEnum): GlUint {.cdecl.}
    glDeleteBuffers: proc (n: GlSizei,
                           buffers: ptr UncheckedArray[GlUint]) {.cdecl.}
    glDeleteProgram: proc (program: GlUint) {.cdecl.}
    glDeleteShader: proc (shader: GlUint) {.cdecl.}
    glDeleteVertexArrays: proc (n: GlSizei,
                                arrays: ptr UncheckedArray[GlUint]) {.cdecl.}
    glDisableVertexAttribArray: proc (index: GlUint) {.cdecl.}
    glDrawArrays: proc (mode: GlEnum, first: GlInt, count: GlSizei) {.cdecl.}
    glEnableVertexAttribArray: proc (index: GlUint) {.cdecl.}
    glGenBuffers: proc (n: GlSizei,
                        buffers: ptr UncheckedArray[GlUint]) {.cdecl.}
    glGenVertexArrays: proc (n: GlSizei,
                             arrays: ptr UncheckedArray[GlUint]) {.cdecl.}
    glGetProgramInfoLog: proc (program: GlUint, maxLen: GlSizei,
                               length: ptr GlSizei, infoLog: cstring) {.cdecl.}
    glGetProgramiv: proc (program: GlUint, pname: GlEnum,
                          params: ptr UncheckedArray[GlInt]) {.cdecl.}
    glGetShaderInfoLog: proc (shader: GlUint, maxLen: GlSizei,
                              length: ptr GlSizei, infoLog: cstring) {.cdecl.}
    glGetShaderiv: proc (shader: GlUint, pname: GlEnum,
                         params: ptr UncheckedArray[GlInt]) {.cdecl.}
    glLinkProgram: proc (program: GlUint) {.cdecl.}
    glShaderSource: proc (shader: GlUint, count: GlSizei,
                          str: cstringArray,
                          length: ptr UncheckedArray[GlInt]) {.cdecl.}
    glVertexAttribPointer: proc (index: GlUint, size: GlInt, typ: GlEnum,
                                 normalized: bool, stride: GlSizei,
                                 point: pointer) {.cdecl.}
    glVertexAttribIPointer: proc (index: GlUint, size: GlInt, typ: GlEnum,
                                  stride: GlSizei, point: pointer) {.cdecl.}

const
  GL_DEPTH_BUFFER_BIT* = GlEnum(0x100)
  GL_STENCIL_BUFFER_BIT* = GlEnum(0x400)
  GL_COLOR_BUFFER_BIT* = GlEnum(0x4000)
  GL_READ_FRAMEBUFFER* = GlEnum(0x8CA8)
  GL_DRAW_FRAMEBUFFER* = GlEnum(0x8CA9)
  GL_FRAGMENT_SHADER* = GlEnum(0x8B30)
  GL_VERTEX_SHADER* = GlEnum(0x8B31)
  GL_GEOMETRY_SHADER* = GlEnum(0x8DD9)
  GL_COMPILE_STATUS* = GlEnum(0x8B81)
  GL_LINK_STATUS* = GlEnum(0x8B82)
  GL_INFO_LOG_LENGTH* = GlEnum(0x8B84)
  GL_ARRAY_BUFFER* = GlEnum(0x8892)
  GL_ELEMENT_ARRAY_BUFFER* = GlEnum(0x8893)
  GL_STREAM_DRAW* = GlEnum(0x88E0)
  GL_STATIC_DRAW* = GlEnum(0x88E4)
  GL_DYNAMIC_DRAW* = GlEnum(0x88E8)
  GL_TBYTE* = GlEnum(0x1400)
  GL_TUNSIGNED_BYTE* = GlEnum(0x1401)
  GL_TSHORT* = GlEnum(0x1402)
  GL_TUNSIGNED_SHORT* = GlEnum(0x1403)
  GL_TINT* = GlEnum(0x1404)
  GL_TUNSIGNED_INT* = GlEnum(0x1405)
  GL_TFLOAT* = GlEnum(0x1406)
  GL_POINTS* = GlEnum(0x0000)
  GL_LINES* = GlEnum(0x0001)
  GL_LINE_LOOP* = GlEnum(0x0002)
  GL_LINE_STRIP* = GlEnum(0x0003)
  GL_TRIANGLES* = GlEnum(0x0004)
  GL_TRIANGLE_STRIP* = GlEnum(0x0005)
  GL_TRIANGLE_FAN* = GlEnum(0x0006)
  GL_LINES_ADJACENCY* = GlEnum(0x000A)
  GL_LINE_STRIP_ADJACENCY* = GlEnum(0x000B)
  GL_TRIANGLES_ADJACENCY* = GlEnum(0x000C)
  GL_TRIANGLE_STRIP_ADJACENCY* = GlEnum(0x000D)

when not defined(js):
  # desktop platforms

  proc load*(gl: OpenGl, getProcAddr: proc (name: string): pointer) =
    ## Loads OpenGL procs to the given GL instance.
    ## aglet uses a custom loader because as far as I could tell, glad doesn't
    ## support loading procs to an object.
    ## This unfortunately means that the code will need to list each and
    ## every one of the GL procs it uses, but it's a good opportunity to use
    ## some macro magic so it's not that bad.

    const
      debug = defined(aglDebugLoader)

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
          when debug:
            let debugCall = quote:
              stderr.writeLine "|agl/load| ", `procName`, ": ", `dot` != nil
              stderr.flushFile()
            result.add(debugCall)

    when debug:
      expandMacros:
        genLoader(gl)
    else:
      genLoader(gl)

else:
  discard # TODO: webgl

proc toGlEnum(target: BufferTarget): GlEnum =
  case target
  of btArray: GL_ARRAY_BUFFER
  of btElementArray: GL_ELEMENT_ARRAY_BUFFER

proc newGl*(): OpenGl =
  new(result)

template updateDiff(a, b, action: untyped) =
  if a != b:
    a = b
    action

template updateDiff(a, b: untyped): bool =
  if a != b:
    a = b
    true
  else:
    false

proc viewport*(gl: OpenGl, x, y: GlInt, width, height: GlSizei) =
  updateDiff gl.sViewport, (x, y, width, height):
    gl.glViewport(x, y, width, height)

proc clearColor*(gl: OpenGl, r, g, b, a: GlClampf) =
  updateDiff gl.sClearColor, (r, g, b, a):
    gl.glClearColor(r, g, b, a)
  gl.glClear(GL_COLOR_BUFFER_BIT.GlBitfield)

proc clearDepth*(gl: OpenGl, depth: GlClampd) =
  updateDiff gl.sClearDepth, depth:
    gl.glClearDepth(depth)
  gl.glClear(GL_DEPTH_BUFFER_BIT.GlBitfield)

proc clearStencil*(gl: OpenGl, stencil: GlInt) =
  updateDiff gl.sClearStencil, stencil:
    gl.glClearStencil(stencil)
  gl.glClear(GL_DEPTH_BUFFER_BIT.GlBitfield)

proc bindBuffer*(gl: OpenGl, target: BufferTarget, buffer: GlUint) =
  updateDiff gl.sBuffers[target], buffer:
    gl.glBindBuffer(target.toGlEnum, buffer)

proc bindFramebuffer*(gl: OpenGl, targets: set[FramebufferTarget],
                      buffer: GlUint) =
  if ftRead in targets:
    updateDiff gl.sFramebuffers.read, buffer:
      gl.glBindFramebuffer(GL_READ_FRAMEBUFFER, buffer)
  if ftDraw in targets:
    updateDiff gl.sFramebuffers.draw, buffer:
      gl.glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buffer)

proc bindVertexArray*(gl: OpenGl, vao: VertexArray) =
  var changed = false
  for target in BufferTarget:
    changed = changed or updateDiff(gl.sBuffers[target], vao.buffers[target])
  if changed or gl.sVertexArray != vao.id:
    gl.glBindVertexArray(vao.id)
    gl.sVertexArray = vao.id

proc useProgram*(gl: OpenGl, program: GlUint) =
  updateDiff gl.sProgram, program:
    gl.glUseProgram(program)

proc createShader*(gl: OpenGl, shaderType: GlEnum,
                   source: string, outError: var string): Option[GlUint] =
  var shader = gl.glCreateShader(shaderType)

  var
    cstr = allocCStringArray [source]
    len = source.len.GlInt
  gl.glShaderSource(shader, 1, cstr, cast[ptr UncheckedArray[GlInt]](addr len))
  deallocCStringArray(cstr)

  gl.glCompileShader(shader)
  var compileSuccess: GlInt
  gl.glGetShaderiv(shader, GL_COMPILE_STATUS,
                   cast[ptr UncheckedArray[GlInt]](addr compileSuccess))
  if not compileSuccess.bool:
    var
      errorLen: GlInt
      logErrorLen: GlSizei
    gl.glGetShaderiv(shader, GL_INFO_LOG_LENGTH,
                     cast[ptr UncheckedArray[GlInt]](addr errorLen))
    outError = newString(errorLen.Natural)
    gl.glGetShaderInfoLog(shader, errorLen.GlSizei, addr logErrorLen,
                          outError[0].unsafeAddr)

    gl.glDeleteShader(shader)
    result = GlUint.none
  else:
    result = some(shader)

proc createProgram*(gl: OpenGl): GlUint =
  result = gl.glCreateProgram()

proc attachShader*(gl: OpenGl, program, shader: GlUint) =
  gl.glAttachShader(program, shader)

proc bindAttribLocation*(gl: OpenGl, program: GlUint,
                         index: Natural, name: string) =
  gl.glBindAttribLocation(program, index.GlUint, name)

proc linkProgram*(gl: OpenGl, program: GlUint): Option[string] =
  gl.glLinkProgram(program)
  var linkSuccess: GlInt
  gl.glGetProgramiv(program, GL_LINK_STATUS,
                    cast[ptr UncheckedArray[GlInt]](addr linkSuccess))
  if not linkSuccess.bool:
    var
      errorLen: GlInt
      logErrorLen: GlSizei
      errorStr: string
    gl.glGetProgramiv(program, GL_INFO_LOG_LENGTH,
                      cast[ptr UncheckedArray[GlInt]](addr errorLen))
    errorStr = newString(errorLen.Natural)
    gl.glGetShaderInfoLog(program, errorLen.GlSizei, addr logErrorLen,
                          errorStr[0].unsafeAddr)
    result = some(errorStr)

proc deleteShader*(gl: OpenGl, shader: GlUint) =
  gl.glDeleteShader(shader)

proc deleteProgram*(gl: OpenGl, program: GlUint) =
  gl.glDeleteProgram(program)

proc createBuffer*(gl: OpenGl): GlUint =
  gl.glGenBuffers(1, cast[ptr UncheckedArray[GlUint]](addr result))

proc bufferData*(gl: OpenGl, target: BufferTarget,
                 size: int, data: pointer, usage: GlEnum) =
  gl.glBufferData(target.toGlEnum, size.GlSizeiptr, data, usage)

proc bufferSubData*(gl: OpenGl, target: BufferTarget,
                    where: Slice[int], data: pointer) =
  gl.glBufferSubData(target.toGlEnum, where.a.GlIntptr,
                     GlSizeiptr(where.b - where.a), data)

proc deleteBuffer*(gl: OpenGl, buffer: GlUint) =
  var buffer = buffer
  gl.glDeleteBuffers(1, cast[ptr UncheckedArray[GlUint]](addr buffer))

proc createVertexArray*(gl: OpenGl): VertexArray =
  result.buffers = gl.sBuffers
  gl.glGenVertexArrays(1, cast[ptr UncheckedArray[GlUint]](addr result.id))

proc toGlEnum(T: typedesc): GlEnum =
  when T is uint8: GL_TUNSIGNED_BYTE
  elif T is uint16: GL_TUNSIGNED_SHORT
  elif T is uint32: GL_TUNSIGNED_INT
  elif T is int8: GL_TBYTE
  elif T is int16: GL_TSHORT
  elif T is int32: GL_TINT

proc vertexAttrib*[T](gl: OpenGl, index, stride, offset: int) =
  # XXX: this proc uses literal uint32/int32 instead of the Gl* types because of
  # symbol binding weirdness with macros
  when T is Vec:
    type TT = default(T).T
  else:
    type TT = T
  const
    N =
      when T is Vec: default(T).N
      else: 1
  when TT is float32:
    gl.glVertexAttribPointer(GlUint(index), N, GL_TFLOAT,
                             normalized = false, GlSizei(stride),
                             cast[pointer](offset))
  elif TT is float64:
    # TODO: newer versions of OpenGL have this, but I'm yet to track down when
    # it was introduced. still, it's a performance trap and you most likely
    # want to use float32
    {.error: "float64 is unsupported as a vertex field type, use float32".}
  elif TT is SomeInteger and sizeof(TT) <= 4:
    gl.glVertexAttribIPointer(GlUint(index), N, T.toGlEnum,
                              GlSizei(stride), cast[pointer](offset))
  else:
    {.error: "unsupported vertex field type: <" & $T & ">".}

proc enableVertexAttrib*(gl: OpenGl, index: int) =
  gl.glEnableVertexAttribArray(index.GlUint)

proc disableVertexAttrib*(gl: OpenGl, index: int) =
  gl.glDisableVertexAttribArray(index.GlUint)

proc deleteVertexArray*(gl: OpenGl, array: VertexArray) =
  var array = array
  gl.glDeleteVertexArrays(1, cast[ptr UncheckedArray[GlUint]](addr array.id))

proc drawArrays*(gl: OpenGl, primitive: GlEnum, start, count: int) =
  gl.glDrawArrays(primitive, start.GlInt, count.GlSizei)
