## Draw parameters, used for draw() in the ``rarget`` module.

import std/hashes
import std/macros
import std/options

import glm/vec

import enums
import gl
import rect

export enums

# this module is one of the few places where I decided to use abbreviated names
# to fit into 80 columns easier. we're not glium :)

type
  BlendEquation* = enum
    ## Base blend equation to be used in blending.
    beAdd              ## src * srcFactor + dest * destFactor
    beSubtract         ## src * srcFactor - dest * destFactor
    beReverseSubtract  ## dest * destFactor - src * srcFactor
    beMin              ## min(src, dest)
    beMax              ## max(src, dest)
  BlendFactor* = enum
    ## Factors used in blend equations (suffixed with ``Factor``).
    ## First column is color, second column is alpha.
    bfZero                ## (0, 0, 0)              | 0
    bfOne                 ## (1, 1, 1)              | 1
    bfSrcColor            ## src.rgb                | src.a
    bfOneMinusSrcColor    ## (1, 1, 1) - src.rgb    | 1 - src.a
    bfDestColor           ## dest.rgb               | dest.a
    bfOneMinusDestColor   ## (1, 1, 1) - dest.rgb   | 1 - dest.a
    bfSrcAlpha            ## src.a                  | src.a
    bfSrcAlphaSaturate    ## min(src.a, 1 - dest.a) | 1
    bfOneMinusSrcAlpha    ## 1 - src.a              | 1 - src.a
    bfDestAlpha           ## dest.a                 | dest.a
    bfOneMinusDestAlpha   ## 1 - dest.a             | 1 - dest.a
    bfConstColor          ## constant.rgb           | constant.a
    bfOneMinusConstColor  ## 1 - constant.rgb       | 1 - constant.a
    bfConstAlpha          ## const.a                | constant.a
    bfOneMinusConstAlpha  ## 1 - const.a            | 1 - constant.a
  BlendFunc* = object
    ## A blending function.
    case equation: BlendEquation
    of beAdd, beSubtract, beReverseSubtract:
      src, dest: BlendFactor
    of beMin, beMax: discard
  BlendMode* = object
    ## Blending mode. For each fragment that is rendered, if enabled, blending
    ## is performed using the specified blend functions separately for the color
    ## and alpha components.
    color, alpha: BlendFunc
    constant: Vec4f

  ColorLogic* = enum
    ## Logic operation to apply to color buffers. This does not work for
    ## ``float`` framebuffers.
    ## ``s`` = source, ``d`` = destination. Nim operators are used.
    clClear         ## 0
    clSet           ## 1
    clCopy          ## s
    clCopyInverted  ## not s
    clNoop          ## d
    clInvert        ## not d
    clAnd           ## s and d
    clNand          ## not (s and d)
    clOr            ## s or d
    clNor           ## not (s or d)
    clXor           ## s xor d
    clEquiv         ## not (s xor d)
    clAndReverse    ## s and not d
    clAndInverted   ## not s and d
    clOrReverse     ## s or not d
    clOrInverted    ## not s or d

  CompareFunc* = enum
    ## Equation for checking if the stencil test passes.
    ## Nim operators are used.
    cfNever         ## false
    cfLess          ## (reference and mask) <  (stencil and mask)
    cfLessEqual     ## (reference and mask) <= (stencil and mask)
    cfGreater       ## (reference and mask) >  (stencil and mask)
    cfGreaterEqual  ## (reference and mask) >= (stencil and mask)
    cfEqual         ## (reference and mask) == (stencil and mask)
    cfNotEqual      ## (reference and mask) != (stencil and mask)
    cfAlways        ## true
  StencilFunc* = object
    ## Function for stencil testing. Refer to ``StencilEquation`` for details on
    ## how each individual ``equation`` value works.
    equation: CompareFunc  ## the equation to apply
    reference: int32       ## reference value
    mask: uint32
      ## bitmask with which ``reference`` and ``stencil`` are ANDed when testing
  StencilAction* = enum
    ## Action to take on a given stencil condition
    ## (pass, depth fail, depth pass).
    saKeep     ## keep value in stencil buffer
    saZero     ## set the value to 0
    saReplace
      ## replace the value with ``reference`` value from ``StencilFunc``
    saInc      ## increment value with clamping on overflow
    saIncWrap  ## increment value with wrapping on overflow
    saDec      ## decrement value with clamping on underflow
    saDecWrap  ## decrement value with wrapping on underflow
    saInvert   ## bitwise invert the value
  StencilOp* = object
    ## Set of stencil operations for cases when the stencil test fails or passes
    ## and the depth test fails or passes.
    stencilFail: StencilAction
      ## action to take when stencil test fails
    stencilPassDepthFail: StencilAction
      ## action to take when stencil test passes but depth test fails
    stencilPassDepthPass: StencilAction
      ## action to take when stencil test passes and depth test passes
  StencilMode* = object
    ## Stencil buffer operation mode.
    funcs: array[Facing, StencilFunc]  ## functions for individual facings
    ops: array[Facing, StencilOp]      ## operations for individual facings
    masks: array[Facing, uint32]       ## bitmasks for write operations

  PolygonMode* = enum
    ## Mode used for polygon rendering.
    pmPoint  ## draw individual vertices
    pmLine   ## draw vertices connected with lines
    pmFill   ## draw filled shape

  ColorMask* = tuple
    ## Mask specifying which color channels are to be written to when rendering.
    red, green, blue, alpha: bool

  DrawParamsVal = object
    blend: Option[BlendMode]
    colorLogicOp: Option[ColorLogic]
    colorMask: ColorMask
    depthMask: bool
    depthTest: bool
    dither: bool
    faceCulling: set[Facing]
    frontFace: Winding
    hints: array[Hint, HintValue]
    lineSmooth: bool
    lineWidth: float32
    multisample: bool
    pointSize: float32
    polygonMode: array[Facing, PolygonMode]
    polygonSmooth: bool
    primitiveRestartIndex: Option[uint32]
    programPointSize: bool
    scissor: Option[Recti]
    stencilMode: Option[StencilMode]
    seamlessCubeMap: bool
  DrawParams* = object
    ## A set of draw parameters. These are used to specify how a mesh is drawn,
    ## what features to enable, etc.
    hash: Hash          ## hash of ``val`` used for optimization purposes
    val: DrawParamsVal  ## actual draw parameters

