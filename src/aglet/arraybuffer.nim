## An array buffer storing an arbitrary mesh. This array buffer is a hybrid
## between a VAO, VBO and EBO. The EBO is only allocated when it's explicitly
## used through the constructor or ``uploadIndices``, so no memory is wasted.

import std/macros

import gl
import window

type
  IndexType* = uint8 | uint16 | uint32
  IndexTypeEnum = enum
    itNone = "<invalid>"
    it8 = "uint8"
    it16 = "uint16"
    it32 = "uint32"

  ArrayBuffer*[V] = ref object
    gl: OpenGl
    vbo, ebo, vao: GlUint
    usage: GlEnum
    fVboLen, fEboLen: int
    vboCap, eboCap: int
    eboType: IndexTypeEnum

  ArrayBufferUsage* = enum
    abuStream   ## buffer is initialized once and used a few times
    abuStatic   ## buffer is initialized once and used many times
    abuDynamic  ## buffer is modified repeatedly and used many times

proc vboCapacity*(buffer: ArrayBuffer): int =
  ## Returns the capacity of the buffer's VBO.
  buffer.vboCap

proc vboLen*(buffer: ArrayBuffer): int =
  ## Returns the length of the buffer's VBO.
  buffer.fVboLen

proc hasEbo*(buffer: ArrayBuffer): bool =
  ## Returns whether the buffer has an EBO allocated.
  buffer.ebo != 0

proc eboCapacity*(buffer: ArrayBuffer): int =
  ## Returns the capacity of the buffer's EBO.
  buffer.eboCap

proc eboLen*(buffer: ArrayBuffer): int =
  ## Returns the length of the buffer's EBO.
  buffer.fEboLen

proc useVbo(buffer: ArrayBuffer) =
  buffer.gl.bindBuffer(btArray, buffer.vbo)

proc useEbo(buffer: ArrayBuffer) =
  buffer.gl.bindBuffer(btElementArray, buffer.ebo)

macro vaoAttribsAux(gl: typed, T: typedesc): untyped =
  result = newStmtList()

  var index = 0

  let impl = T.getTypeImpl[1].getTypeImpl  # yay for typedesc
  if impl.kind notin {nnkObjectTy, nnkTupleTy}:
    error("vertex type must be an object or a tuple", T)
  for identDefs in impl[2]:
    let ty = identDefs[^2]
    for name in identDefs[0..^3]:
      let
        genericInst = newTree(nnkBracketExpr, bindSym"vertexAttrib", ty)
        call = newCall(genericInst, gl, newLit(index), newLit(sizeof(T)),
                       newCall(bindSym"offsetof", T, name))
      result.add(call)
      inc(index)

  # as much as I don't like this, I don't think there's a better solution to
  # return *both* some statements and a value from a macro
  let countDecl = newVarStmt(ident"attribCount", newLit(index))
  result.add(countDecl)

proc updateVao[V](buffer: ArrayBuffer[V]) =
  if buffer.vao != 0:
    buffer.gl.deleteVertexArray(buffer.vao)
  buffer.useVbo()
  buffer.useEbo()

  vaoAttribsAux(buffer.gl, V)
  buffer.vao = buffer.gl.createVertexArray()
  for index in 0..<attribCount:  # from vaoAttribsAux
    buffer.gl.disableVertexAttrib(index)

proc uploadVertices*[V](buffer: ArrayBuffer[V], data: openArray[V]) =
  ## Uploads vertex data to the vertex buffer of the given array buffer.
  ## This operation is optimized, so if the data store can fit the given array,
  ## it is not reallocated.

  if buffer.vbo == 0:
    buffer.vbo = buffer.gl.createBuffer()
    buffer.updateVao[:V]()

  buffer.useVbo()

  let dataSize = data.len * sizeof(V)
  if buffer.vboCap < data.len:
    buffer.gl.bufferData(btArray, dataSize, data[low(data)].unsafeAddr,
                         buffer.usage)
    buffer.vboCap = data.len
  else:
    buffer.gl.bufferSubData(btArray, 0..dataSize, data[low(data)].unsafeAddr)

  buffer.fVboLen = data.len

