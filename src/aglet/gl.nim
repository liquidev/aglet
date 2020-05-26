## Abstract API for OpenGL.

import std/macros
import std/options
import std/strutils
import std/sugar

import glm/mat
import glm/vec
export mat
export vec

import uniform

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
  TextureTarget* = enum
    ttTexture1D, ttTexture1DArray
    ttTexture2D, ttTexture2DMultisample, ttTexture2DArray,
      ttTexture2DMultisampleArray
    ttTexture3D
    ttTextureCubeMapPosX, ttTextureCubeMapNegX
    ttTextureCubeMapPosY, ttTextureCubeMapNegY
    ttTextureCubeMapPosZ, ttTextureCubeMapNegZ

  OpenGlCapability* = enum
    glcTexture1D, glcTexture2D, glcTexture3D

  VertexArray* = object
    buffers: array[BufferTarget, GlUint]
    id*: GlUint

  UniformVecProc = proc (location: GlInt, count: GlSizei,
                         value: pointer) {.cdecl.}
  UniformMatrixProc = proc (location: GlInt, count: GlSizei, transpose: GlBool,
                            value: pointer) {.cdecl.}

  OpenGl* = ref object  ## the opengl API and state
    version*: string

    # state
    sBuffers: array[BufferTarget, GlUint]
    sClearColor: tuple[r, g, b, a: GlClampf]
    sClearDepth: GlClampd
    sClearStencil: GlInt
    sEnabledCapabilities: array[OpenGlCapability, bool]
    sFramebuffers: tuple[read, draw: GlUint]
    sProgram: GlUint
    sSamplerBindings: seq[GlUint]
    sTextureUnit: int
    sTextureUnitBindings: seq[array[TextureTarget, GlUint]]
    sVertexArray: GlUint
    sViewport: tuple[x, y: GlInt, w, h: GlSizei]

    uniformTextureUnit: int

    # state functions
    glActiveTexture: proc (texture: GlEnum) {.cdecl.}
    glBindBuffer: proc (target: GlEnum, buffer: GlUint) {.cdecl.}
    glBindFramebuffer: proc (target: GlEnum, framebuffer: GlUint) {.cdecl.}
    glBindSampler: proc (unit, sampler: GlUint) {.cdecl.}
    glBindTexture: proc (target: GlEnum, texture: GlUint) {.cdecl.}
    glBindVertexArray: proc (array: GlUint) {.cdecl.}
    glClear: proc (targets: GlBitfield) {.cdecl.}
    glClearColor: proc (r, g, b, a: GlClampf) {.cdecl.}
    glClearDepth: proc (depth: GlClampd) {.cdecl.}
    glClearStencil: proc (stencil: GlInt) {.cdecl.}
    glDisable: proc (cap: GlEnum) {.cdecl.}
    glEnable: proc (cap: GlEnum) {.cdecl.}
    glPixelStorei: proc (pname: GlEnum, param: GlInt) {.cdecl.}
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
    glDeleteBuffers: proc (n: GlSizei, buffers: pointer) {.cdecl.}
    glDeleteProgram: proc (program: GlUint) {.cdecl.}
    glDeleteSamplers: proc (n: GlSizei, samplers: pointer) {.cdecl.}
    glDeleteShader: proc (shader: GlUint) {.cdecl.}
    glDeleteTextures: proc (n: GlSizei, textures: pointer) {.cdecl.}
    glDeleteVertexArrays: proc (n: GlSizei, arrays: pointer) {.cdecl.}
    glDisableVertexAttribArray: proc (index: GlUint) {.cdecl.}
    glDrawArrays: proc (mode: GlEnum, first: GlInt, count: GlSizei) {.cdecl.}
    glDrawElements: proc (mode: GlEnum, count: GlSizei, kind: GlEnum,
                          indices: pointer) {.cdecl.}
    glEnableVertexAttribArray: proc (index: GlUint) {.cdecl.}
    glGenBuffers: proc (n: GlSizei, buffers: pointer) {.cdecl.}
    glGenSamplers: proc (n: GlSizei, samplers: pointer) {.cdecl.}
    glGenTextures: proc (n: GlSizei, textures: pointer) {.cdecl.}
    glGenVertexArrays: proc (n: GlSizei, arrays: pointer) {.cdecl.}
    glGenerateMipmap: proc (target: GlEnum) {.cdecl.}
    glGetError: proc (): GlEnum {.cdecl.}
    glGetProgramInfoLog: proc (program: GlUint, maxLen: GlSizei,
                               length: ptr GlSizei, infoLog: cstring) {.cdecl.}
    glGetProgramiv: proc (program: GlUint, pname: GlEnum,
                          params: pointer) {.cdecl.}
    glGetShaderInfoLog: proc (shader: GlUint, maxLen: GlSizei,
                              length: ptr GlSizei, infoLog: cstring) {.cdecl.}
    glGetShaderiv: proc (shader: GlUint, pname: GlEnum,
                         params: pointer) {.cdecl.}
    glGetString: proc (name: GlEnum): cstring {.cdecl.}
    glGetIntegerv: proc (pname: GlEnum, params: pointer) {.cdecl.}
    glGetUniformLocation: proc (program: GlUint, name: cstring): GlInt {.cdecl.}
    glLinkProgram: proc (program: GlUint) {.cdecl.}
    glSamplerParameteri: proc (sampler: GlUint, pname: GlEnum,
                               param: GlInt) {.cdecl.}
    glSamplerParameterfv: proc (sampler: GlUint, pname: GlEnum,
                                params: pointer) {.cdecl.}
    glShaderSource: proc (shader: GlUint, count: GlSizei,
                          str: cstringArray, length: pointer) {.cdecl.}
    glTexImage1D: proc (target: GlEnum, level, internalFormat: GlInt,
                        width: GlSizei, border: GlInt, format, kind: GlEnum,
                        data: pointer) {.cdecl.}
    glTexSubImage1D: proc (target: GlEnum, level, xoffset: GlInt,
                           width: GlSizei, format, typ: GlEnum,
                           data: pointer) {.cdecl.}
    glTexImage2D: proc (target: GlEnum, level, internalFormat: GlInt,
                        width, height: GlSizei, border: GlInt,
                        format, kind: GlEnum, data: pointer) {.cdecl.}
    glTexSubImage2D: proc (target: GlEnum, level, xoffset, yoffset: GlInt,
                           width, height: GlSizei, format, typ: GlEnum,
                           data: pointer) {.cdecl.}
    glTexImage2DMultisample: proc (target: GlEnum, samples: GlSizei,
                                   internalFormat: GlInt,
                                   width, height: GlSizei,
                                   fixedSampleLocations: GlBool) {.cdecl.}
    glTexImage3D: proc (target: GlEnum, level, internalFormat: GlInt,
                        width, height, depth: GlSizei, border: GlInt,
                        format, kind: GlEnum, data: pointer) {.cdecl.}
    glTexSubImage3D: proc (target: GlEnum, level: GlInt,
                           xoffset, yoffset, zoffset: GlInt,
                           width, height, depth: GlSizei, format, typ: GlEnum,
                           data: pointer) {.cdecl.}
    glUniform1fv, glUniform2fv, glUniform3fv, glUniform4fv,
      glUniform1iv, glUniform2iv, glUniform3iv, glUniform4iv,
      glUniform1uiv, glUniform2uiv, glUniform3uiv, glUniform4uiv: UniformVecProc
    glUniformMatrix2fv, glUniformMatrix3fv, glUniformMatrix4fv,
      glUniformMatrix2x3fv, glUniformMatrix3x2fv,
      glUniformMatrix2x4fv, glUniformMatrix4x2fv,
      glUniformMatrix3x4fv, glUniformMatrix4x3fv: UniformMatrixProc
    glVertexAttribPointer: proc (index: GlUint, size: GlInt, typ: GlEnum,
                                 normalized: bool, stride: GlSizei,
                                 point: pointer) {.cdecl.}
    glVertexAttribIPointer: proc (index: GlUint, size: GlInt, typ: GlEnum,
                                  stride: GlSizei, point: pointer) {.cdecl.}