proc blendMode*(color: BlendFunc, alpha = color,
                constant = vec4f(0.0)): BlendMode =
  ## Construct a blend mode.
  BlendMode(
    color: color,
    alpha: alpha,
    constant: constant,
  )

proc blendAdd*(src, dest: BlendFactor): BlendFunc =
  ## Construct an addition blend function. Check ``BlendFunc`` for reference.
  BlendFunc(
    equation: beAdd,
    src: src,
    dest: dest,
  )

proc blendSub*(src, dest: BlendFactor): BlendFunc =
  ## Construct a subtraction blend function.
  BlendFunc(
    equation: beSubtract,
    src: src,
    dest: dest,
  )

proc blendRevSub*(src, dest: BlendFactor): BlendFunc =
  ## Construct a reverse subtraction blend function.
  BlendFunc(
    equation: beReverseSubtract,
    src: src,
    dest: dest,
  )

const
  blendMin* = BlendFunc(equation: beMin)
    ## beMin blend equation. This is a constant because the equation requires no
    ## parameters.
  blendMax* = BlendFunc(equation: beMax)
    ## beMax blend equation.

proc stencilMode*(funcs: array[Facing, StencilFunc],
                  ops: array[Facing, StencilOp],
                  masks: array[Facing, uint32] =
                    [high(uint32), high(uint32)]): StencilMode =
  ## Constructs a stencil mode using the provided stencil functions and
  ## operations.
  StencilMode(
    funcs: funcs,
    ops: ops,
    masks: masks,
  )

proc stencilMode*(funcBoth: StencilFunc, opBoth: StencilOp,
                  maskBoth = high(uint32)): StencilMode =
  ## Constructs a stencil mode. ``funcBoth`` and ``opBoth`` are used both for
  ## front and back faces.
  StencilMode(
    funcs: [funcBoth, funcBoth],
    ops: [opBoth, opBoth],
    masks: [maskBoth, maskBoth],
  )

