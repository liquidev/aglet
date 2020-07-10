## Framebuffers and renderbuffers for rendering to textures.

import enums
import framebuffer_attachment
import gl
import pixelbuffer
import pixeltypes
import rect
import target
import window

export framebuffer_attachment

# methods produce this annoying warning, so we turn it off
{.push warning[LockLevel]: off.}

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
    pixelBuffer: PixelBuffer

  DefaultFramebuffer* {.final.} = ref object of BaseFramebuffer
    ## Object representation of the default framebuffer.

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

proc size*(renderbuffer: Renderbuffer): Vec2i {.inline.} =
  ## Returns the size of the renderbuffer as a vector.
  renderbuffer.fSize

proc width*(renderbuffer: Renderbuffer): int {.inline.} =
  ## Returns the width of the renderbuffer.
  renderbuffer.size.x

proc height*(renderbuffer: Renderbuffer): int {.inline.} =
  ## Returns the height of the renderbuffer.
  renderbuffer.size.y

proc multisampled*(renderbuffer: Renderbuffer): bool {.inline.} =
  ## Returns whether the renderbuffer is multisampled.
  renderbuffer.fSamples > 0

proc samples*(renderbuffer: Renderbuffer): int {.inline.} =
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
  result.window = window
  result.id = gl.createRenderbuffer()
  result.gl = gl

  result.use()
  result.gl.renderbufferStorage(GlSizei(size.x), GlSizei(size.y),
                                GlSizei(samples), T.internalFormat)
  result.fSize = size
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

converter source*(rb: Renderbuffer[ColorPixelType]): ColorSource {.inline.} =
  ## ``ColorSource`` implementation for color renderbuffers.
  result = rb.implSource().ColorSource

converter source*(rb: Renderbuffer[DepthPixelType]): DepthSource {.inline.} =
  ## ``DepthSource`` implementation for depth renderbuffers.
  result = rb.implSource().DepthSource

converter source*(rb: Renderbuffer[StencilPixelType]): StencilSource
                 {.inline.} =
  ## ``StencilSource`` implementation for stencil renderbuffers.
  result = rb.implSource().StencilSource

converter source*(rb: Renderbuffer[DepthStencilPixelType]): DepthStencilSource
                 {.inline.} =
  ## ``DepthStencilSource`` implementation for combined depth/stencil
  ## renderbuffers.
  result = rb.implSource().DepthStencilSource


# base framebuffer

method size*(framebuffer: BaseFramebuffer): Vec2i {.base.} =
  ## Returns the size of the framebuffer as a vector.
  framebuffer.fSize

proc width*(framebuffer: BaseFramebuffer): int {.inline.} =
  ## Returns the width of the framebuffer.
  framebuffer.size.x

proc height*(framebuffer: BaseFramebuffer): int {.inline.} =
  ## Returns the height of the framebuffer.
  framebuffer.size.y

proc multisampled*(framebuffer: BaseFramebuffer): bool {.inline.} =
  ## Returns whether the framebuffer is multisampled.
  framebuffer.fSamples > 0

proc samples*(framebuffer: BaseFramebuffer): int {.inline.} =
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

proc sizeInBytes[T: ClientPixelType](framebuffer: BaseFramebuffer): int =
  result = framebuffer.width * framebuffer.height * sizeof(T)

proc ensurePixelBuffer[T: ClientPixelType](framebuffer: BaseFramebuffer): int =
  assert framebuffer.width > 0 and framebuffer.height > 0,
    "framebuffer must have a valid attachment for pixel downloading"
  if framebuffer.pixelBuffer == nil:
    framebuffer.pixelBuffer = framebuffer.window.newPixelBuffer()
  result = framebuffer.sizeInBytes[:T]()
  framebuffer.pixelBuffer.ensureSize(result)

proc download*[T: ClientPixelType](framebuffer: BaseFramebuffer, area: Recti,
                                   callback: proc (data: ptr UncheckedArray[T],
                                                   len: Natural)) =
  ## Asynchronously download pixels off the graphics card from the given ara,
  ## in the given format.
  ## This calls the callback procedure after the pixels are downloaded, which
  ## may take some amount of time to accomplish. This callback retrieves a
  ## pointer to the downloaded array of pixels with **read-only access**,
  ## along with the amount of pixels (not bytes!) stored in that array.
  ##
  ## If you wish to preserve this data in a ``seq`` or some other container, use
  ## ``copyMem(data[0].addr, theSeq[0].addr, len * sizeof(T))``. Passing the
  ## ``data`` array anywhere outside of this callback is undefined behavior
  ## (most likely resulting in a crash).
  ##
  ## This procedure is asynchronous. Don't forget to update the window's async
  ## event loop using ``pollAsyncCallbacks``, ``pollEvents``, or ``waitEvents``.
  ## Otherwise the results will never arrive.

  framebuffer.use()
  let dataSize = framebuffer.ensurePixelBuffer[:T]()
  framebuffer.pixelBuffer.packUse:
    framebuffer.gl.readPixels(area.x, area.y,
                              GlSizei(area.width), GlSizei(area.height),
                              T.format, T.dataType, nil)
  let fence = framebuffer.gl.createFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE)
  framebuffer.window.startAsync do -> bool:
    let status = framebuffer.gl.pollSyncStatus(fence, timeout = 0)
    # have to convert to int here because of generic quirks
    result = status.int notin
             [GL_ALREADY_SIGNALED.int, GL_CONDITION_SATISFIED.int]
    if not result:
      # XXX: is mapping and unmapping the buffer fast? probably not.
      # there's definitely some room for optimization here
      framebuffer.pixelBuffer.map({amRead})
      callback(cast[ptr UncheckedArray[T]](framebuffer.pixelBuffer.data),
               dataSize div sizeof(T))
      framebuffer.pixelBuffer.unmap()
      framebuffer.gl.deleteSync(fence)

