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
  ## Empty uniforms constant. This is preferred over ``uniforms {:}``
  ## (which is transformed to ``NoUniforms`` anyways).

proc isValidUniformName(name: NimNode): bool =
  result =
    name.kind == nnkIdent or
    name.kind == nnkPrefix and name[0] == ident"?" and name[1].kind == nnkIdent

macro uniforms*(uniforms: untyped): untyped =
  ## Helper macro that transforms a table constructor to a
  ## ``UniformSource``-compatible tuple. This macro is mainly useful for
  ## readability and rapid prototyping via the features described below.
  ##
  ## This macro supports a special syntax for optional uniforms. Normally, when
  ## a uniform is not used in a shader, an error is thrown. This can be
  ## suppressed by prefixing the uniform name with a ``?``, eg. ``?offset``.
  ## The same trick works with uniform Tables.
  ##
  ## Additionally, to allow libraries to add their own sets of uniforms, it is
  ## possible to use ``..`` as a prefix operator in the constructor's body.
  ## The operand must be a value that can be iterated with ``getUniforms``.
  ## The uniforms returned by this value are simply included in the final
  ## uniforms passed to ``draw``, as defined by the ``getUniforms`` iterator for
  ## records.

  runnableExamples:
    import aglet/uniform
    import glm/vec

    type
      Expansion = tuple
        extra: int
    proc myExpansion: Expansion = (extra: 42)

    let
      a = uniforms {
        ?constant: 10.0,
        offsetPerInstance: vec2f(2.0, 0.0),
        ..myExpansion(),
      }
      b = (
        # this does not compile due to a bug in the compiler (Nim/#14911)
        # `?constant`: 10'f32,
        offsetPerInstance: vec2f(2.0, 0.0),
        # `..0`: myExpansion(),
      )

    # assert a == b

  var expansionCount: int

  if uniforms.kind notin {nnkCurly, nnkTableConstr}:
    error("table constructor expected", uniforms)

  if uniforms.len == 0:
    result = bindSym"NoUniforms"
  else:
    result = newPar()
    for decl in uniforms:
      if decl.kind == nnkExprColonExpr:
        var
          key = decl[0]
          value = decl[1]
        if not key.isValidUniformName:
          error("invalid uniform name: '" & key.repr & "'", key)
        if key.kind == nnkPrefix:
          key = ident('?' & key[1].strVal)
        result.add(newColonExpr(key, value))
      elif decl.kind == nnkPrefix:
        decl[0].expectIdent("..")
        let key = ident(".." & $expansionCount)
        inc(expansionCount)
        result.add(newColonExpr(key, decl[1]))
      else:
        error("uniform 'name: value' or expansion '..expansion' expected", decl)

iterator getUniforms*(none: EmptyUniforms): (string, Uniform) =
  ## Yields no uniforms.

iterator getUniforms*(table: SomeTable[string, Uniform]): (string, Uniform) =
  ## Built-in helper for Tables containing Uniforms.
  for key, value in table:
    yield (key, value)

iterator getUniforms*(rec: tuple | object): (string, Uniform) =
  ## Built-in helper iterator for the ``uniforms`` macro. This also allows for
  ## user-defined object types to be used as UniformSources.
  ## Every field in the record must be convertable to a uniform using
  ## ``toUniform``.
  ##
  ## If a field's name begins with `..` (which is normally only possible through
  ## the use of macros), the field is iterated using ``getUniforms``.
  ## This process happens recursively for any field whose name begins with `..`.

  template expand(rec) =
    for key, value in fieldPairs(rec):
      when key.len >= 2 and key[0..1] == "..":
        expand(value)
      else:
        yield (key, value.toUniform)

  expand(rec)