const
  GL_VERSION* = GlEnum(0x1F02)
  GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS* = GlEnum(0x8B4D)
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
  GL_INVALID_ENUM* = GlEnum(0x0500)
  GL_INVALID_VALUE* = GlEnum(0x0501)
  GL_INVALID_OPERATION* = GlEnum(0x0502)
  GL_OUT_OF_MEMORY* = GlEnum(0x0505)
  GL_INVALID_FRAMEBUFFER_OPERATION* = GlEnum(0x0505)
  GL_TEXTURE_1D* = GlEnum(0x0DE0)
  GL_TEXTURE_1D_ARRAY* = GlEnum(0x8C18)
  GL_TEXTURE_2D* = GlEnum(0x0DE1)
  GL_TEXTURE_2D_ARRAY* = GlEnum(0x8C1A)
  GL_TEXTURE_2D_MULTISAMPLE* = GlEnum(0x9100)
  GL_TEXTURE_2D_MULTISAMPLE_ARRAY* = GlEnum(0x9102)
  GL_TEXTURE_3D* = GlEnum(0x806F)
  GL_TEXTURE_CUBE_MAP* = GlEnum(0x8513)
  GL_TEXTURE_CUBE_MAP_POSITIVE_X* = GlEnum(0x8515)
  GL_TEXTURE0* = GlEnum(0x84C0)
  GL_RED* = GlEnum(0x1903)
  GL_GREEN* = GlEnum(0x1904)
  GL_BLUE* = GlEnum(0x1905)
  GL_ALPHA* = GlEnum(0x1906)
  GL_RG* = GlEnum(0x8227)
  GL_RGB* = GlEnum(0x1907)
  GL_RGBA* = GlEnum(0x1908)
  GL_TEXTURE_WRAP_S* = GlEnum(0x2802)
  GL_TEXTURE_WRAP_T* = GlEnum(0x2803)
  GL_TEXTURE_WRAP_R* = GlEnum(0x8072)
  GL_REPEAT* = GlEnum(0x2901)
  GL_MIRRORED_REPEAT* = GlEnum(0x8370)
  GL_CLAMP_TO_EDGE* = GlEnum(0x812F)
  GL_CLAMP_TO_BORDER* = GlEnum(0x812D)
  GL_TEXTURE_BORDER_COLOR* = GlEnum(0x1004)
  GL_TEXTURE_COMPARE_MODE* = GlEnum(0x884C)
  GL_TEXTURE_COMPARE_FUNC* = GlEnum(0x884D)
  GL_NEAREST* = GlEnum(0x2600)
  GL_LINEAR* = GlEnum(0x2601)
  GL_NEAREST_MIPMAP_NEAREST* = GlEnum(0x2700)
  GL_LINEAR_MIPMAP_NEAREST* = GlEnum(0x2701)
  GL_NEAREST_MIPMAP_LINEAR* = GlEnum(0x2702)
  GL_LINEAR_MIPMAP_LINEAR* = GlEnum(0x2703)
  GL_TEXTURE_MAG_FILTER* = GlEnum(0x2800)
  GL_TEXTURE_MIN_FILTER* = GlEnum(0x2801)
  GL_PACK_ALIGNMENT* = GlEnum(0x0D05)
  GL_UNPACK_ALIGNMENT* = GlEnum(0x0CF5)

