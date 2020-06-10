## Abstract API for OpenGL.

import std/hashes
import std/macros
import std/options
import std/strutils
import std/sugar

import glm/mat
import glm/vec
export mat
export vec

import enums
import uniform

import gl_enum
import gl_types
export gl_enum
export gl_types

type
  # opengl types
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

  OpenGlFeature* = enum
    glfBlend
    glfColorLogicOp
    glfCullFace
    glfDepthTest
    glfDither
    glfLineSmooth
    glfMultisample
    glfPolygonSmooth
    glfPrimitiveRestart
    glfScissorTest
    glfStencilTest
    glfTextureCubeMapSeamless
    glfProgramPointSize

  VertexArray* = object
    buffers: array[BufferTarget, GlUint]
    id*: GlUint

  UniformVecProc = proc (location: GlInt, count: GlSizei,
                         value: pointer) {.cdecl.}
  UniformMatrixProc = proc (location: GlInt, count: GlSizei, transpose: GlBool,
                            value: pointer) {.cdecl.}

  OpenGl* = ref object
    ## The OpenGL API and state.
    ## This object is quite a behemoth, but that's also what OpenGL is.
    version*: string

    # state
    sBlendColor: tuple[r, g, b, a: GlClampf]
    sBlendEquation: tuple[rgb, alpha: GlEnum]
    sBlendFunc: tuple[srcRgb, destRgb, srcAlpha, destAlpha: GlEnum]
    sBuffers: array[BufferTarget, GlUint]
    sClearColor: tuple[r, g, b, a: GlClampf]
    sClearDepth: GlClampd
    sClearStencil: GlInt
    sColorMask: tuple[r, g, b, a: GlBool]
    sCullFace: GlEnum
    sDepthFunc: GlEnum
    sDepthMask: bool
    sEnabledFeatures: array[OpenGlFeature, bool]
    sFramebuffers: tuple[read, draw: GlUint]
    sFrontFace: GlEnum
    sHints: array[Hint, GlEnum]
    sLogicOp: GlEnum
    sLineWidth: GlFloat
    sPointSize: GlFloat
    sPolygonModes: array[Facing, GlEnum]
    sPrimitiveRestartIndex: GlUint
    sProgram: GlUint
    sRenderbuffer: GlUint
    sSamplerBindings: seq[GlUint]
    sScissor: tuple[x, y: GlInt, width, height: GlSizei]
    sStencilFuncs: array[Facing, tuple[fn: GlEnum, refr: GlInt, mask: GlUint]]
    sStencilMasks: array[Facing, GlUint]
    sStencilOps: array[Facing, tuple[sfail, dpfail, dppass: GlEnum]]
    sTextureUnit: int
    sTextureUnitBindings: seq[array[TextureTarget, GlUint]]
    sVertexArray: GlUint
    sViewport: tuple[x, y: GlInt, w, h: GlSizei]

    uniformTextureUnit: int
    currentDrawParamsHash*: Hash  # opt used by IMPL_apply in drawparams.nim

    # state functions
    glActiveTexture: proc (texture: GlEnum) {.cdecl.}
    glBindBuffer: proc (target: GlEnum, buffer: GlUint) {.cdecl.}
    glBindFramebuffer: proc (target: GlEnum, framebuffer: GlUint) {.cdecl.}
    glBindRenderbuffer: proc (target: GlEnum, renderbuffer: GlUint) {.cdecl.}
    glBindSampler: proc (unit, sampler: GlUint) {.cdecl.}
    glBindTexture: proc (target: GlEnum, texture: GlUint) {.cdecl.}
    glBindVertexArray: proc (array: GlUint) {.cdecl.}
    glBlendColor: proc (r, g, b, a: GlClampf) {.cdecl.}
    glBlendEquationSeparate: proc (modeRGB, modeAlpha: GlEnum) {.cdecl.}
    glBlendFuncSeparate: proc (srcRGB, destRGB: GlEnum,
                               srcAlpha, destAlpha: GlEnum) {.cdecl.}
    glClear: proc (targets: GlBitfield) {.cdecl.}
    glClearColor: proc (r, g, b, a: GlClampf) {.cdecl.}
    glClearDepth: proc (depth: GlClampd) {.cdecl.}
    glClearStencil: proc (stencil: GlInt) {.cdecl.}
    glColorMask: proc (r, g, b, a: GlBool) {.cdecl.}
    glCullFace: proc (mode: GlEnum) {.cdecl.}
    glDepthFunc: proc (fn: GlEnum) {.cdecl.}
    glDepthMask: proc (mask: GlBool) {.cdecl.}
    glDisable: proc (cap: GlEnum) {.cdecl.}
    glEnable: proc (cap: GlEnum) {.cdecl.}
    glFrontFace: proc (mode: GlEnum) {.cdecl.}
    glHint: proc (target, mode: GlEnum) {.cdecl.}
    glLineWidth: proc (width: GlFloat) {.cdecl.}
    glLogicOp: proc (opcode: GlEnum) {.cdecl.}
    glPixelStorei: proc (pname: GlEnum, param: GlInt) {.cdecl.}
    glPointSize: proc (size: GlFloat) {.cdecl.}
    glPolygonMode: proc (face, mode: GlEnum) {.cdecl.}
    glPrimitiveRestartIndex: proc (index: GlUint) {.cdecl.}
    glScissor: proc (x, y: GlInt, width, height: GlSizei) {.cdecl.}
    glStencilFuncSeparate: proc (face, fn: GlEnum, reference: GlInt,
                                 mask: GlUint) {.cdecl.}
    glStencilMaskSeparate: proc (face: GlEnum, mask: GlUint) {.cdecl.}
    glStencilOpSeparate: proc (face, sfail, dpfail, dppass: GlEnum) {.cdecl.}
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
    glDeleteFramebuffers: proc (n: GlSizei, framebuffers: pointer) {.cdecl.}
    glDeleteRenderbuffers: proc (n: GlSizei, renderbuffers: pointer) {.cdecl.}
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
    glFramebufferRenderbuffer: proc (target, attachment: GlEnum,
                                     renderbufferTarget: GlEnum,
                                     renderbuffer: GlUint) {.cdecl.}
    glFramebufferTexture1D: proc (target, attachment, texTarget: GlEnum,
                                  texture: GlUint, level: GlInt) {.cdecl.}
    glFramebufferTexture2D: proc (target, attachment, texTarget: GlEnum,
                                  texture: GlUint, level: GlInt) {.cdecl.}
    glFramebufferTextureLayer: proc (target, attachment: GlEnum,
                                     texture: GlUint,
                                     level, layer: GlInt) {.cdecl.}
    glGenBuffers: proc (n: GlSizei, buffers: pointer) {.cdecl.}
    glGenFramebuffers: proc (n: GlSizei, framebuffers: pointer) {.cdecl.}
    glGenRenderbuffers: proc (n: GlSizei, renderbuffers: pointer) {.cdecl.}
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
    glRenderbufferStorageMultisample: proc (target: GlEnum, samples: GlSizei,
                                            internalFormat: GlEnum,
                                            width, height: GlSizei) {.cdecl.}
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
    glTexImage2DMultisample: proc (target: GlEnum, samples: GlSizei,
                                   internalFormat: GlInt,
                                   width, height: GlSizei,
                                   fixedSampleLocations: GlBool) {.cdecl.}
    glTexSubImage2D: proc (target: GlEnum, level, xoffset, yoffset: GlInt,
                           width, height: GlSizei, format, typ: GlEnum,
                           data: pointer) {.cdecl.}
    glTexImage3D: proc (target: GlEnum, level, internalFormat: GlInt,
                        width, height, depth: GlSizei, border: GlInt,
                        format, kind: GlEnum, data: pointer) {.cdecl.}
    glTexImage3DMultisample: proc (target: GlEnum, samples: GlSizei,
                                   internalFormat: GlInt,
                                   width, height, depth: GlSizei,
                                   fixedSampleLocations: GlBool) {.cdecl.}
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

    # initialize default state stuff
    gl.sBlendEquation = (GL_FUNC_ADD, GL_FUNC_ADD)
    gl.sBlendFunc = (GL_ONE, GL_ZERO,
                     GL_ONE, GL_ZERO)
    gl.sCullFace = GL_BACK
    gl.sClearDepth = 1
    gl.sColorMask = (on, on, on, on)
    gl.sDepthMask = true
    gl.sEnabledFeatures[glfDither] = true
    gl.sFrontFace = GL_CCW
    gl.sLogicOp = GL_COPY
    gl.sLineWidth = 1
    gl.sPointSize = 1
    gl.sPolygonModes = [GL_FILL, GL_FILL]
    # as much as I don't like this, I don't think there's a better solution to
    # this that wouldn't require me to know the size of the window on load time
    gl.sScissor = (high(GlInt), high(GlInt), high(GlSizei), high(GlSizei))
    gl.sStencilMasks = [high(uint32), high(uint32)]

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

