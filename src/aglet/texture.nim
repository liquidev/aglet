## 1D, 2D, and 3D textures and samplers.

import std/tables

import gl
import uniform
import window

type
  PixelType* =
    uint8 | Vec2[uint8] | Vec3[uint8] | Vec4[uint8] |
    float32 | Vec2f | Vec3f | Vec4f |
    int32 | Vec2i | Vec3i | Vec4i |
    uint32 | Vec2ui | Vec3ui | Vec4ui

  TextureFilter* = enum
    tfNearest
    tfLinear
    tfNearestMipmapNearest
    tfNearestMipmapLinear
    tfLinearMipmapNearest
    tfLinearMipmapLinear
  TextureMinFilter* = TextureFilter
  TextureMagFilter* = range[tfNearest..tfLinear]

  TextureWrap* = enum
    twRepeat
    twMirroredRepeat
    twClampToEdge
    twClampToBorder

  SamplerParams = tuple
    minFilter: TextureMinFilter
    magFilter: TextureMagFilter
    wrapS, wrapT, wrapR: TextureWrap
    # std/hashes for tuples was having a stroke so I had to do this
    borderColor: (float32, float32, float32, float32)
  Sampler* = ref object
    texture {.cursor.}: Texture
    id: GlUint
    textureTarget: TextureTarget

  Texture = ref object of RootObj
    gl: OpenGl
    id: GlUint
    samplers: Table[SamplerParams, Sampler]
    mipmapped, dirty: bool
  TextureArray = ref object of Texture

  Texture1D* {.final.} = ref object of Texture
    fWidth: int
  Texture1DArray* {.final.} = ref object of TextureArray
    fWidth, fLen: int
  Texture2D* {.final.} = ref object of Texture
    fWidth, fHeight: int
    fMultisample: bool
  Texture2DArray* {.final.} = ref object of TextureArray
    fWidth, fHeight, fLen: int
    fMultisample: bool
  Texture3D* {.final.} = ref object of Texture
    fWidth, fHeight, fDepth: int
  TextureCubeMap* {.final.} = ref object of Texture
    fWidth, fHeight: int

  Some2DTexture* = Texture2D | Texture2DArray

proc toGlEnum(filter: TextureFilter): GlEnum =
  case filter
  of tfNearest: GL_NEAREST
  of tfLinear: GL_LINEAR
  of tfNearestMipmapNearest: GL_NEAREST_MIPMAP_NEAREST
  of tfNearestMipmapLinear: GL_NEAREST_MIPMAP_LINEAR
  of tfLinearMipmapNearest: GL_LINEAR_MIPMAP_NEAREST
  of tfLinearMipmapLinear: GL_LINEAR_MIPMAP_LINEAR

proc toGlEnum(wrap: TextureWrap): GlEnum =
  case wrap
  of twRepeat: GL_REPEAT
  of twMirroredRepeat: GL_MIRRORED_REPEAT
  of twClampToEdge: GL_CLAMP_TO_EDGE
  of twClampToBorder: GL_CLAMP_TO_BORDER

proc format(T: typedesc[PixelType]): GlEnum =
  when T is uint8 | float32 | int32 | uint32: GL_RED
  elif T is Vec2[uint8] | Vec2f | Vec2i | Vec2ui: GL_RG
  elif T is Vec3[uint8] | Vec3f | Vec3i | Vec3ui: GL_RGB
  elif T is Vec4[uint8] | Vec4f | Vec4i | Vec4ui: GL_RGBA

proc dataType(T: typedesc[PixelType]): GlEnum =
  when T is uint8 | Vec2[uint8] | Vec3[uint8] | Vec4[uint8]: GL_TUNSIGNED_BYTE
  elif T is float32 | Vec2f | Vec3f | Vec4f: GL_TFLOAT
  elif T is int32 | Vec2i | Vec3i | Vec4i: GL_TINT
  elif T is uint32 | Vec2ui | Vec3ui | Vec4ui: GL_TUNSIGNED_INT

