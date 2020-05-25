## Various utilities for dealing with common use cases.

import std/macros
import std/tables

import texture
import uniform

type
  EmptyUniforms* = object  ## \
    ## special type that represents an empty uniform table
  
  SomeTable*[K, V] = Table[K, V] | TableRef[K, V]

const NoUniforms* = EmptyUniforms()

proc isValidUniformName(name: NimNode): bool =
  result =
    name.kind == nnkIdent or
    name.kind == nnkPrefix and name[0] == ident"?" and name[1].kind == nnkIdent

macro uniforms*(pairs: untyped): untyped =
  ## Helper macro that transforms a table constructor to a
  ## ``UniformSource``-compatible tuple. This macro is mainly useful to avoid
  ## repetitive noise by ``toUniform``, and not have to worry about remembering
  ## to add ``.toUniform`` to the end of your value.

  runnableExamples:
    let
      a = uniforms {
        constant: 10.0,
        offsetPerInstance: vec2f(2.0, 0.0),
      }
      b = (
        constant: 10'f32.toUniform,
        offsetPerInstance: vec2f(2.0, 0.0).toUniform,
      )
    assert a == b

  if pairs.kind != nnkTableConstr:
    error("table constructor expected", pairs)
  if pairs.len == 0:
    return bindSym"NoUniforms"
  result = newPar()
  for pair in pairs:
    if pair.kind != nnkExprColonExpr:
      error("uniform pair 'a: b' expected", pair)
    var
      key = pair[0]
      value = pair[1]
    if not key.isValidUniformName:
      error("invalid uniform name: '" & key.repr & "'", key)
    if key.kind == nnkPrefix:
      key = ident('?' & key[1].strVal)
    result.add(newColonExpr(key, newCall(bindSym"toUniform", value)))

iterator getUniforms*(none: EmptyUniforms): (string, Uniform) =
  ## Yields no uniforms. This is preferred instead of ``uniforms {:}``.

iterator getUniforms*(rec: tuple | object): (string, Uniform) =
  ## Built-in helper iterator for the ``uniforms`` macro. This also allows for
  ## user-defined object types to be used as ``UniformSource``s.
  for key, value in fieldPairs(rec):
    assert value is Uniform, "all fields must be Uniforms"
    yield (key, value)

iterator getUniforms*(table: SomeTable[string, Uniform]): (string, Uniform) =
  ## Built-in helper for ``Table``s containing ``Uniform``s.
  for key, value in table:
    yield (key, value)
