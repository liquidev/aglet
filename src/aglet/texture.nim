## 1D, 2D, and 3D textures and samplers.

import std/tables

import gl
import uniform
import window


# types

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
    dirty: bool

  TextureArray = ref object of Texture

  Texture1D* {.final.} = ref object of Texture
    fWidth: int
  Texture2D* {.final.} = ref object of Texture
    fWidth, fHeight: int
    fMultisample: bool
  Texture3D* {.final.} = ref object of Texture
    fWidth, fHeight, fDepth: int
  Texture1DArray* {.final.} = ref object of TextureArray
    fWidth, fLen: int
  Texture2DArray* {.final.} = ref object of TextureArray
    fWidth, fHeight, fLen: int
    fMultisample: bool
  TextureCubeMap* {.final.} = ref object of Texture
    fWidth, fHeight: int

  Some2DTexture* = Texture2D | Texture2DArray

  ByteArray* = concept array
    ## Describes an array of values, of which each one can be casted to a uint8.
    sizeof(array[int]) == 1

  BinaryImageBuffer* = concept image
    ## Concept describing an image that holds some arbitrary 8-bit data.
    image.width is SomeInteger
    image.height is SomeInteger
    image.data is ByteArray


# utilities

const
  tfMipmapped = {tfNearestMipmapNearest..tfLinearMipmapLinear}

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


# getters

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


# 1D

proc subImage*[T: PixelType](texture: Texture1D, x: int, width: Positive,
                             data: ptr T) =
  ## Updates a portion of the texture. ``x + width`` must be less than or equal
  ## to ``texture.width``, otherwise an assertion is triggered.
  ## This procedure deals with pointers and so it is **unsafe**, prefer the
  ## ``openArray`` version instead.

  assert x >= 0
  assert x + width <= texture.width, "pixels cannot be copied out of bounds"
  assert data != nil
  texture.use()
  texture.gl.subImage1D(x, width, T.format, T.dataType, data)
  texture.dirty = true

proc subImage*[T: PixelType](texture: Texture1D, x: int,
                             data: openArray[T]) =
  ## Safe version of ``subImage``. The width is inferred from the length of
  ## ``data``.

  texture.subImage[:T](x, data.len, data[0].unsafeAddr)

proc upload*[T: PixelType](texture: Texture1D, width: int, data: ptr T) =
  ## Upload generic data to the texture. This will only allocate a new data
  ## store if the texture's existing width does not match the target width.
  ## This procedure is **unsafe** and should only be used in specific cases.
  ## Prefer the ``openArray`` version instead.

  assert data != nil
  assert width > 0
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
  texture.upload(data.len, data[0].unsafeAddr)

template textureInit(gl: OpenGl) =
  new(result) do (texture: typeof(result)):
    texture.gl.deleteTexture(texture.id)
  result.id = gl.createTexture()
  result.gl = gl

proc newTexture1D*(win: Window): Texture1D =
  ## Creates a new 1D texture. The texture does not contain any data; a data
  ## store must be allocated using ``upload`` before the texture is used.

  var gl = win.IMPL_getGlContext()
  textureInit(gl)

proc newTexture1D*[T: PixelType](win: Window, width: Positive,
                                 data: ptr T): Texture1D =
  ## Creates a new 1D texture and initializes it with data stored at the
  ## given pointer. This procedure is **unsafe** as it deals with pointers.
  ## Prefer the ``openArray`` version instead.

  result = win.newTexture1D()
  result.upload[:T](width, data)

proc newTexture1D*[T: PixelType](win: Window, data: openArray[T]): Texture1D =
  ## Creates a new 1D texture and initializes it with the given data.
  ## The width of the texture is inferred from the data's length, which must not
  ## be zero.

  result = win.newTexture1D()
  result.upload[:T](data)


# 2D

