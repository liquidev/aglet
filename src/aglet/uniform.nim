## Static, efficient uniform representation.
## Uniform arrays are represented using a different enum discriminator, because
## then we don't have to allocate a seq each time.

import std/strutils
import std/sugar
import std/macros

import glm/mat
import glm/vec

proc typeNameToNode(typeName, arrayRepr: string): NimNode =
  result =
    if typeName.endsWith("Array"):
      newTree(nnkBracketExpr, ident(arrayRepr),
              typeName.dup(removeSuffix("Array")).ident)
    else:
      ident(typeName)

proc genTypeNames(dest: var seq[string]) =
  const
    Scalars = ["float32", "int32", "uint32"]
    VecSizes = ["2", "3", "4"]
    VecTypes = ["f", "i", "ui"]
    MatSizes = ["2", "3", "4", "2x3", "3x2", "2x4", "4x2", "3x4", "4x3"]
    MatTypes = ["f"]

  dest.add(Scalars)

  for size in VecSizes:
    for ty in VecTypes:
      dest.add("Vec" & size & ty)

  for size in MatSizes:
    for ty in MatTypes:
      dest.add("Mat" & size & ty)

  block:
    # this block is here to make the ``arrays`` variable have as short of a
    # lifetime as possible
    var arrays: seq[string]
    for ty in dest:
      arrays.add(ty & "Array")
    dest.add(arrays)

proc addUniformTypeEnum(typesec: var NimNode, typeList: seq[string]) =
  var enumDef = newTree(nnkEnumTy, newEmptyNode())
  for ty in typeList:
    let base = "ut" & ty.capitalizeAscii
    enumDef.add(ident(base))

  typesec.add(newTree(nnkTypeDef,
                      newTree(nnkPostfix, ident"*", ident"UniformType"),
                      newEmptyNode(),
                      enumDef))

proc addUniformObject(typesec: var NimNode, typeList: seq[string]) =
  var
    objDef = newTree(nnkObjectTy, newEmptyNode(), newEmptyNode())
    recList = newNimNode(nnkRecList)
    cases = newTree(nnkRecCase,
                    newTree(nnkIdentDefs,
                            newTree(nnkPostfix, ident"*", ident"ty"),
                            ident"UniformType",
                            newEmptyNode()))

  for typeName in typeList:
    let
      enumName = "ut" & typeName.capitalizeAscii
      fieldName = "val" & typeName.capitalizeAscii
      ty = typeNameToNode(typeName, "seq")
    cases.add(newTree(nnkOfBranch, ident(enumName),
                      newTree(nnkIdentDefs,
                              newTree(nnkPostfix, ident"*", ident(fieldName)),
                              ty, newEmptyNode())))

  recList.add(cases)
  objDef.add(recList)
  typesec.add(newTree(nnkTypeDef,
                      newTree(nnkPostfix, ident"*", ident"Uniform"),
                      newEmptyNode(),
                      objDef))

proc addConverters(stmts: var NimNode, typeList: seq[string]) =
  for typeName in typeList:
    var
      argType = typeNameToNode(typeName, "openArray")
      procDef = newProc(newTree(nnkPostfix, ident"*", ident"toUniform"),
                        params = @[
                          ident"Uniform",
                          newTree(nnkIdentDefs, ident"val", argType,
                                  newEmptyNode())
                        ])
      val =
        if typeName.endsWith("Array"):
          newTree(nnkPrefix, ident"@", ident"val")
        else:
          ident"val"
    procDef.body =
      newTree(nnkObjConstr, ident"Uniform",
              newColonExpr(ident"ty", ident("ut" & typeName.capitalizeAscii)),
              newColonExpr(ident("val" & typeName.capitalizeAscii), val))
    stmts.add(procDef)

macro genUniforms() =
  result = newStmtList()

  var
    typesec = newTree(nnkTypeSection)
    types: seq[string]

  genTypeNames(types)

  addUniformTypeEnum(typesec, types)
  addUniformObject(typesec, types)
  result.add(typesec)

  addConverters(result, types)

genUniforms()
