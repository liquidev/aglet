## Abstract interface for things that can be drawn onto the screen.

import gl

type
  Drawable* = object of RootObj
    drawImpl*: proc (drawable: Drawable, gl: OpenGl) {.nimcall.}

proc draw*(drawable: Drawable, gl: OpenGl) =
  drawable.drawImpl(drawable, gl)