proc texture*(sampler: Sampler): Texture =
  ## Retrieves the texture this sampler was created for.
  ## Note that this returns the *generic* ``Texture`` type, which can later be
  ## casted to any of its descendants. The type of the descendant can be checked
  ## using the ``of`` operator, eg. ``sampler.texture of Texture2D`` will check
  ## if the sampler was created for a 2D texture.
  sampler.texture

proc width*(texture: Texture1D): int =
  ## Returns the width of the texture.
  texture.fWidth

proc width*(array: Texture1DArray): int =
  ## Returns the width of all the 1D textures stored in the array.
  array.fWidth

proc len*(array: Texture1DArray): int =
  ## Returns how many 1D textures the array stores.
  array.fLen

proc width*(texture: Texture2D): int =
  ## Returns the width of the texture.
  texture.fWidth

proc height*(texture: Texture2D): int =
  ## Returns the height of the texture.
  texture.fHeight

proc width*(array: Texture2DArray): int =
  ## Returns the width of all the 2D textures stored in the array.
  array.fWidth

proc height*(array: Texture2DArray): int =
  ## Returns the height of all the 2D textures stored in the array.
  array.fHeight

proc len*(array: Texture2DArray): int =
  ## Returns how many 2D textures the array stores.
  array.fLen

proc multisampled*(texture: Some2DTexture): bool =
  ## Returns whether the texture is multisampled.
  texture.fMultisample

proc width*(texture: Texture3D): int =
  ## Returns the width of the texture.
  texture.fWidth

proc height*(texture: Texture3D): int =
  ## Returns the height of the texture.
  texture.fHeight

proc depth*(texture: Texture3D): int =
  ## Returns the depth of the texture.
  texture.fDepth

proc width*(texture: TextureCubeMap): int =
  ## Returns the width of each texture in the cubemap.
  texture.fWidth

proc height*(texture: TextureCubeMap): int =
  ## Returns the height of each texture in the cubemap.
  texture.fHeight

proc target[T: Texture](texture: T): TextureTarget =
  when T is Texture1D: ttTexture1D
  elif T is Texture1DArray: ttTexture1DArray
  elif T is Texture2D:
    if texture.multisampled: ttTexture2DMultisample
    else: ttTexture2D
  elif T is Texture2DArray:
    if texture.multisampled: ttTexture2DMultisampleArray
    else: ttTexture2DArray
  elif T is Texture3D: ttTexture3D
  elif T is TextureCubeMap: ttTextureCubeMap

proc use[T: Texture](texture: T) =
  texture.gl.bindTexture(texture.target, texture.id)

proc subImage*[T: PixelType](texture: Texture1D, x: Natural, width: Positive,
                             data: ptr T) =
  ## Updates a portion of the texture. ``x + width`` must be less than or equal
  ## to ``texture.width``, otherwise an assertion is triggered.
  ## This procedure deals with pointers and so it is **unsafe**, prefer the
  ## ``openArray`` version instead.

  assert x + width <= texture.width, "pixels cannot be copied out of bounds"
  assert data != nil
  texture.use()
  texture.gl.subImage1D(x, width, T.format, T.dataType, data)
  texture.dirty = true

proc subImage*[T: PixelType](texture: Texture1D, x: Natural,
                             data: openArray[T]) =
  ## Safe version of ``subImage``. The width is inferred from the length of
  ## ``data``.

  texture.subImage[:T](x, data.len, data[0].unsafeAddr)

proc upload*[T: PixelType](texture: Texture1D, width: Positive, data: ptr T) =
  ## Upload generic data to the texture. This will only allocate a new data
  ## store if the texture's existing width does not match the target width.
  ## This procedure is **unsafe** and should only be used in specific cases.
  ## Prefer the ``openArray`` version instead.

  assert data != nil
  texture.use()
  if texture.fWidth != width:
    texture.gl.data1D(width, T.format, T.dataType)
    texture.fWidth = width
  texture.subImage(0, width, data)