proc getInt(gl: OpenGl, property: GlEnum, result: ptr GlInt) =
  gl.glGetIntegerv(property, result)

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
        let procTy = defs[^2]
        for procNameSym in defs[0..^3]:
          let procName = procNameSym.repr
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

    gl.version = $gl.glGetString(GL_VERSION)

    # this is so primitive lol
    if gl.glGenSamplers == nil:
      raise newException(OSError,
                         "minimum required OpenGL version is 3.3, got " &
                         gl.version.splitWhitespace(1)[0])
    # query capabilities
    var textureUnitCount: GlInt
    gl.getInt(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, addr textureUnitCount)

    # update internal state accordingly
    gl.sSamplerBindings.setLen(textureUnitCount)
    gl.sTextureUnitBindings.setLen(textureUnitCount)

    # apply some default settings because OpenGL is weird
    gl.glPixelStorei(GL_PACK_ALIGNMENT, 1)
    gl.glPixelStorei(GL_UNPACK_ALIGNMENT, 1)

else:
  # supporting WebGL would be nice, but there are at least a few problems
  # in place:
  # - WebGL functions have different signatures and use JavaScript features such
  #   as ArrayBuffer
  # - aglet requires sampler object support, only available since WebGL 2
  #   (OpenGL ES 3)
  # I may take on this if anyone's interested, but core OpenGL is good enough
  # for me.
  {.error: "WebGL is not supported".}

proc toGlEnum(target: BufferTarget): GlEnum =
  case target
  of btArray: GL_ARRAY_BUFFER
  of btElementArray: GL_ELEMENT_ARRAY_BUFFER

