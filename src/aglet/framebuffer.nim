## Framebuffers and renderbuffers for rendering to textures.

import enums
import framebuffer_attachment
import gl
import pixeltypes
import rect
import target
import window

export framebuffer_attachment

type
  Renderbuffer*[T] = ref object of FramebufferAttachment
    ## Renderbuffers are special buffer types similar to textures, but not
    ## suited for sampling. These are commonly used for depth and stencil
    ## buffers as they have lower overhead than using a full texture.
    ## Data cannot be uploaded to renderbuffers, as their only purpose is to
    ## function as depth and stencil attachments.
    window: Window
    gl: OpenGl
    id: GlUint
    fSize: Vec2i
    fSamples: int

  RenderbufferPixelType* = AnyPixelType

  BaseFramebuffer* = ref object of RootObj
    ## Base type for framebuffers.
    window: Window
    gl: OpenGl
    id: GlUint
    fSize: Vec2i
    fSamples: int

  SimpleFramebuffer* {.final.} = ref object of BaseFramebuffer
    ## Framebuffer with only one color attachment.
    fColor, fDepth, fStencil, fDepthStencil: FramebufferAttachment

  MultiFramebuffer* {.final.} = ref object of BaseFramebuffer
    ## Framebuffer with one or more color attachments.
    fColor: seq[FramebufferAttachment]
    fDepth, fStencil, fDepthStencil: FramebufferAttachment

  FramebufferTarget* = object of Target
    framebuffer: BaseFramebuffer

  BufferBit* = enum
    bbColor
    bbDepth
    bbStencil

  BlitFilter* = range[fmNearest..fmLinear]

# renderbuffer

proc size*(renderbuffer: Renderbuffer): Vec2i =
  ## Returns the size of the renderbuffer as a vector.
  renderbuffer.fSize

proc width*(renderbuffer: Renderbuffer): int =
  ## Returns the width of the renderbuffer.
  renderbuffer.size.x

proc height*(renderbuffer: Renderbuffer): int =
  ## Returns the height of the renderbuffer.
  renderbuffer.size.y

proc multisampled*(renderbuffer: Renderbuffer): bool =
  ## Returns whether the renderbuffer is multisampled.
  renderbuffer.fSamples > 0

proc samples*(renderbuffer: Renderbuffer): bool =
  ## Returns the number of MSAA samples for the renderbuffer, or 0 if the
  ## renderbuffer does not have MSAA enabled.
  renderbuffer.fSamples

proc use(renderbuffer: Renderbuffer) =
  renderbuffer.window.IMPL_makeCurrent()
  renderbuffer.gl.bindRenderbuffer(renderbuffer.id)

proc newRenderbuffer*[T: RenderbufferPixelType](window: Window,
                                                size: Vec2i,
                                                samples = 0): Renderbuffer[T] =
  ## Creates a new renderbuffer.
  new(result) do (renderbuffer: Renderbuffer[T]):
    renderbuffer.window.IMPL_makeCurrent()
    renderbuffer.gl.deleteRenderbuffer(renderbuffer.id)

  window.IMPL_makeCurrent()
  var gl = window.IMPL_getGlContext()
  result.id = gl.createRenderbuffer()
  result.gl = gl

  result.use()
  result.gl.renderbufferStorage(size.x.GlSizei, size.y.GlSizei,
                                samples.GlSizei, T.internalFormat)
  result.fSamples = samples

proc implSource(renderbuffer: Renderbuffer): FramebufferSource =
  # since all renderbuffers share the same procedure for attachment to
  # framebuffers, we may as well do this

  result.attachment = renderbuffer.FramebufferAttachment
  result.size = renderbuffer.size
  result.samples = renderbuffer.samples

  result.attachToFramebuffer = proc (framebuffer: GlUint, attachment: GlEnum) =
    renderbuffer.use()
    renderbuffer.gl.attachRenderbuffer(attachment, renderbuffer.id)

converter source*(rb: Renderbuffer[ColorPixelType]): ColorSource =
  ## ``ColorSource`` implementation for color renderbuffers.
  result = rb.implSource().ColorSource

converter source*(rb: Renderbuffer[DepthPixelType]): DepthSource =
  ## ``DepthSource`` implementation for depth renderbuffers.
  result = rb.implSource().DepthSource

converter source*(rb: Renderbuffer[StencilPixelType]): StencilSource =
  ## ``StencilSource`` implementation for stencil renderbuffers.
  result = rb.implSource().StencilSource

converter source*(rb: Renderbuffer[DepthStencilPixelType]): DepthStencilSource =
  ## ``DepthStencilSource`` implementation for combined depth/stencil
  ## renderbuffers.
  result = rb.implSource().DepthStencilSource


# base framebuffer

proc size*(framebuffer: BaseFramebuffer): Vec2i =
  ## Returns the size of the framebuffer as a vector.
  framebuffer.fSize

proc width*(framebuffer: BaseFramebuffer): int =
  ## Returns the width of the framebuffer.
  framebuffer.size.x

proc height*(framebuffer: BaseFramebuffer): int =
  ## Returns the height of the framebuffer.
  framebuffer.size.y

