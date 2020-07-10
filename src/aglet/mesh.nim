## An array buffer storing an arbitrary mesh. This array buffer is a hybrid
## between a VAO, VBO and EBO. The EBO is only allocated when it's explicitly
## used through the constructor or ``uploadIndices``, so no memory is wasted.

import std/macros
import std/options

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
    window: Window
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
    instanceCount: Option[Natural]

  MeshUsage* = enum
    muStream   ## mesh is initialized once and used a few times
    muStatic   ## mesh is initialized once and used many times
    muDynamic  ## mesh is modified repeatedly and used many times

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

proc toGlEnum(dp: DrawPrimitive): GlEnum {.inline.} =
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

proc toGlEnum(ty: IndexTypeEnum): GlEnum {.inline.} =
  case ty
  of it8: GL_TUNSIGNED_BYTE
  of it16: GL_TUNSIGNED_SHORT
  of it32: GL_TUNSIGNED_INT
  else: GlEnum(0)

proc vboCapacity*(mesh: Mesh): int {.inline.} =
  ## Returns the capacity of the mesh's VBO.
  mesh.vboCap

proc vboLen*(mesh: Mesh): int {.inline.} =
  ## Returns the length of the mesh's VBO.
  mesh.fVboLen

proc hasEbo*(mesh: Mesh): bool {.inline.} =
  ## Returns whether the mesh has an EBO allocated.
  mesh.ebo != 0

proc eboCapacity*(mesh: Mesh): int {.inline.} =
  ## Returns the capacity of the mesh's EBO.
  mesh.eboCap

proc eboLen*(mesh: Mesh): int {.inline.} =
  ## Returns the length of the mesh's EBO.
  mesh.fEboLen

proc primitive*(mesh: Mesh): DrawPrimitive {.inline.} =
  ## Returns what primitive the mesh is built from.
  mesh.fPrimitive

proc `primitive=`*(mesh: Mesh, newPrimitive: DrawPrimitive) {.inline.} =
  ## Changes what primitive the mesh is built from.
  mesh.fPrimitive = newPrimitive

proc vertexCount*(mesh: Mesh): int {.inline.} =
  ## Returns the total amount of vertices that can be drawn using the mesh.
  if mesh.hasEbo: mesh.eboLen
  else: mesh.vboLen

proc primitiveCount*(mesh: Mesh): int {.inline.} =
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
  mesh.window.IMPL_makeCurrent()
  mesh.gl.bindBuffer(btArray, mesh.vbo)

proc useEbo(mesh: Mesh) =
  mesh.window.IMPL_makeCurrent()
  mesh.gl.bindBuffer(btElementArray, mesh.ebo)

proc use(mesh: Mesh) =
  mesh.window.IMPL_makeCurrent()
  mesh.gl.bindVertexArray(mesh.vao)

macro vaoAttribsAux(gl: typed, T: typedesc, attrCount: typed): untyped =
  result = newStmtList()

  var index = 0

  let impl = T.getTypeImpl[1].getTypeImpl  # yay for typedesc
  for identDefs in impl[2]:
    let ty = identDefs[^2]
    for name in identDefs[0..^3]:
      result.add(quote do:
        vertexAttrib[`ty`](`gl`, `index`, sizeof(`T`), offsetof(`T`, `name`)))
      inc(index)

  result.add(newAssignment(attrCount, newLit(index)))

proc updateVao[V](mesh: Mesh[V]) =
  mesh.window.IMPL_makeCurrent()
  if mesh.vao.id != 0:
    mesh.gl.deleteVertexArray(mesh.vao)

  mesh.vao = mesh.gl.createVertexArray()
  mesh.use()

  mesh.useVbo()
  mesh.useEbo()

  var attribCount = 0
  vaoAttribsAux(mesh.gl, V, attribCount)
  for index in 0..<attribCount:  # from vaoAtrribsAux
    mesh.gl.enableVertexAttrib(index)

proc uploadVertices*[V](mesh: Mesh[V], data: openArray[V]) =
  ## Uploads vertex data to the vertex buffer of the given mesh.
  ## This operation is optimized, so if the data store can fit the given array,
  ## it is not reallocated.

  mesh.window.IMPL_makeCurrent()

  if mesh.vbo == 0:
    mesh.vbo = mesh.gl.createBuffer()
    mesh.updateVao[:V]()

  mesh.useVbo()

  let dataSize = data.len * sizeof(V)
  if mesh.vboCap < data.len:
    mesh.gl.bufferData(btArray, dataSize, data[low(data)].unsafeAddr,
                       mesh.usage)
    mesh.vboCap = data.len
  else:
    mesh.gl.bufferSubData(btArray, 0..dataSize, data[low(data)].unsafeAddr)

  mesh.fVboLen = data.len

