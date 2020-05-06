## An array buffer storing an arbitrary mesh. This array buffer is a hybrid
## between a VAO, VBO and EBO. The EBO is only allocated when it's explicitly
## used through the constructor or ``uploadIndices``, so no memory is wasted.

import gl
import window

type
  IndexType* = uint8 | uint16 | uint32

  ArrayBuffer* = ref object
    gl: OpenGl
    vbo, ebo, vao: GlUint
    usage: GlEnum
    vboLen, eboLen: int
    vboCap, eboCap: int

  ArrayBufferUsage* = enum
    abuStream   ## buffer is initialized once and used a few times
    abuStatic   ## buffer is initialized once and used many times
    abuDynamic  ## buffer is modified repeatedly and used many times

proc vboCapacity*(buffer: ArrayBuffer): int =
  ## Returns the capacity of the buffer's VBO.
  buffer.vboCap

proc vboLen*(buffer: ArrayBuffer): int =
  ## Returns the length of the buffer's VBO.
  buffer.vboLen

proc hasEbo*(buffer: ArrayBuffer): bool =
  ## Returns whether the buffer has an EBO allocated.
  buffer.ebo != 0

proc eboCapacity*(buffer: ArrayBuffer): int =
  ## Returns the capacity of the buffer's EBO.
  buffer.eboCap

proc eboLen*(buffer: ArrayBuffer): int =
  ## Returns the length of the buffer's EBO.

proc useVbo(buffer: ArrayBuffer) =
  buffer.gl.bindBuffer(btArray, buffer.vbo)

proc useEbo(buffer: ArrayBuffer) =
  buffer.gl.bindBuffer(btElementArray, buffer.ebo)

proc uploadVertices*[T](buffer: ArrayBuffer, data: openArray[T]) =
  ## Uploads vertex data to the vertex buffer of the given array buffer.
  ## This operation is optimized, so if the data store can fit the given array,
  ## it is not relocated.

  if buffer.vbo == 0:
    buffer.vbo = buffer.gl.createBuffer()

  buffer.useVbo()

  let dataSize = (max(data) - min(data)) * sizeof(T)
  if buffer.vboCap < data.len:
    buffer.gl.bufferData(btArray, data[min(data)].unsafeAddr,
                         dataSize, buffer.usage)
    buffer.vboCap = data.len
  else:
    buffer.gl.bufferSubData(btArray, 0..dataSize, data[min(data)].unsafeAddr)

  buffer.vboLen = data.len

proc uploadIndices*[T: IndexType](buffer: ArrayBuffer, data: openArray[T]) =
  ## Uploads index data to the element buffer of the given array buffer. Note
  ## that vertices must be uploaded first; failing to do so will trigger an
  ## assertion.
  ## This operation is o

  assert buffer.vbo != 0, "vertices must be uploaded before indices"
  if buffer.ebo == 0:
    buffer.ebo = buffer.gl.createBuffer()

  buffer.useEbo()

  let dataSize = (max(data) - min(data)) * sizeof(T)
  if buffer.eboCap < data.len:
    buffer.gl.bufferData(btElementArray, data[min(data)].unsafeAddr,
                         dataSize, buffer.usage)
    buffer.eboCap = data.len
  else:
    buffer.gl.bufferSubData(btElementArray, 0..dataSize,
                            data[min(data)].unsafeAddr)

  buffer.eboLen = data.len

proc updateVertices*[T](buffer: ArrayBuffer, pos: int,
                        data: openArray[T]) =
  ## Updates vertices at the given position. ``pos + data.len`` must be less
  ## than ``buffer.vboCapacity``, otherwise an assertion is triggered.
  assert pos + data.len < buffer.vboCapacity,
    "given data won't fit in the vertex buffer"
  
  buffer.useVbo()

  let
    byteMin = pos * sizeof(T)
    byteMax = (pos + data.len) * sizeof(T)
  buffer.gl.bufferSubData(btArray, byteMin..byteMax,
                          data[min(data)].unsafeAddr)

proc updateIndices*[T: IndexType](buffer: ArrayBuffer, pos: int,
                                  data: openArray[T]) =
  ## Updates indices at the given range. ``pos + data.len``` must be less than
  ## ``buffer.eboCapacity``, otherwise an assertion is triggered.
  assert pos + data.len < buffer.vboCapacity,
    "given data won't fit in the index buffer"
  
  buffer.useEbo()

  let
    byteMin = pos * sizeof(T)
    byteMax = (pos + data.len) * sizeof(T)
  buffer.gl.bufferSubData(btElementArray, byteMin..byteMax,
                          data[min(data)].unsafeAddr)

proc newArrayBuffer*(win: Window, usage: ArrayBufferUsage): ArrayBuffer =
  let gl = win.IMPL_getGlContext()
  new(result) do (buffer: ArrayBuffer):
    buffer.gl.deleteBuffer(buffer.vbo)
    if buffer.hasEbo:
      buffer.gl.deleteBuffer(buffer.ebo)
  result.gl = gl
  result.usage =
    case usage
    of abuStream: GL_STREAM_DRAW
    of abuStatic: GL_STATIC_DRAW
    of abuDynamic: GL_DYNAMIC_DRAW