proc download*[T: ClientPixelType](framebuffer: BaseFramebuffer, area: Recti,
                                   callback: proc (data: seq[T])) =
  ## Version of ``download`` that yields a seq. This seq contains an
  ## *owned* copy of the data stored in the framebuffer, so it's safe to assign
  ## it to somewhere else outside of the callback.

  framebuffer.download(area) do (data: ptr UncheckedArray[T], len: Natural):
    var dataSeq: seq[T]
    dataSeq.setLen(len)
    copyMem(dataSeq[0].addr, data[0].addr, len * sizeof(T))
    callback(dataSeq)

proc downloadSync*[T: ClientPixelType](framebuffer: BaseFramebuffer,
                                       area: Recti): seq[T] =
  ## *Synchronously* download pixels off the graphics card from the given area,
  ## in the given format.
  ##
  ## This procedure is **synchronous**, so the results are available
  ## immediately. However, it forces a synchronization between the CPU and
  ## the GPU. This can negatively impact performance if it is called frequently.
  ## Prefer the asynchronous versions whenever possible.

  framebuffer.use()
  let dataSize = framebuffer.sizeInBytes[:T]()
  result.setLen(dataSize div sizeof(T))
  framebuffer.gl.readPixels(area.x, area.y,
                            GlSizei(area.width), GlSizei(area.height),
                            T.format, T.dataType, addr result[0])

template framebufferInit(T) =
  new(result) do (fb: T):
    fb.window.IMPL_makeCurrent()
    fb.gl.deleteFramebuffer(fb.id)
  result.window = window
  IMPL_makeCurrent(window)
  result.id = createFramebuffer(gl)
  result.gl = gl
  result.fSamples = -1


# default framebuffer

method size*(defaultfb: DefaultFramebuffer): Vec2i =
  ## Returns the size of the framebuffer as a vector.
  defaultfb.window.size

proc defaultFramebuffer*(window: Window): DefaultFramebuffer =
  ## Returns a handle to the window's default framebuffer.
  new(result)
  result.window = window
  result.id = 0
  result.gl = window.IMPL_getGlContext()
  result.fSamples = result.gl.defaultFramebufferSamples


# simple framebuffer

proc color*(simplefb: SimpleFramebuffer): FramebufferAttachment {.inline.} =
  ## Returns the color attachment of this framebuffer.
  simplefb.fColor

proc depth*(simplefb: SimpleFramebuffer): FramebufferAttachment {.inline.} =
  ## Returns the depth attachment of this framebuffer, or ``nil`` if no depth
  ## target was attached.
  simplefb.fDepth

proc stencil*(simplefb: SimpleFramebuffer): FramebufferAttachment {.inline.} =
  ## Returns the stencil attachment of this framebuffer, or ``nil`` if no
  ## stencil target was attached.
  simplefb.fStencil

proc depthStencil*(simplefb: SimpleFramebuffer): FramebufferAttachment
                  {.inline.} =
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

proc colorCount*(multifb: MultiFramebuffer): int {.inline.} =
  ## Returns the number of color attachments.
  multifb.fColor.len

proc color*(multifb: MultiFramebuffer, index: Natural): FramebufferAttachment
           {.inline.} =
  ## Returns the color attachment ``index`` of the framebuffer.
  multifb.fColor[index]

proc depth*(multifb: MultiFramebuffer): FramebufferAttachment {.inline.} =
  ## Returns the depth attachment of this framebuffer, or ``nil`` if no depth
  ## target was attached.
  multifb.fDepth

proc stencil*(multifb: MultiFramebuffer): FramebufferAttachment {.inline.} =
  ## Returns the stencil attachment of this framebuffer, or ``nil`` if no
  ## stencil  target was attached.
  multifb.fStencil

proc depthStencil*(multifb: MultiFramebuffer): FramebufferAttachment
                  {.inline.} =
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
  result.size = framebuffer.size
  result.useImpl = proc (target: Target, gl: OpenGl) {.nimcall.} =
    let framebuffer = target.FramebufferTarget.framebuffer
    framebuffer.window.IMPL_makeCurrent()
    gl.bindFramebuffer({ftRead, ftDraw}, framebuffer.id)
    gl.viewport(0, 0, framebuffer.width.GlSizei, framebuffer.height.GlSizei)

{.pop.}