proc multisampled*(framebuffer: BaseFramebuffer): bool =
  ## Returns whether the framebuffer is multisampled.
  framebuffer.fSamples > 0

proc samples*(framebuffer: BaseFramebuffer): int =
  ## Returns the MSAA sample count of the framebuffer.
  framebuffer.fSamples

proc blit*(source, dest: BaseFramebuffer, sourceArea, destArea: Recti,
           buffers: set[BufferBit], filter: BlitFilter) =
  ## Blits an area from one framebuffer to another.
  ## ``sourceArea`` and ``destArea`` specify the area from which to copy, and
  ## the area to copy the pixels to. ## ``buffers`` specifies which buffers to
  ## copy, and ``filter`` specifies the filtering mode.
  ## Both framebuffers must have the same parent window, attempting to use
  ## framebuffers created with different windows is an error.
  assert source.window == dest.window,
    "both framebuffers must be owned by the same window"
  source.window.IMPL_makeCurrent()
  source.gl.bindFramebuffer({ftRead}, source.id)
  source.gl.bindFramebuffer({ftDraw}, dest.id)

  var bitmask = 0
  if bbColor in buffers: bitmask = bitmask or GL_COLOR_BUFFER_BIT.int
  if bbDepth in buffers: bitmask = bitmask or GL_DEPTH_BUFFER_BIT.int
  if bbStencil in buffers: bitmask = bitmask or GL_STENCIL_BUFFER_BIT.int

  assert not (card(buffers * {bbDepth, bbStencil}) > 0 and filter != fmNearest),
    "filter must be fmNearest if blitting depth and/or stencil buffers"

  let filter =
    case filter
    of fmLinear: GL_LINEAR
    of fmNearest: GL_NEAREST

  source.gl.blitFramebuffer(sourceArea.left, sourceArea.top,
                            sourceArea.right, sourceArea.bottom,
                            destArea.left, destArea.top,
                            destArea.right, destArea.bottom,
                            bitmask.GlBitfield, filter)

proc use(framebuffer: BaseFramebuffer) =
  framebuffer.window.IMPL_makeCurrent()
  framebuffer.gl.bindFramebuffer({ftRead, ftDraw}, framebuffer.id)


# simple framebuffer

proc color*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the color attachment of this framebuffer.
  simplefb.fColor

proc depth*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the depth attachment of this framebuffer, or ``nil`` if no depth
  ## target was attached.
  simplefb.fDepth

proc stencil*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the stencil attachment of this framebuffer, or ``nil`` if no
  ## stencil target was attached.
  simplefb.fStencil

proc depthStencil*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the combined depth/stencil attachment of this framebuffer, or
  ## ``nil`` if no combined depth/stencil target was attached.
  simplefb.fStencil

template singleSource(F, T, field, attachmentEnum) =
  proc attach(fb: F, source: T) =
    let source = source.FramebufferSource
    fb.use()
    source.attachToFramebuffer(fb.id, attachmentEnum)
    fb.field = source.attachment
    if fb.fSize == vec2i(0):
      fb.fSize = source.size
    else:
      assert source.size == fb.size, "all attachments must have the same size"
    if fb.fSamples == -1:
      fb.fSamples = source.samples
    else:
      assert source.samples == fb.fSamples,
        "all attachments must have the same number of MSAA samples"

singleSource SimpleFramebuffer, ColorSource, fColor, GL_COLOR_ATTACHMENT0
singleSource SimpleFramebuffer, DepthSource, fDepth, GL_DEPTH_ATTACHMENT
singleSource SimpleFramebuffer, StencilSource, fStencil, GL_STENCIL_ATTACHMENT
singleSource SimpleFramebuffer, DepthStencilSource, fDepthStencil,
             GL_DEPTH_STENCIL_ATTACHMENT

template framebufferInit(T) =
  new(result) do (fb: T):
    fb.window.IMPL_makeCurrent()
    fb.gl.deleteFramebuffer(fb.id)
  result.window = window
  IMPL_makeCurrent(window)
  result.id = createFramebuffer(gl)
  result.gl = gl
  result.fSamples = -1

template framebufferCheck =
  result.use()
  let status = framebufferStatus(gl)
  if status != GL_FRAMEBUFFER_COMPLETE:
    let statusCode =
      case status
      of GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: "incomplete attachment"
      of GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: "missing attachment"
      of GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER: "incomplete draw buffer"
      of GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS: "incomplete layer targets"
      of GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE: "incomplete multisample"
      of GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER: "incomplete read buffer"
      else: "error code: " & $status.int
    raise newException(IOError, "aglet internal error: incomplete framebuffer" &
                       " (" & statusCode & "). please report this")

