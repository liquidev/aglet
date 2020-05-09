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

  Mesh*[V] = ref object
    gl: OpenGl
    vao: VertexArray
    vbo, ebo: GlUint
    usage: GlEnum
    fVboLen, fEboLen: Natural
    vboCap, eboCap: Natural
    eboType: IndexTypeEnum
    fPrimitive: DrawPrimitive
  MeshSlice*[V] = object
    mesh: Mesh[V]
    range: Slice[Natural]

  MeshUsage* = enum
    abuStream   ## mesh is initialized once and used a few times
    abuStatic   ## mesh is initialized once and used many times
    abuDynamic  ## mesh is modified repeatedly and used many times

  DrawPrimitive* = enum
    dpPoints
    dpLines
    dpLinesAdjacency
    dpLineStrip
    dpLineStripAdjacency
    dpLineLoop
    dpTriangles
    dpTrianglesAdjacency
    dpTriangleStrip
    dpTriangleStripAdjacency
    dpTriangleFan

proc toGlEnum(dp: DrawPrimitive): GlEnum =
  case dp
  of dpPoints: GL_POINTS
  of dpLines: GL_LINES
  of dpLinesAdjacency: GL_LINES_ADJACENCY
  of dpLineStrip: GL_LINE_STRIP
  of dpLineStripAdjacency: GL_LINE_STRIP_ADJACENCY
  of dpLineLoop: GL_LINE_LOOP
  of dpTriangles: GL_TRIANGLES
  of dpTrianglesAdjacency: GL_TRIANGLES_ADJACENCY
  of dpTriangleStrip: GL_TRIANGLE_STRIP
  of dpTriangleStripAdjacency: GL_TRIANGLE_STRIP_ADJACENCY
  of dpTriangleFan: GL_TRIANGLE_FAN

proc vboCapacity*(mesh: Mesh): int =
  ## Returns the capacity of the mesh's VBO.
  mesh.vboCap

proc vboLen*(mesh: Mesh): int =
  ## Returns the length of the mesh's VBO.
  mesh.fVboLen

proc hasEbo*(mesh: Mesh): bool =
  ## Returns whether the mesh has an EBO allocated.
  mesh.ebo != 0

proc eboCapacity*(mesh: Mesh): int =
  ## Returns the capacity of the mesh's EBO.
  mesh.eboCap

proc eboLen*(mesh: Mesh): int =
  ## Returns the length of the mesh's EBO.
  mesh.fEboLen

proc primitive*(mesh: Mesh): DrawPrimitive =
  ## Returns what primitive the mesh is built from.
  mesh.fPrimitive

proc `primitive=`*(mesh: Mesh, newPrimitive: DrawPrimitive) =
  ## Changes what primitive the mesh is built from.
  mesh.fPrimitive = newPrimitive

proc vertexCount*(mesh: Mesh): int =
  ## Returns the total amount of vertices that can be drawn using the mesh.
  if mesh.hasEbo: mesh.eboLen
  else: mesh.vboLen

proc primitiveCount*(mesh: Mesh): int =
  ## Returns how many primitives the mesh contains.
  let verts = mesh.vertexCount
  case mesh.primitive
  of dpPoints:
    verts
  of dpLines, dpLinesAdjacency:
    verts div 2
  of dpLineStrip, dpLineStripAdjacency:
    max(0, verts - 1)
  of dpLineLoop:
    if verts in [0, 1]: 0
    elif verts == 2: 1
    else: verts
  of dpTriangles, dpTrianglesAdjacency:
    verts div 3
  of dpTriangleStrip, dpTriangleStripAdjacency, dpTriangleFan:
    max(0, verts - 2)

proc useVbo(mesh: Mesh) =
  mesh.gl.bindBuffer(btArray, mesh.vbo)

proc useEbo(mesh: Mesh) =
  mesh.gl.bindBuffer(btElementArray, mesh.ebo)

proc use(mesh: Mesh) =
  mesh.gl.bindVertexArray(mesh.vao)

macro vaoAttribsAux(gl: typed, T: typedesc): untyped =
  result = newStmtList()

  var index = 0

  let impl = T.getTypeImpl[1].getTypeImpl  # yay for typedesc
  for identDefs in impl[2]:
    let ty = identDefs[^2]
    for name in identDefs[0..^3]:
      result.add(quote do:
        vertexAttrib[`ty`](`gl`, `index`, sizeof(`T`), offsetof(`T`, `name`)))
      inc(index)

  let countVar = newVarStmt(ident"attribCount", newLit(index))
  result.add(countVar)

proc updateVao[V](mesh: Mesh[V]) =
  if mesh.vao.id != 0:
    mesh.gl.deleteVertexArray(mesh.vao)

  mesh.useVbo()
  mesh.useEbo()

  mesh.vao = mesh.gl.createVertexArray()
  mesh.use()

  vaoAttribsAux(mesh.gl, V)
  for index in 0..<attribCount:  # from vaoAtrribsAux
    mesh.gl.enableVertexAttrib(index)