proc toGlEnum(feature: OpenGlFeature): GlEnum =
  # lol this is actually deprecated but I'm leaving it in anyways as I don't
  # want "just a placeholder enum value"
  case feature
  of glfBlend: GL_BLEND
  of glfColorLogicOp: GL_COLOR_LOGIC_OP
  of glfCullFace: GL_CULL_FACE
  of glfDepthTest: GL_DEPTH_TEST
  of glfDither: GL_DITHER
  of glfLineSmooth: GL_LINE_SMOOTH
  of glfMultisample: GL_MULTISAMPLE
  of glfPolygonSmooth: GL_POLYGON_SMOOTH
  of glfPrimitiveRestart: GL_PRIMITIVE_RESTART
  of glfScissorTest: GL_SCISSOR_TEST
  of glfStencilTest: GL_STENCIL_TEST
  of glfTextureCubeMapSeamless: GL_TEXTURE_CUBE_MAP_SEAMLESS
  of glfProgramPointSize: GL_PROGRAM_POINT_SIZE

proc toGlEnum*(hint: Hint): GlEnum =
  case hint
  of hintFragmentShaderDerivative: GL_FRAGMENT_SHADER_DERIVATIVE_HINT
  of hintLineSmooth: GL_LINE_SMOOTH_HINT
  of hintPolygonSmooth: GL_POLYGON_SMOOTH_HINT

