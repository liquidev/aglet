## Supported pixel types usable by textures and renderbuffers.

import glm/vec

import gl

when sizeof(Vec3f) != sizeof(float32) * 3:
  {.error: "[aglet] sizeof(Vec3f) must equal sizeof(float32). please report " &
           "this along with your platform, C compiler, and architecture.".}

type
  Red8* = distinct uint8
    ## 8-bit red color values.
  Red16* = distinct uint16
    ## 16-bit red color values.
  Red32* = distinct uint32
    ## 32-bit red color values.
  Red32f* = distinct float32
    ## 32-bit float red color values.

  Rg8* = distinct Vec2[uint8]
    ## 8-bit red/green color values.
  Rg16* = distinct Vec2[uint16]
    ## 16-bit red/green color values.
  Rg32* = distinct Vec2[uint32]
    ## 32-bit red/green color values.
  Rg32f* = distinct Vec2[float32]
    ## 32-bit float red/green color values.

  Rgb8* = distinct Vec3[uint8]
    ## 8-bit red/green/blue color values.
  Rgb16* = distinct Vec3[uint16]
    ## 16-bit red/green/blue color values.
  Rgb32* = distinct Vec3[uint32]
    ## 32-bit red/green/blue color values.
  Rgb32f* = distinct Vec3[float32]
    ## 32-bit float red/green/blue color values.

  Rgba8* = distinct Vec4[uint8]
    ## 8-bit red/green/blue/alpha color values.
  Rgba16* = distinct Vec4[uint16]
    ## 16-bit red/green/blue/alpha color values.
  Rgba32* = distinct Vec4[uint32]
    ## 32-bit red/green/blue/alpha color values.
  Rgba32f* = distinct Vec4[float32]
    ## 32-bit float red/green/blue/alpha color values.

  Depth16* = uint16
    ## 16-bit depth values.
  Depth24* = object
    ## 24-bit depth values.
  Depth32* = uint32
    ## 32-bit depth values.
  Depth32f* = float32
    ## 32-bit float depth values.
  Stencil1* = object
    ## 1-bit stencil values.
  Stencil4* = object
    ## 4-bit stencil values.
  Stencil8* = uint8
    ## 8-bit stencil values.
  Stencil16* = uint16
    ## 16-bit stencil values.
  Depth24Stencil8* = object
    ## Combined 24-bit depth value with 8-bit stencil value.
  Depth32fStencil8* = object
    ## Combined 32-bit float depth value with 8-bit stencil value.

  ColorPixelType* =
    Red8 | Rg8 | Rgb8 | Rgba8 |
    Red16 | Rg16 | Rgb16 | Rgba16 |
    Red32 | Rg32 | Rgb32 | Rgba32 |
    Red32f | Rg32f | Rgb32f | Rgba32f
    ## Pixel formats for storing color values.

  DepthPixelType* = Depth16 | Depth24 | Depth32 | Depth32f
    ## Pixel formats for storing depth values.

  StencilPixelType* = Stencil1 | Stencil4 | Stencil8 | Stencil16
    ## Pixel formats for storing stencil values.

  DepthStencilPixelType* = Depth24Stencil8 | Depth32fStencil8
    ## Pixel formats for storing combined depth and stencil values.

  AnyPixelType* =
    ColorPixelType | DepthPixelType | StencilPixelType | DepthStencilPixelType
    ## Any valid pixel format.

  ClientPixelType* = concept type T
    ## Concept that denotes any type that can be represented on the client side.
    T is AnyPixelType and T isnot object


# color constructors
# I hate repetitive code like this but afaik there's no better way to do this
# while preserving the doc comments.

proc red8*(red: uint8): Red8 =
  ## Construct a Red8 value.
  result = Red8(red)

proc red16*(red: uint16): Red16 =
  ## Construct a Red16 value.
  result = Red16(red)

proc red32*(red: uint32): Red32 =
  ## Construct a Red32 value.
  result = Red32(red)

proc red32f*(red: float32): Red32f =
  ## Construct a Red32f value.
  result = Red32f(red)

proc rg8*(red, green: uint8): Rg8 =
  ## Construct a Rg8 value.
  result = Rg8(vec2(red, green))

proc rg16*(red, green: uint16): Rg16 =
  ## Construct a Rg16 value.
  result = Rg16(vec2(red, green))

proc rg32*(red, green: uint32): Rg32 =
  ## Construct a Rg32 value.
  result = Rg32(vec2(red, green))

proc rg32f*(red, green: float32): Rg32f =
  ## Construct a Rg32f value.
  result = Rg32f(vec2(red, green))

proc rgb8*(red, green, blue: uint8): Rgb8 =
  ## Construct a Rgb8 value.
  result = Rgb8(vec3(red, green, blue))

proc rgb16*(red, green, blue: uint16): Rgb16 =
  ## Construct a Rgb16 value.
  result = Rgb16(vec3(red, green, blue))

proc rgb32*(red, green, blue: uint32): Rgb32 =
  ## Construct a Rgb32 value.
  result = Rgb32(vec3(red, green, blue))

proc rgb32f*(red, green, blue: float32): Rgb32f =
  ## Construct a Rgb32f value.
  result = Rgb32f(vec3(red, green, blue))

proc rgba8*(red, green, blue, alpha: uint8): Rgba8 =
  ## Construct a Rgba8 value.
  result = Rgba8(vec4(red, green, blue, alpha))

proc rgba16*(red, green, blue, alpha: uint16): Rgba16 =
  ## Construct a Rgba16 value.
  result = Rgba16(vec4(red, green, blue, alpha))

