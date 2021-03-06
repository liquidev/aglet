## One Module To Rule Them All; imports everything the user should use and
## exports it without the ``IMPL_`` cruft.
## Refer to the documentation of individual modules for more information:
##
## - ``state`` – aglet submodule initialization
## - ``mesh`` – vertex and element buffer management
## - ``program`` – shader program creation
## - ``uniform`` – dynamic GLSL uniform wrapper type
## - ``target`` – generic surface for drawing
## - ``pixeltypes`` – pixel storage types
## - ``texture`` – textures
## - ``framebuffer`` – framebuffer and renderbuffer objects
## - ``drawparams`` – drawing parameters and OpenGL features
## - ``window`` – abstract window interface
## - ``input`` – input events
## - ``util`` – various utilities like the ``uniforms`` macro
##
## In addition to this, you'll need to import a context creation backend:
##
## - ``window/glfw`` – cross-platform context management using GLFW3
##
## As an added bonus, aglet also exports the common ``vec``, ``mat``, and
## ``mat_transform`` modules from nim-glm.

import glm/mat
import glm/mat_transform
import glm/vec

import aglet/[
  drawparams,
  framebuffer,
  input,
  mesh,
  pixeltypes,
  program,
  rect,
  state,
  target,
  texture,
  uniform,
  util,
  window,
]

export drawparams except IMPL_apply
export framebuffer
export input
export mesh except IMPL_draw
export pixeltypes except internalFormat, dataType
export program except IMPL_use, IMPL_setUniform
export rect
export state
export target
export texture except internalFormat, dataType
export uniform
export util
export window except IMPL_makeCurrent, IMPL_loadGl, IMPL_getGlContext

export mat
export mat_transform
export vec
