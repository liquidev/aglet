## Pixel buffer objects, used internally for async download operations.

import enums
import gl
import window

type
  PixelBuffer* = ref object
    win: Window
    gl: OpenGl
    id: GlUint
    size*: Natural  ## the data store's size in bytes
    data*: pointer  ## the data store mapped to process memory

template use*(buffer: PixelBuffer, body: untyped): untyped =
  ## Use the pixel buffer for the lifetime of the block.
  ## This is implemented differently from the other modules, because pixel
  ## buffers should always be unbound after you're finished with them.
  ## Otherwise it might mess up synchronous pixel read operations.

  buffer.win.IMPL_makeCurrent()
  buffer.gl.bindBuffer(btPixelPack, buffer.id)
  body
  buffer.gl.bindBuffer(btPixelPack, 0)

proc map*(buffer: PixelBuffer, access: AccessMode) =
  ## Maps the pixel buffer to the process's virtual memory and sets the ``data``
  ## field to a pointer to its first element.
  ## This field can then be cast to `ptr UncheckedArray[T]``, where T is your
  ## pixel type.

  buffer.use:
    buffer.data = buffer.gl.mapBuffer(btPixelPack, access.toGlEnum)

proc unmap*(buffer: PixelBuffer) =
  ## Unmaps the pixel buffer's data store from virtual memory.

  if buffer.data != nil:
    buffer.use:
      buffer.gl.unmapBuffer(btPixelPack)
    buffer.data = nil

proc ensureSize*(buffer: PixelBuffer, size: Natural) =
  ## Ensures that the pixel buffer has the given amount of bytes of storage.
  ## This unmaps the data store from virtual memory if the size does not match,
  ## so be careful!

  if buffer.size != size:
    buffer.use:
      # I'm not sure about the usage of GL_DYNAMIC_READ here, a different usage
      # hint may be better depending on the pixel buffer is used but
      # GL_DYNAMIC_READ is generic enough especially because we're reusing the
      # same buffer when the requested size is always the same.
      buffer.gl.bufferData(btPixelPack, size, nil, GL_DYNAMIC_READ)
    buffer.size = size
    buffer.data = nil  # glBufferData invalidates any maps

proc newPixelBuffer*(window: Window): PixelBuffer =
  ## Creates a new pixel buffer with no storage. ``ensureSize`` must be then
  ## used to allocate storage space for the buffer.

  new(result) do (buffer: PixelBuffer):
    buffer.gl.deleteBuffer(buffer.id)
  let gl = window.IMPL_getGlContext()
  result.win = window
  result.gl = gl
  result.id = gl.createBuffer()