proc subImage*[T: PixelType](texture: Texture2D, position, size: Vec2i,
                             data: ptr T) =
  ## ``subImage`` for 2D textures. Same rules as apply as for 1D textures,
  ## except the Y coordinate is checked as well.
  ## This procedure deals with pointers and so, it is **unsafe**. Prefer the
  ## ``openArray`` version for dealing with generated data, or the
  ## ``BinaryImageBuffer`` version for dealing with data loaded from other
  ## libraries like nimPNG or flippy.

  assert position.x >= 0 and position.y >= 0
  assert size.x > 0 and size.y > 0
  assert position.x + size.x <= texture.fWidth and
         position.y + size.y <= texture.fHeight,
    "pixels cannot be copied out of bounds"
  assert data != nil
  texture.use()
  texture.gl.subImage2D(texture.target, position.x, position.y, size.x, size.y,
                        T.format, T.dataType, data)
  texture.dirty = true

proc subImage*[T: PixelType](texture: Texture2D, position, size: Vec2i,
                             data: openArray[T]) =
  ## ``subImage`` for 2D textures that accepts an ``openArray`` for data.
  ## ``data.len`` must be equal to ``size.x * size.y``, otherwise an assertion
  ## is triggered.

  assert data.len == size.x * size.y
  texture.subImage(position, size, data[0].unsafeAddr)

proc channelCountToGlEnum(channels: range[1..4]): GlEnum =
  case channels
  of 1: GL_RED
  of 2: GL_RG
  of 3: GL_RGB
  of 4: GL_RGBA

proc subImage*[T: BinaryImageBuffer](texture: Texture2D,
                                     position: Vec2i,
                                     image: T, channels: range[1..4] = 4) =
  ## ``subImage`` for loading arbitrary image data to the texture.
  ## This procedure allows for compatibility with existing image libraries,
  ## like nimPNG or Flippy, without them being a hard dependency.

  assert image.data.len == image.width * image.height * channels
  assert position.x >= 0 and position.y >= 0
  texture.use()
  texture.gl.subImage2D(texture.target,
                        position.x, position.y, image.width, image.height,
                        channelCountToGlEnum(channels), GL_TUNSIGNED_BYTE,
                        image.data[0].unsafeAddr)
  texture.dirty = true

proc upload*[T: PixelType](texture: Texture2D, size: Vec2i,
                           data: ptr T) =
  ## Uploads arbitrary data to the texture. This only allocates a new data store
  ## if the texture's existing size does not match the target size.
  ## This procedure deals with pointers, and so it is **unsafe**. Prefer the
  ## ``openArray`` and ``BinaryImageBuffer`` versions instead.

  assert data != nil
  assert size.x > 0 and size.y > 0
  texture.use()
  if texture.fWidth != size.x or texture.fHeight != size.y:
    texture.gl.data2D(texture.target, size.x, size.y, T.format, T.dataType)
    texture.fWidth = size.x
    texture.fHeight = size.y
  texture.subImage(vec2i(0, 0), size, data)

proc upload*[T: PixelType](texture: Texture2D, size: Vec2i,
                           data: openArray[T]) =
  ## Safe version of ``upload``. ``data.len`` must be equal to
  ## ``size.x * size.y``, otherwise an assertion is triggered.

  texture.upload(size, data[0].unsafeAddr)

proc upload*[T: BinaryImageBuffer](texture: Texture2D, image: T,
                                   channels: range[1..4] = 4) =
  ## Generic image buffer version of ``upload``, for use with libraries like
  ## nimPNG or Flippy.

  assert image.width > 0 and image.height > 0
  texture.use()
  if texture.fWidth != image.width or texture.fHeight != image.height:
    texture.gl.data2D(texture.target, image.width, image.height,
                      channelCountToGlEnum(channels), GL_TUNSIGNED_BYTE)
    texture.fWidth = image.width
    texture.fHeight = image.height
  texture.subImage(vec2i(0, 0), image, channels)

proc newTexture2D*(win: Window): Texture2D =
  ## Creates a new 2D texture. The texture does not contain any data; a data
  ## store must be allocated using ``upload`` before the texture is used.

  var gl = win.IMPL_getGlContext()
  textureInit(gl)

proc newTexture2D*[T: PixelType](win: Window, size: Vec2i,
                                 data: ptr T): Texture2D =
  ## Creates a new 2D texture and initializes it with data stored at the given
  ## pointer. This procedure is **unsafe** as it deals with pointers.
  ## Prefer the ``openArray`` and ``BinaryImageBuffer`` versions when possible.

  result = win.newTexture2D()
  result.upload[:T](size, data)