proc newFramebuffer*(window: Window,
                     color: ColorSource,
                     depth: DepthSource,
                     stencil: StencilSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with color, depth, and stencil
  ## attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(SimpleFramebuffer)

  result.attach(color)
  result.attach(depth)
  result.attach(stencil)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: ColorSource,
                     depth: DepthSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with color and depth attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(SimpleFramebuffer)

  result.attach(color)
  result.attach(depth)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: ColorSource,
                     stencil: StencilSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with color and stencil attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(SimpleFramebuffer)

  result.attach(color)
  result.attach(stencil)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: ColorSource,
                     depthStencil: DepthStencilSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with a color attachment and combined
  ## depth/stencil attachment.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(SimpleFramebuffer)

  result.attach(color)
  result.attach(depthStencil)

  framebufferCheck()

proc newFramebuffer*(window: Window, color: ColorSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with a color attachment only.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(SimpleFramebuffer)

  result.attach(color)

  framebufferCheck()


# multi framebuffer

proc colorCount*(multifb: MultiFramebuffer): int =
  ## Returns the number of color attachments.
  multifb.fColor.len

proc color*(multifb: MultiFramebuffer, index: Natural): FramebufferAttachment =
  ## Returns the color attachment ``index`` of the framebuffer.
  multifb.fColor[index]

proc depth*(multifb: MultiFramebuffer): FramebufferAttachment =
  ## Returns the depth attachment of this framebuffer, or ``nil`` if no depth
  ## target was attached.
  multifb.fDepth

proc stencil*(multifb: MultiFramebuffer): FramebufferAttachment =
  ## Returns the stencil attachment of this framebuffer, or ``nil`` if no
  ## stencil  target was attached.
  multifb.fStencil

proc depthStencil*(multifb: MultiFramebuffer): FramebufferAttachment =
  ## Returns the combined depth/stencil attachment of this framebuffer, or
  ## ``nil`` if no combined depth/stencil target was attached.
  multifb.fDepthStencil

singleSource MultiFramebuffer, DepthSource, fDepth, GL_DEPTH_ATTACHMENT
singleSource MultiFramebuffer, StencilSource, fStencil, GL_STENCIL_ATTACHMENT
singleSource MultiFramebuffer, DepthStencilSource, fDepthStencil,
             GL_DEPTH_STENCIL_ATTACHMENT

proc attach(multifb: MultiFramebuffer, sources: openArray[ColorSource]) =
  multifb.fColor.setLen(0)  # failsafe
  multifb.use()
  for index, color in sources:
    let
      source = color.FramebufferSource
      attachmentPoint = GlEnum(int(GL_COLOR_ATTACHMENT0) + index)
    source.attachToFramebuffer(multifb.id, attachmentPoint)
    multifb.fColor.add(source.attachment)
    if multifb.size == vec2i(0):
      multifb.fSize = source.size
    else:
      assert source.size == multifb.size,
        "all attachments must have the same size"
    if multifb.samples == -1:
      multifb.fSamples = source.samples
    else:
      assert source.samples == multifb.samples,
        "all attachments must have the same number of MSAA samples"

proc newFramebuffer*(window: Window,
                     color: openArray[ColorSource],
                     depth: DepthSource,
                     stencil: StencilSource): MultiFramebuffer =
  ## Creates a new multi framebuffer with color, depth, and stencil attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.
  ##
  ## **Caution:** When using multi framebuffers, you may find that ``source``
  ## converters defined by Textures and Renderbuffers don't really work with the
  ## ``color`` openArray. In this case, you need to call these converters
  ## explicitly.

  var gl = window.IMPL_getGlContext()
  framebufferInit(MultiFramebuffer)

  result.attach(color)
  result.attach(depth)
  result.attach(stencil)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: openArray[ColorSource],
                     depth: DepthSource): MultiFramebuffer =
  ## Creates a new multi framebuffer with color and depth attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(MultiFramebuffer)

  result.attach(color)
  result.attach(depth)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: openArray[ColorSource],
                     stencil: StencilSource): MultiFramebuffer =
  ## Creates a new multi framebuffer with color and stencil attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(MultiFramebuffer)

  result.attach(color)
  result.attach(stencil)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: openArray[ColorSource],
                     depthStencil: DepthStencilSource): MultiFramebuffer =
  ## Creates a new multi framebuffer with color and combined depth/stencil
  ## attachments.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(MultiFramebuffer)

  result.attach(color)
  result.attach(depthStencil)

  framebufferCheck()

proc newFramebuffer*(window: Window,
                     color: openArray[ColorSource]): MultiFramebuffer =
  ## Creates a new multi framebuffer with color attachments only.
  ## All attachments must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(MultiFramebuffer)

  result.attach(color)

  framebufferCheck()


# rendering

proc render*(framebuffer: BaseFramebuffer): FramebufferTarget =
  ## Creates and returns a target for rendering onto the framebuffer.
  ## This proc is safe to use this in your render loop, as it does not have
  ## heavy performance implications.
  ## Also, the target returned from this proc does not have to be
  ## ``finish()``ed, unlike a window ``Frame``.

  result.framebuffer = framebuffer
  result.gl = framebuffer.gl
  result.useImpl = proc (target: Target, gl: OpenGl) {.nimcall.} =
    let framebuffer = target.FramebufferTarget.framebuffer
    framebuffer.window.IMPL_makeCurrent()
    gl.bindFramebuffer({ftRead, ftDraw}, framebuffer.id)
    gl.viewport(0, 0, framebuffer.width.GlSizei, framebuffer.height.GlSizei)
