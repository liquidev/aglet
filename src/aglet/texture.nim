## 1D, 2D, and 3D textures.

import gl

type
  Texture = object of RootObj
    id: GlUint
  TextureArray = object of RootObj
    id: GlUint

  Texture1D* {.final.} = ref object of Texture
  Texture2D* {.final.} = ref object of Texture
  Texture3D* {.final.} = ref object of Texture
  Texture1DArray* {.final.} = ref object of TextureArray
  Texture2DArray* {.final.} = ref object of TextureArray
  Texture3DArray* {.final.} = ref object of TextureArray