proc newTexture2D*[T: PixelType](win: Window, size: Vec2i,
                                 data: openArray[T]): Texture2D =
  ## Creates a new 2D texture and initializes it with data stored in the given
  ## array.

  result = win.newTexture2D()
  result.upload[:T](size, data)

proc newTexture2D*[T: BinaryImageBuffer](win: Window, image: T): Texture2D =
  ## Creates a new 2D texture and initializes it with pixels stored in the given
  ## image.

  result = win.newTexture2D()
  result.upload[:T](image)


# 3D

proc subImage*[T: PixelType](texture: Texture3D, position, size: Vec3i,
                             data: ptr T) =
  ## ``subImage`` for 3D texture.
  ## This procedure deals with pointers and so, it is **unsafe**. Prefer the
  ## ``openArray`` version instead.

  assert position.x >= 0 and position.y >= 0 and position.z >= 0
  assert size.x > 0 and size.y > 0 and size.z > 0
  assert position.x + size.x <= texture.fWidth and
         position.y + size.y <= texture.fHeight and
         position.z + size.z <= texture.fDepth,
    "pixels cannot be copied out of bounds"
  assert data != nil
  texture.use()
  texture.gl.subImage3D(texture.target,
                        position.x, position.y, position.z,
                        size.x, size.y, size.z,
                        T.format, T.dataType, data)
  texture.dirty = true

proc subImage*[T: PixelType](texture: Texture3D, position, size: Vec3i,
                             data: openArray[T]) =
  ## ``subImage`` for 3D textures that accepts an ``openArray`` for data.
  ## ``data.len`` must be equal to ``size.x * size.y * size.z``, otherwise an
  ## assertion is triggered.

proc upload*[T: PixelType](texture: Texture3D, size: Vec3i, data: ptr T) =
  ## Uploads arbitrary data to the texture. This only allocates a new data store
  ## if the texture's existing size does not match the target size.
  ## This procedure deals with pointers, and so it is **unsafe**. Prefer the
  ## ``openArray`` version instead.

  assert data != nil
  assert size.x > 0 and size.y > 0 and size.z > 0
  texture.use()
  if texture.fWidth != size.x or
     texture.fHeight != size.y or
     texture.fDepth != size.z:
    texture.gl.data3D(texture.target, size.x, size.y, size.z,
                      T.format, T.dataType)
    texture.fWidth = size.x
    texture.fHeight = size.y
    texture.fDepth = size.z
  texture.subImage(vec3i(0, 0, 0), size, data)

proc upload*[T: PixelType](texture: Texture3D, size: Vec3i,
                           data: openArray[T]) =
  ## Safe version of ``upload``. ``data.len`` must be equal to
  ## ``size.x * size.y * size.z``, otherwise an assertion is triggered.

  assert data.len == size.x * size.y * size.z
  texture.upload(size, data[0].unsafeAddr)

proc newTexture3D*(win: Window): Texture3D =
  ## Creates a new 3D texture without and data. A data store must be allocated
  ## using ``upload`` before the texture is used.

  var gl = win.IMPL_getGlContext()
  textureInit(gl)

proc newTexture3D*[T: PixelType](win: Window, size: Vec3i,
                                 data: ptr T): Texture3D =
  ## Creates a new 3D texture and initializes it with data stored at the given
  ## pointer. This procedure is **unsafe** as it deals with pointers.
  ## Prefer the ``openArray`` version instead.

  result = win.newTexture3D()
  result.upload[:T](size, data)

proc newTexture3D*[T: PixelType](win: Window, size: Vec3i,
                                 data: openArray[T]): Texture3D =
  ## Creates a new 3D texture and initializes it with data stored in the given
  ## array. ``data.len`` must be equal to ``size.x * size.y * size.z``,
  ## otherwise an assertion is triggered.

  result = win.newTexture3D()
  result.upload[:T](size, data)


# sampler

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

  if minFilter in tfMipmapped and texture.dirty:
    texture.use()
    texture.gl.genMipmaps(texture.target)
    texture.dirty = false

proc toUniform*(sampler: Sampler): Uniform =
  let usampler = USampler(textureTarget: sampler.textureTarget.uint8,
                          textureId: sampler.texture.id,
                          samplerId: sampler.id)
  result = Uniform(ty: utUSampler, valUSampler: usampler)