proc stencilFunc*(equation: CompareFunc, reference: int32,
                  mask = high(uint32)): StencilFunc =
  ## Constructs a stencil test function using the given equation,
  ## reference value, and optional bitmask.
  StencilFunc(
    equation: equation,
    reference: reference,
    mask: mask,
  )

proc stencilOp*(stencilFail, stencilPassDepthFail,
                stencilPassDepthPass: StencilAction): StencilOp =
  ## Constructs a stencil operation from the given parameters.
  StencilOp(
    stencilFail: stencilFail,
    stencilPassDepthFail: stencilPassDepthFail,
    stencilPassDepthPass: stencilPassDepthPass,
  )

using
  params: var DrawParams

proc blend*(params; mode: BlendMode) =
  ## Enables blending. If enabled, each fragment to be drawn (source) is blended
  ## with fragments already in the framebuffer (destination). Refer to
  ## ``BlendMode`` for more details.
  ##
  ## **Default:** disabled
  params.val.blend = some(mode)

proc noBlend*(params) =
  ## Disables blending.
  ##
  ## **Default:** disabled
  params.val.blend = BlendMode.none

proc noColorLogicOp*(params) =
  ## Disables color logic operations.
  ##
  ## **Default:** disabled
  params.val.colorLogicOp = ColorLogic.none

proc colorLogicOp*(params; op: ColorLogic) =
  ## Enables color logic operations.
  ##
  ## **Default:** disabled
  params.val.colorLogicOp = ColorLogic.none

proc colorMask*(params; red, green, blue, alpha: bool) =
  ## Sets the color mask.
  ##
  ## **Default:** ``(on, on, on, on)``
  params.val.colorMask = (red, green, blue, alpha)

proc depthMask*(params; enabled: bool) =
  ## Enables or disables writing to the depth buffer.
  ## Depth testing is still performed if ``enabled == false``, but new depth
  ## fragments are not written.
  ##
  ## **Default:** ``on``
  params.val.depthMask = enabled

proc depthTest*(params; enabled: bool) =
  ## Enables or disables depth testing.
  ##
  ## **Default:** ``off``
  params.val.depthTest = enabled

proc dither*(params; enabled: bool) =
  ## Enables or disables dithering.
  ##
  ## **Default:** ``on``
  params.val.dither = enabled

proc faceCulling*(params; facings: set[Facing]) =
  ## Enables or disables face culling.
  ##
  ## **Default:** disabled
  params.val.faceCulling = facings

proc frontFace*(params; winding: Winding) =
  ## Sets the front face winding direction.
  ##
  ## **Default:** ``windingCounterclockwise``
  params.val.frontFace = winding

proc hint*(params; hint: Hint, value: HintValue) =
  ## Sets an implementation-defined hint.
  ##
  ## **Defaults:**
  ## - ``hintFragmentShaderDerivative``: ``hvDontCare``
  ## - ``hintLineSmooth``: ``hvDontCare``
  ## - ``hintPolygonSmooth``: ``hvDontCare``
  params.val.hints[hint] = value

proc lineSmooth*(params; enabled: bool) =
  ## Enables or disables line antialiasing. This feature can be used without
  ## multisampling.
  ##
  ## **Default:** ``off``
  params.val.lineSmooth = enabled

proc lineWidth*(params; width: float32) =
  ## Sets the line width. The allowed range of values is implementation-defined,
  ## and the only width guaranteed to be supported is 1.
  ##
  ## **Default:** 1
  params.val.lineWidth = width

proc multisample*(params; enabled: bool) =
  ## Enables or disables multisample anti-aliasing (MSAA).
  ## Keep in mind that the target must have a multisample capable framebuffer.
  ## This can be enabled for the default framebuffer when creating the window,
  ## or when creating a 2D framebuffer texture. Keep in mind that the default
  ## framebuffer is not guaranteed to support multisampling, so it's always
  ## safer to use a texture when you *depend* on MSAA, but multisampling is
  ## available on pretty much all modern hardware no matter the framebuffer.
  ##
  ## **Default:** ``off``
  params.val.multisample = enabled