proc toGlEnum*(facing: Facing): GlEnum =
  case facing
  of facingBack: GL_BACK
  of facingFront: GL_FRONT

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

proc feature*(gl: OpenGl, feature: OpenGlFeature, enabled: bool) =
  updateDiff gl.sEnabledFeatures[feature], enabled:
    if enabled: gl.glEnable(feature.toGlEnum)
    else: gl.glDisable(feature.toGlEnum)

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
  if targets == {ftRead, ftDraw}:
    updateDiff gl.sFramebuffers, (buffer, buffer):
      gl.glBindFramebuffer(GL_FRAMEBUFFER, buffer)
  elif targets == {ftRead}:
    updateDiff gl.sFramebuffers.read, buffer:
      gl.glBindFramebuffer(GL_READ_FRAMEBUFFER, buffer)
  elif targets == {ftDraw}:
    updateDiff gl.sFramebuffers.draw, buffer:
      gl.glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buffer)

  if gl.getError() == GL_INVALID_VALUE:
    raise newException(ValueError,
                       "framebuffer " & $buffer & " doesn't exist")

proc bindRenderbuffer*(gl: OpenGl, renderbuffer: GlUint) =
  updateDiff gl.sRenderbuffer, renderbuffer:
    gl.glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer)

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

proc blendColor*(gl: OpenGl, r, g, b, a: GlClampf) =
  updateDiff gl.sBlendColor, (r, g, b, a):
    gl.glBlendColor(r, g, b, a)