proc rgba32*(red, green, blue, alpha: uint32): Rgba32 =
  ## Construct a Rgba32 value.
  result = Rgba32(vec4(red, green, blue, alpha))

proc rgba32f*(red, green, blue, alpha: float32): Rgba32f =
  ## Construct a Rgba32f value.
  result = Rgba32f(vec4(red, green, blue, alpha))

# we also define some nice aliases for color types used commonly across the lib

proc rg*(red, green: float32): Rg32f =
  ## Alias for ``rgba32f``.
  rg32f(red, green)

proc rgb*(red, green, blue: float32): Rgb32f =
  ## Alias for ``rgba32f``.
  rgb32f(red, green, blue)

proc rgba*(red, green, blue, alpha: float32): Rgba32f =
  ## Alias for ``rgba32f``.
  rgba32f(red, green, blue, alpha)


# color getters

proc r*(color: Red8): uint8 = uint8(color)
proc r*(color: Red16): uint16 = uint16(color)
proc r*(color: Red32): uint32 = uint32(color)
proc r*(color: Red32f): float32 = float32(color)

template colorFieldsRg(T, R: type): untyped =
  proc r*(color: T): R {.borrow.}
  proc g*(color: T): R {.borrow.}

colorFieldsRg Rg8, uint8
colorFieldsRg Rg16, uint16
colorFieldsRg Rg32, uint32
colorFieldsRg Rg32f, float32

template colorFieldsRgb(T, R: type): untyped =
  proc r*(color: T): R {.borrow.}
  proc g*(color: T): R {.borrow.}
  proc b*(color: T): R {.borrow.}

colorFieldsRgb Rgb8, uint8
colorFieldsRgb Rgb16, uint16
colorFieldsRgb Rgb32, uint32
colorFieldsRgb Rgb32f, float32

template colorFieldsRgba(T, R: type): untyped =
  proc r*(color: T): R {.borrow.}
  proc g*(color: T): R {.borrow.}
  proc b*(color: T): R {.borrow.}
  proc a*(color: T): R {.borrow.}

colorFieldsRgba Rgba8, uint8
colorFieldsRgba Rgba16, uint16
colorFieldsRgba Rgba32, uint32
colorFieldsRgba Rgba32f, float32

proc channels*(T: type[ColorPixelType]): range[1..4] =
  ## Returns the number of channels a given color pixel type holds.
  when T is Red8 | Red16 | Red32 | Red32f: 1
  when T is Rg8 | Rg16 | Rg32 | Rg32f: 2
  when T is Rgb8 | Rgb16 | Rgb32 | Rgb32f: 3
  when T is Rgba8 | Rgba16 | Rgba32 | Rgba32f: 4

proc internalFormat*(T: type[AnyPixelType]): GlEnum =
  ## Implementation detail, do not use.
  when T is Red8: GL_R8
  elif T is Red16: GL_R16
  elif T is Red32: GL_R32UI
  elif T is Red32f: GL_R32F
  elif T is Rg8: GL_RG8
  elif T is Rg16: GL_RG16
  elif T is Rg32: GL_RG32UI
  elif T is Rg32f: GL_RG32F
  elif T is Rgb8: GL_RGB8
  elif T is Rgb16: GL_RGB16
  elif T is Rgb32: GL_RGB32UI
  elif T is Rgb32f: GL_RGB32F
  elif T is Rgba8: GL_RGBA8
  elif T is Rgba16: GL_RGBA16
  elif T is Rgba32: GL_RGBA32UI
  elif T is Rgba32f: GL_RGBA32F
  elif T is Depth16: GL_DEPTH_COMPONENT16
  elif T is Depth24: GL_DEPTH_COMPONENT24
  elif T is Depth32: GL_DEPTH_COMPONENT32
  elif T is Depth32f: GL_DEPTH_COMPONENT32F
  elif T is Stencil1: GL_STENCIL_INDEX1
  elif T is Stencil4: GL_STENCIL_INDEX4
  elif T is Stencil8: GL_STENCIL_INDEX8
  elif T is Stencil16: GL_STENCIL_INDEX16
  elif T is Depth24Stencil8: GL_DEPTH24_STENCIL8
  elif T is Depth32fStencil8: GL_DEPTH32F_STENCIL8

proc dataType*(T: type[ClientPixelType]): GlEnum =
  ## Implementation detail, do not use.
  when T is Red8 | Rg8 | Rgb8 | Rgba8 | Stencil8:
    GL_TUNSIGNED_BYTE
  elif T is Red16 | Rg16 | Rgb16 | Rgba16 | Depth16 | Stencil16:
    GL_TUNSIGNED_SHORT
  elif T is Red32 | Rg32 | Rgb32 | Rgba32 | Depth32:
    GL_TUNSIGNED_INT
  elif T is Red32f | Rg32f | Rgb32f | Rgba32f | Depth32f:
    GL_TFLOAT

proc format*(T: type[AnyPixelType]): GlEnum =
  ## Implementation detail, do not use.
  when T is Red8 | Red16 | Red32 | Red32f: GL_RED
  elif T is Rg8 | Rg16 | Rg32 | Rg32f: GL_RG
  elif T is Rgb8 | Rgb16 | Rgb32 | Rgb32f: GL_RGB
  elif T is Rgba8 | Rgba16 | Rgba32 | Rgba32f: GL_RGBA
  elif T is Depth16 | Depth24 | Depth32 | Depth32f: GL_DEPTH_COMPONENT
  elif T is Stencil1 | Stencil4 | Stencil8 | Stencil16: GL_STENCIL_INDEX
  elif T is Depth24Stencil8 | Depth32fStencil8: GL_DEPTH_STENCIL