proc toGlEnum(target: TextureTarget): GlEnum =
  case target
  of ttTexture1D: GL_TEXTURE_1D
  of ttTexture1DArray: GL_TEXTURE_1D_ARRAY
  of ttTexture2D: GL_TEXTURE_2D
  of ttTexture2DArray: GL_TEXTURE_2D_ARRAY
  of ttTexture2DMultisample: GL_TEXTURE_2D_MULTISAMPLE
  of ttTexture2DMultisampleArray: GL_TEXTURE_2D_MULTISAMPLE_ARRAY
  of ttTexture3D: GL_TEXTURE_3D
  of ttTextureCubeMapPosX..ttTextureCubeMapNegZ:
    let index = ord(target) - ord(ttTextureCubeMapNegX)
    GlEnum(GL_TEXTURE_CUBEMAP_POSITIVE_X.int + index)

proc toGlEnum(cap: OpenGlCapability): GlEnum =
  # lol this is actually deprecated but I'm leaving it in anyways as I don't
  # want "just a placeholder enum value"
  case cap
  of glcTexture1D: GL_TEXTURE_1D
  of glcTexture2D: GL_TEXTURE_2D
  of glcTexture3D: GL_TEXTURE_3D

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

proc getError(gl: OpenGl): GlEnum =
  gl.glGetError()

proc `==`(a, b: GlEnum): bool {.borrow.}

proc viewport*(gl: OpenGl, x, y: GlInt, width, height: GlSizei) =
  assert width >= 0, "viewport width must not be negative"
  assert height >= 0, "viewport height must not be negative"
  updateDiff gl.sViewport, (x, y, width, height):
    gl.glViewport(x, y, width, height)

proc capability*(gl: OpenGl, cap: OpenGlCapability, enabled: bool) =
  updateDiff gl.sEnabledCapabilities[cap], enabled:
    if enabled: gl.glEnable(cap.toGlEnum)
    else: gl.glDisable(cap.toGlEnum)

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
    if gl.getError() == GL_INVALID_VALUE:
      raise newException(ValueError, "buffer " & $buffer & " doesn't exist")

proc bindFramebuffer*(gl: OpenGl, targets: set[FramebufferTarget],
                      buffer: GlUint) =
  if ftRead in targets:
    updateDiff gl.sFramebuffers.read, buffer:
      gl.glBindFramebuffer(GL_READ_FRAMEBUFFER, buffer)
      if gl.getError() == GL_INVALID_VALUE:
        raise newException(ValueError,
                           "framebuffer " & $buffer & " doesn't exist")
  if ftDraw in targets:
    updateDiff gl.sFramebuffers.draw, buffer:
      gl.glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buffer)
      if gl.getError() == GL_INVALID_VALUE:
        raise newException(ValueError,
                           "framebuffer " & $buffer & " doesn't exist")

proc bindSampler*(gl: OpenGl, unit: int, sampler: GlUint) =
  if unit >= gl.sSamplerBindings.len:
    raise newException(ValueError,
                       "too many texture bindings " &
                       "(attempt to use unit " & $unit & ", max is " &
                       $(gl.sSamplerBindings.len - 1) & ")")
  updateDiff gl.sSamplerBindings[unit], sampler:
    gl.glBindSampler(unit.GlUint, sampler)

proc `textureUnit=`*(gl: OpenGl, unit: int) =
  if unit >= gl.sTextureUnitBindings.len:
    raise newException(ValueError,
                       "too many texture bindings " &
                       "(attempt to use unit " & $unit & ", max is " &
                       $(gl.sTextureUnitBindings.len - 1) & ")")
  updateDiff gl.sTextureUnit, unit:
    let unit = GlEnum(int(GL_TEXTURE0) + unit)
    gl.glActiveTexture(unit)

proc bindTexture*(gl: OpenGl, target: TextureTarget, texture: GlUint) =
  updateDiff gl.sTextureUnitBindings[gl.sTextureUnit][target], texture:
    gl.glBindTexture(target.toGlEnum, texture)

proc bindVertexArray*(gl: OpenGl, vao: VertexArray) =
  var changed = false
  for target in BufferTarget:
    changed = changed or updateDiff(gl.sBuffers[target], vao.buffers[target])
  if changed or gl.sVertexArray != vao.id:
    gl.glBindVertexArray(vao.id)
    gl.sVertexArray = vao.id
    if gl.getError() == GL_INVALID_VALUE:
      raise newException(ValueError,
                         "vertex array " & $vao.id & " doesn't exist")

proc useProgram*(gl: OpenGl, program: GlUint) =
  updateDiff gl.sProgram, program:
    gl.glUseProgram(program)
    if gl.getError() == GL_INVALID_VALUE:
      raise newException(ValueError,
                         "program " & $program & " doesn't exist")