proc toEnum(T: IndexType): IndexTypeEnum {.compileTime.} =
  result =
    when T is uint8: it8
    elif T is uint16: it16
    elif T is uint32: it32
    else: itNone

proc uploadIndices*[V; I: IndexType](buffer: ArrayBuffer[V],
                                     data: openArray[I]) =
  ## Uploads index data to the element buffer of the given array buffer. Note
  ## that vertices must be uploaded first; failing to do so will trigger an
  ## assertion.
  ## This operation is optimized, so if the data store can fit the given array,
  ## it is not reallocated.

  assert buffer.vbo != 0, "vertices must be uploaded before indices"
  if buffer.ebo == 0:
    buffer.ebo = buffer.gl.createBuffer()
    buffer.eboType = toEnum(I)
    buffer.updateVao[:V]()
  else:
    assert toEnum(T) == buffer.eboType,
      "data type mismatch: got <" & T & ">, " &
      "but the EBO is of type <" & buffer.eboType & ">"

  buffer.useEbo()

  let dataSize = data.len * sizeof(I)
  if buffer.eboCap < data.len:
    buffer.gl.bufferData(btElementArray, data[low(data)].unsafeAddr,
                         dataSize, buffer.usage)
    buffer.eboCap = data.len
  else:
    buffer.gl.bufferSubData(btElementArray, 0..dataSize,
                            data[low(data)].unsafeAddr)

  buffer.fEboLen = data.len

proc updateVertices*[V](buffer: ArrayBuffer[V], pos: int,
                        data: openArray[V]) =
  ## Updates vertices at the given position. ``pos + data.len`` must be less
  ## than ``buffer.vboCapacity``, otherwise an assertion is triggered.
  assert pos + data.len < buffer.vboCapacity,
    "given data won't fit in the vertex buffer"

  buffer.useVbo()

  let
    byteMin = pos * sizeof(V)
    byteMax = (pos + data.len) * sizeof(V)
  buffer.gl.bufferSubData(btArray, byteMin..byteMax,
                          data[low(data)].unsafeAddr)
  buffer.fVboLen = max(buffer.fVboLen, pos + data.len)

proc updateIndices*[I: IndexType](buffer: ArrayBuffer, pos: int,
                                  data: openArray[I]) =
  ## Updates indices at the given range. ``pos + data.len``` must be less than
  ## ``buffer.eboCapacity``, otherwise an assertion is triggered.
  assert pos + data.len < buffer.eboCapacity,
    "given data won't fit in the index buffer"
  assert toEnum(T) == buffer.eboType,
    "data type mismatch: got <" & T & ">, " &
    "but the EBO is of type <" & buffer.eboType & ">"

  buffer.useEbo()

  let
    byteMin = pos * sizeof(I)
    byteMax = (pos + data.len) * sizeof(I)
  buffer.gl.bufferSubData(btElementArray, byteMin..byteMax,
                          data[low(data)].unsafeAddr)
  buffer.fEboLen = max(buffer.fEboLen, pos + data.len)

proc newArrayBuffer*[V](win: Window, usage: ArrayBufferUsage): ArrayBuffer[V] =
  let gl = win.IMPL_getGlContext()
  new(result) do (buffer: ArrayBuffer[V]):
    buffer.gl.deleteBuffer(buffer.vbo)
    if buffer.hasEbo:
      buffer.gl.deleteBuffer(buffer.ebo)
  result.gl = gl
  result.usage =
    case usage
    of abuStream: GL_STREAM_DRAW
    of abuStatic: GL_STATIC_DRAW
    of abuDynamic: GL_DYNAMIC_DRAW
