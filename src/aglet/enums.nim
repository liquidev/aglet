## Enums shared between gl and drawparams.
## This module is here to overcome the limitations of Nim imports, which cannot
## be cyclic.

type
  Facing* = enum
    ## Face targeting mode. The facing is determined from the winding order; if
    ## vertices are wound clockwise, the face is interpreted as a facing
    ## backwards. If vertices are wound counterclockwise, the face is
    ## interpreted as a facing to the front. This setting may be overridden
    ## using the ``frontFace`` draw parameter.
    facingFront  ## target front faces
    facingBack   ## target back faces

  Winding* = enum
    ## Winding order.
    windingCounterclockwise
    windingClockwise

  Hint* = enum
    ## Implementation-specific hints.
    hintFragmentShaderDerivative  ## mode for derivative functions in shaders
    hintLineSmooth                ## line smoothing mode
    hintPolygonSmooth             ## polygon smoothing mode

  HintValue* = enum
    ## Value for implementation-specific hints.
    hvDontCare  ## don't care, the driver can do what it wants
    hvFastest   ## prefer faster outcome
    hvNicest    ## prefer nicer outcome

  FilteringMode* = enum
    ## Pixel filtering (interpolation) mode.
    fmNearest
    fmLinear
    fmNearestMipmapNearest
    fmNearestMipmapLinear
    fmLinearMipmapNearest
    fmLinearMipmapLinear

  AccessModeBit* = enum
    ## Memory access modes.
    amRead
    amWrite

  AccessMode* = set[AccessModeBit]