proc blendEquation*(gl: OpenGl, colorMode, alphaMode: GlEnum) =
  updateDiff gl.sBlendEquation, (colorMode, alphaMode):
    gl.glBlendEquationSeparate(colorMode, alphaMode)

proc blendFunc*(gl: OpenGl, srcRgb, destRgb, srcAlpha, destAlpha: GlEnum) =
  updateDiff gl.sBlendFunc, (srcRgb, destRgb, srcAlpha, destAlpha):
    gl.glBlendFuncSeparate(srcRgb, destRgb, srcAlpha, destAlpha)

proc colorMask*(gl: OpenGl, red, green, blue, alpha: GlBool) =
  updateDiff gl.sColorMask, (red, green, blue, alpha):
    gl.glColorMask(red, green, blue, alpha)

proc cullFace*(gl: OpenGl, mode: GlEnum) =
  updateDiff gl.sCullFace, mode:
    gl.glCullFace(mode)

proc depthFunc*(gl: OpenGl, function: GlEnum) =
  updateDiff gl.sDepthFunc, function:
    gl.glDepthFunc(function)

proc depthMask*(gl: OpenGl, enabled: bool) =
  updateDiff gl.sDepthMask, enabled:
    gl.glDepthMask(enabled)

proc frontFace*(gl: OpenGl, mode: GlEnum) =
  updateDiff gl.sFrontFace, mode:
    gl.glFrontFace(mode)

proc hint*(gl: OpenGl, hint: Hint, mode: GlEnum) =
  updateDiff gl.sHints[hint], mode:
    gl.glHint(hint.toGlEnum, mode)

proc logicOp*(gl: OpenGl, opcode: GlEnum) =
  updateDiff gl.sLogicOp, opcode:
    gl.glLogicOp(opcode)

proc lineWidth*(gl: OpenGl, width: GlFloat) =
  updateDiff gl.sLineWidth, width:
    gl.glLineWidth(width)

proc pointSize*(gl: OpenGl, size: GlFloat) =
  updateDiff gl.sPointSize, size:
    gl.glPointSize(size)

proc polygonMode*(gl: OpenGl, facing: Facing, mode: GlEnum) =
  updateDiff gl.sPolygonModes[facing], mode:
    gl.glPolygonMode(facing.toGlEnum, mode)

proc primitiveRestartIndex*(gl: OpenGl, index: GlUint) =
  updateDiff gl.sPrimitiveRestartIndex, index:
    gl.glPrimitiveRestartIndex(index)

proc scissor*(gl: OpenGl, x, y: GlInt, width, height: GlSizei) =
  updateDiff gl.sScissor, (x, y, width, height):
    gl.glScissor(x, y, width, height)

proc stencilFunc*(gl: OpenGl, facing: Facing, fn: GlEnum, reference: GlInt,
                  mask: GlUint) =
  updateDiff gl.sStencilFuncs[facing], (fn, reference, mask):
    gl.glStencilFuncSeparate(facing.toGlEnum, fn, reference, mask)

proc stencilMask*(gl: OpenGl, facing: Facing, mask: GlUint) =
  updateDiff gl.sStencilMasks[facing], mask:
    gl.glStencilMaskSeparate(facing.toGlEnum, mask)

proc stencilOp*(gl: OpenGl, facing: Facing,
                sfail, dpfail, dppass: GlEnum) =
  updateDiff gl.sStencilOps[facing], (sfail, dpfail, dppass):
    gl.glStencilOpSeparate(facing.toGlEnum, sfail, dpfail, dppass)

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

proc data1D*(gl: OpenGl, width: Positive, internalFormat, format, typ: GlEnum) =
  gl.glTexImage1D(GL_TEXTURE_1D, level = 0, internalFormat.GlInt,
                  width.GlSizei, border = 0, format, typ, data = nil)