proc pointSize*(params; size: float32) =
  ## Specifies the radius of rasterized points.
  ##
  ## **Default:** 1
  params.val.pointSize = size

proc programPointSize*(params; enabled: bool) =
  ## Enables or disables setting the point size via shader programs.
  ## Enabling this will make rasterization respect the ``gl_PointSize`` variable
  ## from vertex and geometry shaders.
  params.val.programPointSize = enabled

proc polygonMode*(params; facings: set[Facing], mode: PolygonMode) =
  ## Sets the polygon rasterization mode.
  ##
  ## **Defaults:**
  ## - ``facingFront``: ``pmFill``
  ## - ``facingBack``: ``pmFill``
  for facing in facings:
    params.val.polygonMode[facing] = mode

proc polygonSmooth*(params; enabled: bool) =
  ## Enables or disables polygon antialiasing. This feature can be used without
  ## multisampling.
  ## Alpha blending must be enabled and polygons must be sorted from front to
  ## back to produce correct results.
  ##
  ## **Default:** ``off``
  params.val.lineSmooth = enabled

proc primitiveRestartIndex*(params; index: uint32) =
  ## Enables the primitive restart index. The usage of this index in any mesh
  ## will cause the current primitive to be restarted. This is useful for
  ## line strips, line loops, triangle fans, and triangle strips.
  ##
  ## **Default:** disabled
  params.val.primitiveRestartIndex = some(index)

proc noPrimitiveRestartIndex*(params) =
  ## Disables the primitive restart index.
  ##
  ## **Default:** disabled
  params.val.primitiveRestartIndex = uint32.none

proc scissor*(params; rect: Recti) =
  ## Enables scissor testing. If enabled, the scissor test discards all
  ## fragments outside of the provided ``rect``.
  ##
  ## **Default:** disabled
  params.val.scissor = some(rect)

proc noScissor*(params) =
  ## Disables scissor testing.
  ##
  ## **Default:** disabled
  params.val.scissor = Recti.none

proc stencil*(params; mode: StencilMode) =
  ## Enables stencil testing. If enabled, a per-fragment stencil test is
  ## performed. Fragments that don't pass the test are discarded. Refer to
  ## ``StencilMode``'s documentation for details.
  ##
  ## **Default:** disabled
  params.val.stencilMode = some(mode)

proc noStencil*(params) =
  ## Disables stencil testing.
  ##
  ## **Default:** disabled
  params.val.stencilMode = StencilMode.none

proc seamlessCubeMapSampling*(params; enabled: bool) =
  ## Enables or disables seamless cubemap sampling. This parameter enables
  ## blending of cubemap edges, making the cubemap seamless.
  ##
  ## **Default:** disabled
  params.val.seamlessCubeMap = enabled

proc finish*(params) =
  ## Finalizes construction of draw parameters by re-hashing them.
  ## This step is **very important**. aglet keeps a hash of the draw parameters
  ## for optimization purposes (so that the parameters don't have to be
  ## re-written every single time ``draw()`` is called, and comparisons between
  ## previously used draw parameters and the current ones are fast). If this
  ## procedure is not called, things will most likely break when using multiple
  ## sets of draw parameters.
  params.hash = hashData(addr params, sizeof(params))

proc `==`*(a, b: DrawParams): bool =
  ## Compares two sets of draw parameters by their hash.
  a.hash == b.hash

proc defaultDrawParams*(): DrawParams

macro derive*(params: DrawParams, body: untyped): untyped =
  ## A macro for making param deriving nice. Creates a block with a temporary
  ## variable ``params``, and prepends it to the arguments of every single call
  ## in the block. Finally, adds a call to ``finish(params)``.

  runnableExamples:
    let
      cool = defaultDrawParams().derive:
        multisample on
        depthTest on
      lame = block:
        var p = defaultDrawParams()
        p.multisample on
        p.depthTest on
        p.finish
        p
    assert cool == lame

  var stmts = newStmtList()

  var paramsSym = genSym(nskVar, "params")
  stmts.add(newVarStmt(paramsSym, params))

  for call in body:
    var call = call
    call.expectKind({nnkCall, nnkCommand, nnkIdent})
    if call.kind == nnkIdent:
      call = newCall(call, paramsSym)
    else:
      call.insert(1, paramsSym)
    stmts.add(call)

  stmts.add(newCall(bindSym"finish", paramsSym))
  stmts.add(paramsSym)

  result = newBlockStmt(stmts)

