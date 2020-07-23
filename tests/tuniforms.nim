import std/tables

import aglet

proc a() =
  var u: Table[string, Uniform]
  u["a"] = 1'i32.toUniform

  discard uniforms {
    a: 1, b: 2,
    ..u,
    ..NoUniforms,
    ..uniforms {
      cc: 123,
    },
  }
a()