proc data2D*(gl: OpenGl, target: TextureTarget, width, height: Positive,
             internalFormat, format, typ: GlEnum) =
  assert target in {ttTexture1DArray, ttTexture2D,
                    ttTextureCubeMapPosX..ttTextureCubeMapNegZ}
  gl.glTexImage2D(target.toGlEnum, level = 0, internalFormat.GlInt,
                  width.GlSizei, height.GlSizei, border = 0,
                  format, typ, data = nil)

proc data2DMS*(gl: OpenGl, width, height: Positive,
               internalFormat: GlEnum, samples: Natural,
               fixedSampleLocations: bool) =
  gl.glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, samples.GlSizei,
                             internalFormat.GlInt,
                             width.GlSizei, height.GlSizei,
                             fixedSampleLocations)

proc data3D*(gl: OpenGl, target: TextureTarget, width, height, depth: Positive,
             internalFormat, format, typ: GlEnum) =
  gl.glTexImage3D(target.toGlEnum, level = 0, internalFormat.GlInt,
                  width.GlSizei, height.GlSizei, depth.GlSizei, border = 0,
                  format, typ, data = nil)

proc data3DMS*(gl: OpenGl, width, height, depth: Positive,
               internalFormat: GlEnum, samples: Natural,
               fixedSampleLocations: bool) =
  gl.glTexImage3DMultisample(GL_TEXTURE_2D_MULTISAMPLE_ARRAY, samples.GlSizei,
                             internalFormat.GlInt,
                             width.GlSizei, height.GlSizei, depth.GlSizei,
                             fixedSampleLocations)

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

proc createFramebuffer*(gl: OpenGl): GlUint =
  gl.glGenFramebuffers(1, addr result)

proc attachRenderbuffer*(gl: OpenGl, attachment: GlEnum, renderbuffer: GlUint) =
  gl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment,
                               GL_RENDERBUFFER, renderbuffer)

proc attachTexture1D*(gl: OpenGl, attachment: GlEnum, texTarget: TextureTarget,
                      texture: GlUint, mipLevel: GlInt) =
  gl.glFramebufferTexture1D(GL_FRAMEBUFFER, attachment, texTarget.toGlEnum,
                            texture, mipLevel)

proc attachTexture2D*(gl: OpenGl, attachment: GlEnum, texTarget: TextureTarget,
                      texture: GlUint, mipLevel: GlInt) =
  gl.glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, texTarget.toGlEnum,
                            texture, mipLevel)

proc attachTextureLayer*(gl: OpenGl, attachment: GlEnum, texture: GlUint,
                         mipLevel, layer: GlInt) =
  gl.glFramebufferTextureLayer(GL_FRAMEBUFFER, attachment,
                               texture, mipLevel, layer)

proc deleteFramebuffer*(gl: OpenGl, framebuffer: GlUint) =
  var framebuffer = framebuffer
  gl.glDeleteFramebuffers(1, addr framebuffer)

proc createRenderbuffer*(gl: OpenGl): GlUint =
  gl.glGenRenderbuffers(1, addr result)

proc renderbufferStorage*(gl: OpenGl, width, height, samples: GlSizei,
                          internalFormat: GlEnum) =
  gl.glRenderbufferStorageMultisample(GL_RENDERBUFFER, samples,
                                      internalFormat, width, height)

proc deleteRenderbuffer*(gl: OpenGl, renderbuffer: GlUint) =
  var renderbuffer = renderbuffer
  gl.glDeleteRenderbuffers(1, addr renderbuffer)

proc drawArrays*(gl: OpenGl, primitive: GlEnum, start, count: int) =
  gl.glDrawArrays(primitive, start.GlInt, count.GlSizei)

proc drawElements*(gl: OpenGl, primitive: GlEnum, start, count: int,
                   indexType: GlEnum) =
  gl.glDrawElements(primitive, count.GlInt, indexType, cast[pointer](start))