proc defaultDrawParams*(): DrawParams =
  ## Returns a set of draw parameters matching that described in procedure
  ## descriptions. These parameters also match the default settings of OpenGL,
  ## as specified in the official documentation.

  result = DrawParams().derive:
    # hints
    hint hintFragmentShaderDerivative, hvDontCare
    hint hintLineSmooth, hvDontCare
    hint hintPolygonSmooth, hvDontCare
    # mesh
    faceCulling {}
    frontFace windingCounterclockwise
    noPrimitiveRestartIndex
    # fragment tests
    colorMask on, on, on, on
    depthMask on
    noStencil
    noScissor
    depthTest off
    # rasterization
    lineWidth 1
    pointSize 1
    programPointSize off
    polygonMode {facingFront, facingBack}, pmFill
    # blending
    noBlend
    noColorLogicOp
    # quality
    dither on
    multisample off
    seamlessCubeMapSampling off

proc toGlEnum(blendEquation: BlendEquation): GlEnum =
  case blendEquation
  of beAdd: GL_FUNC_ADD
  of beSubtract: GL_FUNC_SUBTRACT
  of beReverseSubtract: GL_FUNC_REVERSE_SUBTRACT
  of beMin: GL_MIN
  of beMax: GL_MAX

proc toGlEnum(blendFactor: BlendFactor): GlEnum =
  case blendFactor
  of bfZero: GL_ZERO
  of bfOne: GL_ONE
  of bfSrcColor: GL_SRC_COLOR
  of bfOneMinusSrcColor: GL_ONE_MINUS_SRC_COLOR
  of bfDestColor: GL_DST_COLOR
  of bfOneMinusDestColor: GL_ONE_MINUS_DST_COLOR
  of bfSrcAlpha: GL_SRC_ALPHA
  of bfSrcAlphaSaturate: GL_SRC_ALPHA_SATURATE
  of bfOneMinusSrcAlpha: GL_ONE_MINUS_SRC_ALPHA
  of bfDestAlpha: GL_DST_ALPHA
  of bfOneMinusDestAlpha: GL_ONE_MINUS_DST_ALPHA
  of bfConstColor: GL_CONSTANT_COLOR
  of bfOneMinusConstColor: GL_ONE_MINUS_CONSTANT_COLOR
  of bfConstAlpha: GL_CONSTANT_ALPHA
  of bfOneMinusConstAlpha: GL_ONE_MINUS_CONSTANT_ALPHA

proc toGlEnum(colorLogic: ColorLogic): GlEnum =
  case colorLogic
  of clClear: GL_CLEAR
  of clSet: GL_SET
  of clCopy: GL_COPY
  of clCopyInverted: GL_COPY_INVERTED
  of clNoop: GL_NOOP
  of clInvert: GL_INVERT
  of clAnd: GL_AND
  of clNand: GL_NAND
  of clOr: GL_OR
  of clNor: GL_NOR
  of clXor: GL_XOR
  of clEquiv: GL_EQUIV
  of clAndReverse: GL_AND_REVERSE
  of clAndInverted: GL_AND_INVERTED
  of clOrReverse: GL_OR_REVERSE
  of clOrInverted: GL_OR_INVERTED

proc toGlEnum(compareFunc: CompareFunc): GlEnum =
  case compareFunc
  of cfNever: GL_NEVER
  of cfLess: GL_LESS
  of cfLessEqual: GL_LEQUAL
  of cfGreater: GL_GREATER
  of cfGreaterEqual: GL_GEQUAL
  of cfEqual: GL_EQUAL
  of cfNotEqual: GL_NOTEQUAL
  of cfAlways: GL_ALWAYS

