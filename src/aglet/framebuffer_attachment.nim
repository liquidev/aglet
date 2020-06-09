## Parent type for all things that can be attached to a framebuffer.

import gl

type
  FramebufferAttachment* = ref object of RootObj
    ## Anything that can be attached to a framebuffer. This does not implement
    ## any procs by default; each valid attachment must implement a converter
    ## to ``ColorSource``, ``DepthSource``, ``StencilSource``, or
    ## ``DepthStencilSource``.

  FramebufferSource* = object
    ## Abstract interface for all the available types of sources.
    attachment*: FramebufferAttachment
    attachToFramebuffer*: proc (framebuffer: GlUint, attachment: GlEnum)
    size*: Vec2i
    samples*: int

  ColorSource* = distinct FramebufferSource
    ## Abstract interface for color sources.
  DepthSource* = distinct FramebufferSource
    ## Abstract interface for depth sources.
  StencilSource* = distinct FramebufferSource
    ## Abstract interface for stencil sources.
  DepthStencilSource* = distinct FramebufferSource
    ## Abstract interface for combined depth/stencil sources.
