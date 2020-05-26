## Draw parameters, used for draw() in the ``rarget`` module.

import std/hashes
import std/macros
import std/options

import glm/vec

import rect

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

  Facing* = enum
    ## Face targeting mode. The facing is determined from the winding order; if
    ## vertices are wound clockwise, the face is interpreted as a facing
    ## backwards. If vertices are wound counterclockwise, the face is
    ## interpreted as a facing to the front. This setting may be overridden
    ## using the ``frontFace`` draw parameter.
    facingFront         ## target front faces
    facingBack          ## target back faces
  Winding* = enum
    ## Winding order.
    windingCounterclockwise
    windingClockwise

  StencilEquation* = enum
    ## Equation for checking if the stencil test passes.
    ## Nim operators are used.
    seNever         ## false
    seLess          ## (reference and mask) <  (stencil and mask)
    seLessEqual     ## (reference and mask) <= (stencil and mask)
    seGreater       ## (reference and mask) >  (stencil and mask)
    seGreaterEqual  ## (reference and mask) >= (stencil and mask)
    seEqual         ## (reference and mask) == (stencil and mask)
    seNotEqual      ## (reference and mask) != (stencil and mask)
    seAlways        ## true
  StencilFunc* = object
    ## Function for stencil testing. Refer to ``StencilEquation`` for details on
    ## how each individual ``equation`` value works.
    equation: StencilEquation  ## the equation to apply
    reference: int32           ## reference value
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

  PolygonMode* = enum
    ## Mode used for polygon rendering.
    pmPoint  ## draw individual vertices
    pmLine   ## draw vertices connected with lines
    pmFill   ## draw filled shape

  ColorMask* = tuple
    ## Mask specifying which color channels are to be written to when rendering.
    red, green, blue, alpha: bool

  Hint* = enum
    hintFragmentShaderDerivative
    hintLineSmooth
    hintPolygonSmooth

  HintValue* = enum
    ## Value for implementation-specific hints.
    hvDontCare  ## don't care, the driver can do what it wants
    hvFastest   ## prefer faster outcome
    hvNicest    ## prefer nicer outcome

  DrawParamsVal = object
    blend: Option[BlendMode]
    colorLogicOp: Option[ColorLogic]
    colorMask: ColorMask
    depthMask: bool
    depthTest: bool
    dither: bool
    faceCulling: Option[set[Facing]]
    frontFace: Winding
    hints: array[Hint, HintValue]
    lineWidth: float32
    multisample: bool
    pointSize: float32
    polygonMode: array[Facing, PolygonMode]
    primitiveRestartIndex: Option[uint32]
    programPointSize: bool
    scissor: Option[Recti]
    stencilMask: uint32
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
                  ops: array[Facing, StencilOp]): StencilMode =
  ## Constructs a stencil mode using the provided stencil functions and
  ## operations.
  StencilMode(
    funcs: funcs,
    ops: ops,
  )

proc stencilMode*(funcBoth: StencilFunc, opBoth: StencilOp): StencilMode =
  ## Constructs a stencil mode. ``funcBoth`` and ``opBoth`` are used both for
  ## front and back faces.
  StencilMode(
    funcs: [funcBoth, funcBoth],
    ops: [opBoth, opBoth],
  )

proc stencilFunc*(equation: StencilEquation,
                  reference: int32, mask = high(uint32)): StencilFunc =
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
  ## Enables face culling.
  ##
  ## **Default:** disabled
  params.val.faceCulling = some(facings)

proc noFaceCulling*(params) =
  ## Disables face culling.
  ##
  ## **Default:** disabled
  params.val.faceCulling = set[Facing].none

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

proc stencilMask*(params; mask: uint32) =
  ## Enables the stencil mask. If enabled, each fragment written to the stencil
  ## buffer will be ANDed with the provided mask.
  ##
  ## **Default:** ``high(uint32)``
  params.val.stencilMask = mask

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

macro derive*(params: DrawParams, body: untyped): untyped =
  ## A macro for making param deriving nice. Creates a block with a temporary
  ## variable ``params``, and prepends it to the arguments of every single call
  ## in the block. Finally, adds a call to ``finish(params)``.
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
  echo result.repr

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
    noFaceCulling
    frontFace windingCounterclockwise
    noPrimitiveRestartIndex
    # fragment tests
    colorMask on, on, on, on
    depthMask on
    stencilMask high(uint32)
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