proc upload*[T: PixelType](texture: Texture1D, data: openArray[T]) =
  ## Safe version of ``upload``. The width of the texture is inferred from the
  ## length of the data array. This will only allocate a new data store if the
  ## texture's existing width does not match the target width.

  assert data.len > 0
  texture.upload[:T](data.len, data[0].unsafeAddr)

proc sampler*[T: Texture](texture: T,
                          minFilter: TextureMinFilter = tfNearestMipmapLinear,
                          magFilter: TextureMagFilter = tfLinear,
                          wrapS, wrapT, wrapR = twRepeat,
                          borderColor = vec4f(0.0, 0.0, 0.0, 0.0)): Sampler =
  ## Creates a sampler for the given texture, with the provided parameters.
  ## ``minFilter`` and ``magFilter`` specify the filtering used when sampling
  ## non-integer coordinates. ``wrap(S|T|R)`` specify the texture wrapping on
  ## the X, Y, and Z axes respectively. ``borderColor`` specifies the border
  ## color to be used when any of the ``wrap`` options is ``twClampToBorder``.

  let params = SamplerParams (minFilter, magFilter,
                              wrapS, wrapT, wrapR,
                              (borderColor.r, borderColor.g, borderColor.b,
                               borderColor.a))

  if params in texture.samplers:
    result = texture.samplers[params]
  else:

    result = Sampler(texture: texture,
                     id: texture.gl.createSampler(),
                     textureTarget: texture.target)

    var borderColor = borderColor
    texture.gl.samplerParam(result.id, GL_TEXTURE_MIN_FILTER,
                            GlInt(minFilter.toGlEnum))
    texture.gl.samplerParam(result.id, GL_TEXTURE_MAG_FILTER,
                            GlInt(magFilter.toGlEnum))
    texture.gl.samplerParam(result.id, GL_TEXTURE_WRAP_S,
                            GlInt(wrapS.toGlEnum))
    texture.gl.samplerParam(result.id, GL_TEXTURE_WRAP_T,
                            GlInt(wrapT.toGlEnum))
    texture.gl.samplerParam(result.id, GL_TEXTURE_WRAP_R,
                            GlInt(wrapR.toGlEnum))
    texture.gl.samplerParam(result.id, GL_TEXTURE_BORDER_COLOR,
                            borderColor.caddr)

    texture.samplers[params] = result

  if texture.mipmapped and texture.dirty:
    texture.use()
    texture.gl.genMipmaps(texture.target)
    texture.dirty = false

proc toUniform*(sampler: Sampler): Uniform =
  let usampler = USampler(textureTarget: sampler.textureTarget.uint8,
                          textureId: sampler.texture.id,
                          samplerId: sampler.id)
  result = Uniform(ty: utUSampler, valUSampler: usampler)

template textureInit(gl: OpenGl) =
  new(result) do (texture: typeof(result)):
    texture.gl.deleteTexture(texture.id)
  result.id = gl.createTexture()
  result.gl = gl
  result.mipmapped = mipmapped

proc newTexture1D*(win: Window, mipmapped = true): Texture1D =
  ## Creates a new texture. What the texture contains is undefined
  ## (it may be cleared to zeroes, but some drivers may simply leave leftover
  ## garbage remaining in the texture).

  var gl = win.IMPL_getGlContext()

  textureInit(gl)

proc newTexture1D*[T: PixelType](win: Window, width: Positive,
                                 data: ptr T, mipmapped = true): Texture1D =
  ## Creates a new texture and initializes it with some data stored at the given
  ## pointer. If you want to upload data, this procedure is unsafe as it deals
  ## with pointers. Prefer the ``openArray`` and ``BinaryImageBuffer`` versions
  ## instead.

  result = win.newTexture1D(mipmapped)
  result.upload[:T](width, data)

proc newTexture1D*[T: PixelType](win: Window, data: openArray[T],
                                 mipmapped = true): Texture1D =
  ## Creates a new texture and initializes it with the given data.
  ## The width of the texture is inferred from the data's length, which must not
  ## be zero.

  result = win.newTexture1D(mipmapped)
  result.upload[:T](data)
