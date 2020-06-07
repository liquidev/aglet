# aglet

A safe, high-level core OpenGL 3.3+ context manager and wrapper for Nim.

## Features

### No state machine

OpenGL is a mess—it's a giant state machine, and it's hard to keep track of its
current state. Modern programming languages are more suited towards using
objects for resource allocation and managenent, and that's what aglet strives to
provide.
aglet uses Nim's type system to ensure OpenGL type safety. When you get a
`Texture2D` object, you can be sure it's a 2D texture. It's not of a vague
`GLuint` that does not really describe anything.
Apart from that, you don't have to worry about keeping track of all this
state—aglet does all the bookkeeping for you, and even avoids unnecessary API
calls via some simple and cheap `if` statements.

The main goal is to provide a safe API around the core GL API, which is made
primarily for C. aglet embraces Nim's features like concepts to make the wrapper
generic and extendable. Forget having to deal with pointers and other unsafe
features—aglet abstracts that away by using safe containers, like `openArray`s.
Forget all the state management—aglet abstracts it away via safe, stateless
objects that make your code much easier to maintain. What your code reads is
really what it does—you don't have to scan your codebase to find out which
texture is currently bound.

### No global variables

Forget about GLAD's global variables—aglet is fully safe for dynamic loading via
the `std/dynlib` module. All loaded OpenGL procs are stored in the abstract
`Window` class.

### Fast `check` times

Import the context backend once, and don't think about it ever since. The
abstract codebase is lightweight and does not use any Nimterop wrappers, which
are known to slow down `nim check`, which is used by many editor extensions
(most notably the Visual Studio Code extension).
At some point aglet will remove its GLFW dependency completely, but that's what
it uses for now to help develop core features quicker.

### Short, generic code

Code written using aglet is much shorter than the equivalent code written in
libraries imported from C. It abstracts all the verbosity away to keep your
codebase small and concise.

### It's free

aglet is and will always be free. It's licensed under the MIT license, so you're
free to use it in commercial projects.

## Examples

You can find code examples in the `tests/` directory.

## Roadmap

- [x] Context management
  - [x] via GLFW
  - [ ] pure Nim implementation
- [x] Generic render target
  - [x] `DrawParams` object as a replacement for the state machine
- [x] Vertex buffers (`Mesh`)
  - [x] Vertex buffer
  - [x] Element (index) buffer
  - [x] Buffer slicing
  - [ ] Instancing
- [x] Shaders and programs
- [ ] Textures
  - Types
    - [x] 1D, 2D, 3D
    - [ ] 1D array, 2D array
    - [ ] Cube map
  - Features
    - [x] Texture units
    - [x] Sampler objects
    - [ ] Texture swizzle mask
- [ ] Framebuffers
  - [ ] Renderbuffers
  - [ ] `SimpleFramebuffer` (one color attachment, inherits from `Texture`)
  - [ ] `MultiFramebuffer` (≥1 color attachment)

Please report any extra features you'd like to see in the Issues tab!

## Installation

**aglet is not in the Nimble package directory yet, please install manually via
the method described below.**

By adding it your dependencies:
```nim
requires "aglet >= 0.1.0"
```

Via the `nimble` command:
```
$ nimble install aglet
```

Manually:
```
$ git clone https://github.com/liquid600pgm/aglet
$ cd aglet
$ nimble install
```