proc uploadVertices*[V](mesh: Mesh[V], data: openArray[V]) =
  ## Uploads vertex data to the vertex buffer of the given mesh.
  ## This operation is optimized, so if the data store can fit the given array,
  ## it is not reallocated.

  if mesh.vbo == 0:
    mesh.vbo = mesh.gl.createBuffer()
    mesh.updateVao[:V]()

  mesh.useVbo()

  let dataSize = data.len * sizeof(V)
  echo data
  if mesh.vboCap < data.len:
    mesh.gl.bufferData(btArray, dataSize, data[low(data)].unsafeAddr,
                       mesh.usage)
    mesh.vboCap = data.len
  else:
    mesh.gl.bufferSubData(btArray, 0..dataSize, data[low(data)].unsafeAddr)

  mesh.fVboLen = data.len

proc toEnum(T: IndexType): IndexTypeEnum {.compileTime.} =
  result =
    when T is uint8: it8
    elif T is uint16: it16
    elif T is uint32: it32
    else: itNone

proc uploadIndices*[V; I: IndexType](mesh: Mesh[V],
                                     data: openArray[I]) =
  ## Uploads index data to the element buffer of the given mesh. Note
  ## that vertices must be uploaded first; failing to do so will trigger an
  ## assertion.
  ## This operation is optimized, so if the data store can fit the given array,
  ## it is not reallocated.

  assert mesh.vbo != 0, "vertices must be uploaded before indices"
  if mesh.ebo == 0:
    mesh.ebo = mesh.gl.createBuffer()
    mesh.eboType = toEnum(I)
    mesh.updateVao[:V]()
  else:
    assert toEnum(T) == mesh.eboType,
      "data type mismatch: got <" & T & ">, " &
      "but the EBO is of type <" & mesh.eboType & ">"

  mesh.useEbo()

  let dataSize = data.len * sizeof(I)
  if mesh.eboCap < data.len:
    mesh.gl.bufferData(btElementArray, data[low(data)].unsafeAddr,
                       dataSize, mesh.usage)
    mesh.eboCap = data.len
  else:
    mesh.gl.bufferSubData(btElementArray, 0..dataSize,
                          data[low(data)].unsafeAddr)

  mesh.fEboLen = data.len

proc updateVertices*[V](mesh: Mesh[V], pos: Natural,
                        data: openArray[V]) =
  ## Updates vertices at the given position. ``pos + data.len`` must be less
  ## than ``mesh.vboCapacity``, otherwise an assertion is triggered.
  assert pos + data.len < mesh.vboCapacity,
    "given data won't fit in the vertex mesh"

  mesh.useVbo()

  let
    byteMin = pos * sizeof(V)
    byteMax = (pos + data.len) * sizeof(V)
  mesh.gl.bufferSubData(btArray, byteMin..byteMax,
                        data[low(data)].unsafeAddr)
  mesh.fVboLen = max(mesh.fVboLen, pos + data.len)

proc updateIndices*[I: IndexType](mesh: Mesh, pos: Natural,
                                  data: openArray[I]) =
  ## Updates indices at the given range. ``pos + data.len``` must be less than
  ## ``mesh.eboCapacity``, otherwise an assertion is triggered.
  assert pos + data.len < mesh.eboCapacity,
    "given data won't fit in the index mesh"
  assert toEnum(T) == mesh.eboType,
    "data type mismatch: got <" & T & ">, " &
    "but the EBO is of type <" & mesh.eboType & ">"

  mesh.useEbo()

  let
    byteMin = pos * sizeof(I)
    byteMax = (pos + data.len) * sizeof(I)
  mesh.gl.bufferSubData(btElementArray, byteMin..byteMax,
                        data[low(data)].unsafeAddr)
  mesh.fEboLen = max(mesh.fEboLen, pos + data.len)

proc `[]`*[V](mesh: Mesh[V], range: Slice[int]): MeshSlice[V] =
  ## Returns a MeshSlice for rendering only specified parts (slices)
  ## of the mesh. The specified bounds refer to vertex indices.
  assert range.a <= range.b,
    "first (lower) bound must be greater than the second (higher) bound"
  assert range.a < mesh.vertexCount, "lower index out of range"
  assert range.b < mesh.vertexCount, "higher index out of range"
  result = MeshSlice[V](mesh: mesh, range: range.a.Natural..range.b.Natural)

proc draw*(slice: MeshSlice, gl: OpenGl) =
  ## ``Drawable`` implementation for ``target.draw``, do not use directly.
  slice.mesh.use()
  if slice.mesh.hasEbo:
    discard  # TODO EBOs
  else:
    gl.drawArrays(slice.mesh.primitive.toGlEnum,
                  slice.range.a, 1 + slice.range.b - slice.range.a)

converter allVertices*[V](mesh: Mesh[V]): MeshSlice[V] =
  ## Implicit converter to avoid having to use ``mesh[0..<mesh.vertexCount]``
  ## when attempting to draw something.
  result = mesh[0..<mesh.vertexCount]

proc newMesh*[V](win: Window, usage: MeshUsage,
                 primitive: DrawPrimitive): Mesh[V] =
  let gl = win.IMPL_getGlContext()
  new(result) do (mesh: Mesh[V]):
    mesh.gl.deleteBuffer(mesh.vbo)
    if mesh.hasEbo:
      mesh.gl.deleteBuffer(mesh.ebo)
  result.gl = gl
  result.usage =
    case usage
    of abuStream: GL_STREAM_DRAW
    of abuStatic: GL_STATIC_DRAW
    of abuDynamic: GL_DYNAMIC_DRAW
  result.primitive = primitive
