## Generic axis-aligned rectangle type.

import glm/vec

type
  Rect*[T] = object
    position*: Vec2[T]
    size*: Vec2[T]
  Recti* = Rect[int32]
  Rectf* = Rect[float32]

func x*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the X position of the rectangle.
  rect.position.x

func y*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the Y position of the rectangle.
  rect.position.y

func width*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the width of the rectangle.
  rect.size.x

func height*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the height of the rectangle.
  rect.size.y

func left*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the left boundary of the rectangle.
  rect.x

func right*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the right boundary of the rectangle.
  rect.x + rect.width

func top*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the top boundary of the rectangle.
  rect.y

func bottom*[T](rect: Rect[T]): T {.inline.} =
  ## Returns the bottom boundary of the rectangle.
  rect.y + rect.height

func rect*[T](position: Vec2[T], size: Vec2[T]): Rect[T] {.inline.} =
  ## Creates a rectangle with the given position and size.
  Rect[T](position: position, size: size)

func rect*[T](x, y, width, height: T): Rect[T] {.inline.} =
  ## Creates a rectangle with the given X and Y coordinates, width, and height.
  rect(vec2(x, y), vec2(width, height))

template alias(T, suffix, doc1, doc2) {.inject.} =

  func `rect suffix`*(position, size: Vec2[T]): Rect[T] {.inline.} =
    doc1
    rect[T](position, size)

  func `rect suffix`*(x, y, width, height: T): Rect[T] {.inline.} =
    doc2
    rect[T](x, y, width, height)

alias float32, f:
  ## Creates a float32 rectangle with the given position and size.
do:
  ## Creates a float32 rectangle with the given X and Y coordinates,
  ## width, and height.

alias int32, i:
  ## Creates an int32 rectangle with the given position and size.
do:
  ## Creates an int32 rectangle with the given X and Y coordinates,
  ## width, and height.