proc createShader*(gl: OpenGl, shaderType: GlEnum,
                   source: string, outError: var string): Option[GlUint] =
  var shader = gl.glCreateShader(shaderType)

  var
    cstr = allocCStringArray [source]
    len = source.len.GlInt
  gl.glShaderSource(shader, 1, cstr, addr len)
  deallocCStringArray(cstr)

  gl.glCompileShader(shader)
  var compileSuccess: GlInt
  gl.glGetShaderiv(shader, GL_COMPILE_STATUS, addr compileSuccess)
  if not compileSuccess.bool:
    var
      errorLen: GlInt
      logErrorLen: GlSizei
    gl.glGetShaderiv(shader, GL_INFO_LOG_LENGTH, addr errorLen)
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
  gl.glGetProgramiv(program, GL_LINK_STATUS, addr linkSuccess)
  if not linkSuccess.bool:
    var
      errorLen: GlInt
      logErrorLen: GlSizei
      errorStr: string
    gl.glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr errorLen)
    errorStr = newString(errorLen.Natural)
    gl.glGetShaderInfoLog(program, errorLen.GlSizei, addr logErrorLen,
                          errorStr[0].unsafeAddr)
    result = some(errorStr)

proc getUniformLocation*(gl: OpenGl, program: GlUint, name: string): GlInt =
  gl.glGetUniformLocation(program, name)

proc resetTextureUnitCounter*(gl: OpenGl) =
  gl.uniformTextureUnit = 0

macro uniformAux(gl, loc, u: untyped) =
  result = newStmtList()

  var cases = newTree(nnkCaseStmt, newDotExpr(u, ident"ty"))
  for utype in UniformType:
    if utype == utUSampler:
      let impl = quote do:
        let usampler = `u`.valUSampler
        `gl`.textureUnit = `gl`.uniformTextureUnit
        `gl`.bindTexture(usampler.textureTarget.TextureTarget,
                         usampler.textureId)
        `gl`.bindSampler(`gl`.uniformTextureUnit, usampler.samplerId)
        var uniformValue = `gl`.uniformTextureUnit.GlInt
        `gl`.glUniform1iv(`loc`, 1, addr uniformValue)
        inc(`gl`.uniformTextureUnit)
      cases.add(newTree(nnkOfBranch, ident($utype), impl))
    else:
      let
        typeName = ($utype)[2..^1]
        flatName = typeName.dup(removeSuffix("Array"))
        uniformName =
          if flatName == "Float32": "1f"
          elif flatName == "Int32": "1i"
          elif flatName == "Uint32": "1ui"
          elif flatName.startsWith("Vec"): flatName[3..^1]
          elif flatName.startsWith("Mat"): "Matrix" & flatName[3..^1]
          else: ""
        glProc = newDotExpr(gl, ident("glUniform" & uniformName & "v"))
        value = newDotExpr(u, ident("val" & typeName))
        valuePtr =
          if typeName.endsWith("Array"):
            newCall("unsafeAddr", newTree(nnkBracketExpr, value, newLit(0)))
          elif uniformName[0] == '1':
            newCall("unsafeAddr", value)
          else:
            newCall("caddr", value)
        count =
          if typeName.endsWith("Array"):
            newCall("GlInt", newCall("len", value))
          else:
            newLit(1)
        call =
          if uniformName[0] == 'M':  # MatrixNxMfv
            newCall(glProc, loc, count, newLit(false), valuePtr)
          else:
            newCall(glProc, loc, count, valuePtr)
      cases.add(newTree(nnkOfBranch, ident($utype), call))

  result.add(cases)

proc uniform*(gl: OpenGl, loc: GlInt, u: Uniform) =
  var u = u
  uniformAux(gl, loc, u)

proc deleteShader*(gl: OpenGl, shader: GlUint) =
  gl.glDeleteShader(shader)

proc deleteProgram*(gl: OpenGl, program: GlUint) =
  gl.glDeleteProgram(program)

proc createBuffer*(gl: OpenGl): GlUint =
  gl.glGenBuffers(1, addr result)

proc bufferData*(gl: OpenGl, target: BufferTarget,
                 size: int, data: pointer, usage: GlEnum) =
  gl.glBufferData(target.toGlEnum, size.GlSizeiptr, data, usage)

proc bufferSubData*(gl: OpenGl, target: BufferTarget,
                    where: Slice[int], data: pointer) =
  gl.glBufferSubData(target.toGlEnum, where.a.GlIntptr,
                     GlSizeiptr(where.b - where.a), data)

