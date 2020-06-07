## Framebuffers and renderbuffers for rendering to textures.

import gl
import texture

type
  Renderbuffer* = ref object
    ## Renderbuffers are special buffer types similar to textures, but not
    ## suited for sampling. These are commonly used for depth and stencil
    ## buffers as they have lower overhead than using a full texture.
    ## Data cannot be uploaded to renderbuffers, as their only purpose is to
    ## function as depth and stencil attachments.
    gl: OpenGl
    id: GlUint

  ColorSource* = object
    ## Abstract interface for color sources.
    attachToFramebuffer: proc (framebuffer: GlUint)

  DepthStencilSource* = object
    ## Abstract interface for depth or stencil sources.
    attachToFramebuffer: proc (framebuffer: GlUint)

  SimpleFramebuffer* = ref object of Texture
    ## Framebuffer with only one color attachment.
    framebufferId: GlUint

  MultiFramebuffer* = ref object
    ## Framebuffer with one or more color attachments.
    attachments: seq[ColorSource]


# renderbuffer

proc newRenderbuffer*(size: Vec2i, kind: RenderbufferKind)