proc toGlEnum(stencilAction: StencilAction): GlEnum =
  case stencilAction
  of saKeep: GL_KEEP
  of saZero: GL_ZERO
  of saReplace: GL_REPLACE
  of saInc: GL_INCR
  of saIncWrap: GL_INCR_WRAP
  of saDec: GL_DECR
  of saDecWrap: GL_DECR_WRAP
  of saInvert: GL_INVERT

proc toGlEnum(hintValue: HintValue): GlEnum =
  case hintValue
  of hvDontCare: GL_DONT_CARE
  of hvFastest: GL_FASTEST
  of hvNicest: GL_NICEST

proc toGlEnum(polygonMode: PolygonMode): GlEnum =
  case polygonMode
  of pmFill: GL_FILL
  of pmLine: GL_LINE
  of pmPoint: GL_POINT

proc IMPL_apply*(params: DrawParams, gl: OpenGl) =
  ## Apply the given draw parameters to the GL context.
  ## **Implementation detail, do not use.**

  # big optimization: update the state only if the hash is different.
  # yes, this does lead to more convoluted code but the extra speed is worth it
  if gl.currentDrawParamsHash != params.hash:
    gl.currentDrawParamsHash = params.hash

    let p = params.val

    gl.capability(glcBlend, p.blend.isSome)
    if p.blend.isSome:
      let blend = p.blend.get
      gl.blendColor(blend.constant.r, blend.constant.g, blend.constant.g,
                    blend.constant.a)
      gl.blendEquation(blend.color.equation.toGlEnum,
                       blend.alpha.equation.toGlEnum)
      if blend.color.equation in {beAdd, beSubtract, beReverseSubtract}:
        gl.blendFunc(blend.color.src.toGlEnum, blend.color.dest.toGlEnum,
                     blend.alpha.src.toGlEnum, blend.alpha.dest.toGlEnum)

    gl.capability(glcColorLogicOp, p.colorLogicOp.isSome)
    gl.logicOp(p.colorLogicOp.get.toGlEnum)

    gl.colorMask(p.colorMask.red, p.colorMask.green, p.colorMask.blue,
                 p.colorMask.alpha)

    gl.depthMask(p.depthMask)

    gl.capability(glcCullFace, p.faceCulling.card > 0)
    if p.faceCulling.card > 0:
      gl.cullFace(
        if p.faceCulling == {facingFront, facingBack}: GL_FRONT_AND_BACK
        elif p.faceCulling == {facingFront}: GL_FRONT
        else: GL_BACK
      )

    for hint, value in p.hints:
      gl.hint(hint, value.toGlEnum)

    gl.lineWidth(p.lineWidth)

    gl.pointSize(p.pointSize)

    for facing, mode in p.polygonMode:
      gl.polygonMode(facing, mode.toGlEnum)

    gl.capability(glcPrimitiveRestart, p.primitiveRestartIndex.isSome)
    if p.primitiveRestartIndex.isSome:
      gl.primitiveRestartIndex(p.primitiveRestartIndex.get.GlUint)

    gl.capability(glcScissorTest, p.scissor.isSome)
    if p.scissor.isSome:
      let rect = p.scissor.get
      gl.scissor(rect.x, rect.y, rect.width, rect.height)

    gl.capability(glcStencilTest, p.stencilMode.isSome)
    if p.stencilMode.isSome:
      let mode = p.stencilMode.get
      for facing, fn in mode.funcs:
        gl.stencilFunc(facing, fn.equation.toGlEnum,
                       fn.reference.GlInt, fn.mask.GlUint)
      for facing, op in mode.ops:
        gl.stencilOp(facing,
                     op.stencilFail.toGlEnum,
                     op.stencilPassDepthFail.toGlEnum,
                     op.stencilPassDepthPass.toGlEnum)
      for facing, mask in mode.masks:
        gl.stencilMask(facing, mask)

    gl.capability(glcDepthTest, p.depthTest)
    gl.capability(glcDither, p.dither)
    gl.capability(glcLineSmooth, p.lineSmooth)
    gl.capability(glcMultisample, p.multisample)
    gl.capability(glcPolygonSmooth, p.polygonSmooth)
    gl.capability(glcTextureCubeMapSeamless, p.seamlessCubeMap)
    gl.capability(glcProgramPointSize, p.programPointSize)