proc deleteBuffer*(gl: OpenGl, buffer: GlUint) =
  var buffer = buffer
  gl.glDeleteBuffers(1, addr buffer)

proc createVertexArray*(gl: OpenGl): VertexArray =
  result.buffers = gl.sBuffers
  gl.glGenVertexArrays(1, addr result.id)

proc toGlEnum(T: typedesc): GlEnum =
  when T is uint8: GL_TUNSIGNED_BYTE
  elif T is uint16: GL_TUNSIGNED_SHORT
  elif T is uint32: GL_TUNSIGNED_INT
  elif T is int8: GL_TBYTE
  elif T is int16: GL_TSHORT
  elif T is int32: GL_TINT

proc vertexAttrib*[T](gl: OpenGl, index, stride, offset: int) =
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
  gl.glDeleteVertexArrays(1, addr array.id)

proc createTexture*(gl: OpenGl): GlUint =
  gl.glGenTextures(1, addr result)

proc data1D*(gl: OpenGl, width: Positive, format, typ: GlEnum) =
  gl.glTexImage1D(GL_TEXTURE_1D, level = 0, format.GlInt, width.GlSizei,
                  border = 0, format, typ, data = nil)

proc data2D*(gl: OpenGl, target: TextureTarget, width, height: Positive,
             format, typ: GlEnum) =
  assert target in {ttTexture1DArray, ttTexture2D,
                    ttTextureCubeMapPosX..ttTextureCubeMapNegZ}
  gl.glTexImage2D(target.toGlEnum, level = 0, format.GlInt,
                  width.GlSizei, height.GlSizei, border = 0,
                  format, typ, data = nil)

proc data3D*(gl: OpenGl, target: TextureTarget, width, height, depth: Positive,
             format, typ: GlEnum) =
  gl.glTexImage3D(target.toGlEnum, level = 0, format.GlInt,
                  width.GlSizei, height.GlSizei, depth.GlSizei, border = 0,
                  format, typ, data = nil)

proc subImage1D*(gl: OpenGl, x: Natural, width: Positive,
                 format, typ: GlEnum, data: pointer) =
  gl.glTexSubImage1D(GL_TEXTURE_1D, level = 0, x.GlInt, width.GlSizei,
                     format, typ, data)

proc subImage2D*(gl: OpenGl, target: TextureTarget,
                 x, y: Natural, width, height: Positive,
                 format, typ: GlEnum, data: pointer) =
  assert target in {ttTexture1DArray, ttTexture2D,
                    ttTextureCubeMapPosX..ttTextureCubeMapNegZ}
  gl.glTexSubImage2D(target.toGlEnum, level = 0,
                     x.GlInt, y.GlInt, width.GlSizei, height.GlSizei,
                     format, typ, data)

proc subImage3D*(gl: OpenGl, target: TextureTarget,
                 x, y, z: Natural, width, height, depth: Positive,
                 format, typ: GlEnum, data: pointer) =
  assert target in {ttTexture2DArray, ttTexture3D}
  gl.glTexSubImage3D(target.toGlEnum, level = 0,
                     x.GlInt, y.GlInt, z.GlInt,
                     width.GlSizei, height.GlSizei, depth.GlSizei,
                     format, typ, data)

proc genMipmaps*(gl: OpenGl, target: TextureTarget) =
  gl.glGenerateMipmap(target.toGlEnum)

proc deleteTexture*(gl: OpenGl, texture: GlUint) =
  var texture = texture
  gl.glDeleteTextures(1, addr texture)

proc createSampler*(gl: OpenGl): GlUint =
  gl.glGenSamplers(1, addr result)

proc samplerParam*(gl: OpenGl, sampler: GlUint, param: GlEnum, value: GlInt) =
  gl.glSamplerParameteri(sampler, param, value)

proc samplerParam*(gl: OpenGl, sampler: GlUint, param: GlEnum,
                    value: ptr GlFloat) =
  gl.glSamplerParameterfv(sampler, param, value)

proc deleteSampler*(gl: OpenGl, sampler: GlUint) =
  var sampler = sampler
  gl.glDeleteSamplers(1, addr sampler)

proc drawArrays*(gl: OpenGl, primitive: GlEnum, start, count: int) =
  gl.glDrawArrays(primitive, start.GlInt, count.GlSizei)

proc drawElements*(gl: OpenGl, primitive: GlEnum, start, count: int,
                   indexType: GlEnum) =
  gl.glDrawElements(primitive, count.GlInt, indexType, cast[pointer](start))