template indexTypeToEnum(T: typedesc): IndexTypeEnum =
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

  mesh.window.IMPL_makeCurrent()

  assert mesh.vbo != 0, "vertices must be uploaded before indices"
  if mesh.ebo == 0:
    mesh.ebo = mesh.gl.createBuffer()
    mesh.eboType = indexTypeToEnum(I)
    mesh.updateVao[:V]()
  else:
    assert indexTypeToEnum(I) == mesh.eboType,
      "data type mismatch: got <" & $I & ">, " &
      "but the EBO is of type <" & $mesh.eboType & ">"

  mesh.useEbo()

  let dataSize = data.len * sizeof(I)
  if mesh.eboCap < data.len:
    mesh.gl.bufferData(btElementArray, dataSize,
                       data[low(data)].unsafeAddr, mesh.usage)
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
  assert indexTypeToEnum(I) == mesh.eboType,
    "data type mismatch: got <" & $I & ">, " &
    "but the EBO is of type <" & $mesh.eboType & ">"

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

proc instanced*[V](slice: MeshSlice[V], instanceCount: Natural): MeshSlice[V] =
  ## Returns a MeshSlice for use with instanced rendering. ``instanceCount``
  ## specifies how many instances should be rendered.
  result = slice
  result.instanceCount = some(instanceCount)

proc draw*(slice: MeshSlice, gl: OpenGl) =
  ## ``Drawable`` implementation for ``target.draw``, do not use directly.
  slice.mesh.use()
  if slice.instanceCount.isSome:
    if slice.mesh.hasEbo:
      gl.drawElementsInstanced(slice.mesh.primitive.toGlEnum,
                               slice.range.a, 1 + slice.range.b - slice.range.a,
                               slice.instanceCount.get,
                               slice.mesh.eboType.toGlEnum)
    else:
      gl.drawArraysInstanced(slice.mesh.primitive.toGlEnum,
                             slice.range.a, 1 + slice.range.b - slice.range.a,
                             slice.instanceCount.get)
  else:
    if slice.mesh.hasEbo:
      gl.drawElements(slice.mesh.primitive.toGlEnum,
                      slice.range.a, 1 + slice.range.b - slice.range.a,
                      slice.mesh.eboType.toGlEnum)
    else:
      gl.drawArrays(slice.mesh.primitive.toGlEnum,
                    slice.range.a, 1 + slice.range.b - slice.range.a)

converter allVertices*[V](mesh: Mesh[V]): MeshSlice[V] {.inline.} =
  ## Implicit converter to avoid having to use ``mesh[0..<mesh.vertexCount]``
  ## when attempting to draw something.
  assert mesh.vertexCount > 0, "cannot draw a mesh with no vertices"
  result = mesh[0..<mesh.vertexCount]

proc newMesh*[V](window: Window, usage: MeshUsage,
                 primitive: DrawPrimitive): Mesh[V] =
  ## Creates a new, empty mesh built from the given draw primitive. Set
  ## ``usage`` depending on how the mesh is going to be used, so that the
  ## driver's able to place it in a suitable area of GPU memory. See
  ## ``MeshUsage`` for details.
  window.IMPL_makeCurrent()
  let gl = window.IMPL_getGlContext()
  new(result) do (mesh: Mesh[V]):
    mesh.window.IMPL_makeCurrent()
    mesh.gl.deleteBuffer(mesh.vbo)
    if mesh.hasEbo:
      mesh.gl.deleteBuffer(mesh.ebo)
  result.window = window
  result.gl = gl
  result.usage =
    case usage
    of muStream: GL_STREAM_DRAW
    of muStatic: GL_STATIC_DRAW
    of muDynamic: GL_DYNAMIC_DRAW
  result.primitive = primitive

proc newMesh*[V](window: Window, primitive: DrawPrimitive,
                 vertices: openArray[V], usage = muStatic): Mesh[V] =
  ## Creates a new mesh pre-loaded with the given vertices.
  result = window.newMesh[:V](usage, primitive)
  result.uploadVertices(vertices)

proc newMesh*[V; I: IndexType](window: Window, primitive: DrawPrimitive,
                               vertices: openArray[V], indices: openArray[I],
                               usage = muStatic): Mesh[V] =
  ## Creates a new mesh pre-loaded with the given vertices and indices.
  result = window.newMesh[:V](usage, primitive)
  result.uploadVertices(vertices)
  result.uploadIndices(indices)
