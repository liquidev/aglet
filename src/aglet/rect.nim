## Generic axis-aligned rectangle type.

import glm/vec

type
  Rect*[T] = object
    position*: Vec2[T]
    size*: Vec2[T]
  Recti* = Rect[int32]
  Rectf* = Rect[float32]

func x*[T](rect: Rect[T]): T = rect.position.x
func y*[T](rect: Rect[T]): T = rect.position.y

func width*[T](rect: Rect[T]): T = rect.size.x
func height*[T](rect: Rect[T]): T = rect.size.y

func left*[T](rect: Rect[T]): T = rect.x
func right*[T](rect: Rect[T]): T = rect.x + rect.width
func top*[T](rect: Rect[T]): T = rect.y
func bottom*[T](rect: Rect[T]): T = rect.y + rect.height

func rect*[T](position: Vec2[T], size: Vec2[T]): Rect[T] =
  Rect[T](position: position, size: size)

func rect*[T](x, y, width, height: T): Rect[T] =
  rect(vec2(x, y), vec2(width, height))

template alias(T, suffix) =
  func `rect suffix`*(x, y, width, height: T): Rect[T] =
    rect[T](x, y, width, height)

alias float32, f
alias int32, i
