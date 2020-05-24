## One Module To Rule Them All; imports everything the user should use and
## exports it without the ``IMPL_`` cruft.
## Refer to the documentation of individual modules for more information:
##
## - ``state`` – aglet submodule initialization
## - ``mesh`` – vertex and element buffer management
## - ``program`` – shader program creation
## - ``uniform`` – dynamic GLSL uniform wrapper type
## - ``target`` – generic surface for drawing
## - ``window`` – abstract window interface
## - ``input`` – input events
##
## In addition to this, you'll need to import a context creation backend:
##
## - ``window/glfw`` – cross-platform context management using GLFW3

import glm/mat
import glm/vec

import aglet/[
  input,
  mesh,
  program,
  state,
  target,
  texture,
  uniform,
  util,
  window,
]

export input
export mesh except IMPL_draw
export program except IMPL_use, IMPL_setUniform
export state
export target
export texture
export uniform
export util
export window except IMPL_makeCurrent, IMPL_loadGl, IMPL_getGlContext

export mat
export vec
