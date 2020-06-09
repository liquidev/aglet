## Framebuffers and renderbuffers for rendering to textures.

import framebuffer_attachment
import gl
import pixeltypes
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

  SimpleFramebuffer* = ref object
    ## Framebuffer with only one color attachment.
    window: Window
    gl: OpenGl
    id: GlUint
    fSize: Vec2i
    fSamples: int
    fColor, fDepth, fStencil, fDepthStencil: FramebufferAttachment

  MultiFramebuffer* = ref object
    ## Framebuffer with one or more color attachments.
    attachments: seq[ColorSource]

  SimpleFramebufferTarget* = object of Target
    framebuffer: SimpleFramebuffer

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


# simple framebuffer

proc size*(simplefb: SimpleFramebuffer): Vec2i =
  ## Returns the size of the framebuffer as a vector.
  simplefb.fSize

proc width*(simplefb: SimpleFramebuffer): int =
  ## Returns the width of the framebuffer.
  simplefb.size.x

proc height*(simplefb: SimpleFramebuffer): int =
  ## Returns the height of the framebuffer.
  simplefb.size.y

proc multisampled*(simplefb: SimpleFramebuffer): bool =
  ## Returns whether the framebuffer is multisampled.
  simplefb.fSamples > 0

proc samples*(simplefb: SimpleFramebuffer): int =
  ## Returns the MSAA sample count of the framebuffer.
  simplefb.fSamples

proc color*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the color attachment of this framebuffer.
  simplefb.fColor

proc depth*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the depth attachment of this framebuffer, or ``nil`` if no depth
  ## target was attached..
  simplefb.fDepth

proc stencil*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the stencil attachment of this framebuffer, or ``nil`` if no
  ## stencil target was attached.
  simplefb.fStencil

proc depthStencil*(simplefb: SimpleFramebuffer): FramebufferAttachment =
  ## Returns the combined depth/stencil attachment of this framebuffer, or
  ## ``nil`` if no combined depth/stencil target was attached.
  simplefb.fStencil

proc use(simplefb: SimpleFramebuffer) =
  simplefb.window.IMPL_makeCurrent()
  simplefb.gl.bindFramebuffer({ftRead, ftDraw}, simplefb.id)

template framebufferSource(T, field, attachmentEnum) =
  proc attach(simplefb: SimpleFramebuffer, source: T) =
    let source = source.FramebufferSource
    simplefb.use()
    source.attachToFramebuffer(simplefb.id, attachmentEnum)
    simplefb.field = source.attachment
    if simplefb.fSize == vec2i(0):
      simplefb.fSize = source.size
    else:
      assert source.size == simplefb.size, "all targets must have the same size"
    if simplefb.fSamples == -1:
      simplefb.fSamples = source.samples
    else:
      assert source.samples == simplefb.fSamples,
        "all targets must have the same count of MSAA samples"

framebufferSource ColorSource, fColor, GL_COLOR_ATTACHMENT0
framebufferSource DepthSource, fDepth, GL_DEPTH_ATTACHMENT
framebufferSource StencilSource, fStencil, GL_STENCIL_ATTACHMENT
framebufferSource DepthStencilSource, fDepthStencil, GL_DEPTH_STENCIL_ATTACHMENT

template framebufferInit(gl) =
  new(result) do (simplefb: SimpleFramebuffer):
    result.window.IMPL_makeCurrent()
    result.gl.deleteFramebuffer(simplefb.id)
  result.window = window
  IMPL_makeCurrent(window)
  result.id = gl.createFramebuffer()
  result.gl = gl
  result.fSamples = -1

proc newFramebuffer*(window: Window,
                     color: ColorSource,
                     depth: DepthSource,
                     stencil: StencilSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with color, depth, and stencil
  ## attachments.
  ## All targets must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(gl)

  result.attach(color)
  result.attach(depth)
  result.attach(stencil)

proc newFramebuffer*(window: Window,
                     color: ColorSource,
                     depthStencil: DepthStencilSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with a color attachment and combined
  ## depth/stencil attachment.
  ## All targets must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(gl)

  result.attach(color)
  result.attach(depthStencil)

proc newFramebuffer*(window: Window, color: ColorSource): SimpleFramebuffer =
  ## Creates a new simple framebuffer with a color attachment only.
  ## All targets must have the same size and sample count, otherwise an
  ## assertion is triggered.

  var gl = window.IMPL_getGlContext()
  framebufferInit(gl)

  result.attach(color)

proc render*(simplefb: SimpleFramebuffer): SimpleFramebufferTarget =
  ## Creates and returns a target for rendering onto the framebuffer.
  ## This proc is safe to use this in your render loop, as it does not have
  ## heavy performance implications.
  ## Also, the target returned from this proc does not have to be
  ## ``finish()``ed, unlike a window ``Frame``.

  result.framebuffer = simplefb
  result.gl = simplefb.gl
  result.useImpl = proc (target: Target, gl: OpenGl) {.nimcall.} =
    let simplefb = target.SimpleFramebufferTarget.framebuffer
    simplefb.window.IMPL_makeCurrent()
    gl.bindFramebuffer({ftRead, ftDraw}, simplefb.id)
    gl.viewport(0, 0, simplefb.width.GlSizei, simplefb.height.GlSizei)
