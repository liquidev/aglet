## Abstract window interface. This is implemented by the different backends,
## which can be found under ``aglet/window/*``.
##
## This module contains some leaked implementation details; these are prefixed
## with ``IMPL_`` and should not be used by user code. The "prelude" file
## ``import aglet`` omits these procs.

import glm/vec

import gl
import input
import state
import target

type
  AgletWindow = ref object of AgletSubmodule ## the window submodule's state
    current: Window

  WindowHints* = object ## \
    ## window hints. For most hints, if a backend does not support them, they
    ## should be ignored
    resizable*, visible*, decorated*, focused*, floating*, maximized*,
      transparent*, scaleToDpi*: bool
    colorBits*: tuple[red, green, blue, alpha: int]
    depthBits*, stencilBits*: int
    stereoscopic*: bool
    msaaSamples*: int
    glVersion*: tuple[major, minor: int]
    debugContext*: bool

  Window* = ref object of RootObj
    ## A backend-independent window. This also contains the OpenGL context, so
    ## resource allocation is done using this handle.

    agl*: Aglet

    # events
    pollEventsImpl*: proc (win: Window, processEvent: InputProc)
      ## polls for incoming events and passes each one to ``processEvent``
    waitEventsImpl*: proc (win: Window, processEvent: InputProc,
                           timeout: float)
      ## waits for incoming events and passes each one to ``processEvent``
      ## stops waiting after the given timeout if it's not -1
    pollMouseImpl*: proc (win: Window): Vec2f
      ## polls the OS for the mouse cursor's position

    # context
    makeCurrentImpl*: proc (win: Window)
      ## makes the window's GL context current
    getProcAddrImpl*: proc (name: string): pointer
      ## returns an OpenGL procedure's address
    setSwapIntervalImpl*: proc (win: Window, interval: int)
      ## sets the buffer swap interval (vsync). 0 means no vsync, 1 is the
      ## monitor's refresh rate, 2 is half the monitor's refresh rate, etc.
    swapBuffersImpl*: proc (win: Window)
      ## swaps the window's front and back buffers

    # window
    setCloseRequestedImpl*: proc (win: Window, close: bool)
      ## requests that the window gets closed. This should set or unset a "close
      ## requested" bit in the window
    closeRequestedImpl*: proc (win: Window): bool
      ## returns the "close requested" bit

    # properties
    getSizeImpl*: proc (win: Window, w, h: var int)
      ## stores the window's dimensions in w and h
    setSizeImpl*: proc (win: Window, w, h: int)
      ## sets the window's dimensions from w and h
    getFramebufferSize*: proc (win: Window, w, h: var int)
      ## gets the window's framebuffer size
    getContentScale*: proc (win: Window, x, y: float)
      ## gets the content scale of the window (for hi-dpi support)
    setSizeLimits*: proc (win: Window, xmin, ymin, xmax, ymax: int)
    setTitleImpl*: proc (win: Window, newTitle: string)
      ## sets the window title

    keyStates: array[low(Key).int..high(Key).int, bool]
    mousePos: Vec2f
    title: string

    gl: OpenGl

  Frame* = object of Target
    window: Window
    finished: bool

proc winHints*(resizable = true, visible = true, decorated = true,
               focused = true, floating = false, maximized = false,
               transparent = false, scaleToDpi = false,
               colorBits = (red: 8, green: 8, blue: 8, alpha: 8),
               depthBits = 24, stencilBits = 8,
               stereoscopic = false,
               msaaSamples = 0,
               glVersion = (major: 3, minor: 3),
               debugContext = not defined(release)): WindowHints =
  ## Constructs a WindowHints with sensible defaults:
  ##
  ## - resizable: true
  ## - visible: true
  ## - decorated: true
  ## - focused: true
  ## - floating: false
  ## - maximized: false
  ## - transparent: false
  ## - scale to DPI: flase
  ## - color bits: (red: 8, green: 8, blue: 8, alpha: 8)
  ## - depth bits: 24
  ## - stencil bits: 8
  ## - stereoscopic: false
  ## - MSAA samples: 0
  ## - GL version: 3.3
  ## - debug context: when -d:release is not defined
  result = WindowHints(resizable: resizable, visible: visible,
                       decorated: decorated, focused: focused,
                       floating: floating, maximized: maximized,
                       transparent: transparent, scaleToDpi: scaleToDpi,
                       colorBits: colorBits, depthBits: depthBits,
                       stencilBits: stencilBits, stereoscopic: stereoscopic,
                       msaaSamples: msaaSamples, glVersion: glVersion,
                       debugContext: debugContext)

const DefaultWindowHints* = winHints()

proc interceptEvents(window: Window, userCallback: InputProc): InputProc =
  ## Wrap the user callback in some special stuff aglet needs to do for key
  ## polling etc. to work.
  result = proc (ev: InputEvent) =
    if ev.kind in {iekKeyPress, iekKeyRelease}:
      window.keyStates[ev.key.int] = ev.kind == iekKeyPress

    userCallback(ev)

    if ev.kind == iekMouseMove:
      window.mousePos = ev.mousePos

proc pollEvents*(window: Window, processEvent: InputProc) =
  ## Poll for incoming events from the given window. ``processEvent`` will be
  ## called for each incoming event.
  window.pollEventsImpl(window, window.interceptEvents(processEvent))

proc waitEvents*(window: Window, processEvent: InputProc,
                 timeout = -1.0) =
  ## Wait for incoming events from the given window. ``processEvent`` will be
  ## called for each incoming event. If ``timeout`` is specified, the procedure
  ## will only wait for the specified amount of seconds, and then continue
  ## execution.
  window.waitEventsImpl(window, window.interceptEvents(processEvent), timeout)

proc requestClose*(window: Window) =
  ## Requests that the window gets closed. This may not *actually* close the
  ## window, it only sets a bit in the window's state, and the application
  ## determines whether the window actually closes.
  window.setCloseRequestedImpl(window, true)

proc rejectClose*(window: Window) =
  ## Resets the close request bit.
  window.setCloseRequestedImpl(window, false)

proc closeRequested*(window: Window): bool =
  ## Returns whether a window close request has been made.
  result = window.closeRequestedImpl(window)

proc `swapInterval=`*(window: Window, interval: int) =
  ## Sets the window's buffer swap interval.
  ## The swap interval controls whether VSync should be used. A value of 0
  ## disables VSync, a value of 1 enables VSync at the monitor's refresh rate,
  ## and any values higher than that enable VSync at the monitor's refresh rate
  ## divided by the interval.
  window.setSwapIntervalImpl(window, interval)

proc key*(window: Window, key: Key): bool =
  ## Returns the pressed state of the given key. ``true`` is pressed.
  result = window.keyStates[key.int]

proc mouse*(window: Window): Vec2f =
  ## Returns the current position of the mouse cursor in the window.
  ## This may be used in an input event handler to query the last mouse
  ## position.
  ##
  ## If the window is not focused, it returns the last position of the cursor
  ## when the window *was* focused. If you need the mouse position when the
  ## window is not focused, consider using the (slower) ``pollMouse``.
  result = window.mousePos

proc pollMouse*(window: Window): Vec2f =
  ## Polls the OS for the mouse cursor's position. Unlike ``mouse``, this works
  ## returns the current position regardless of the window's focus.
  result = window.pollMouseImpl(window)

proc size*(window: Window): Vec2i =
  ## Returns the current size of the window as a vector.
  var x, y: int
  window.getSizeImpl(window, x, y)
  result = vec2i(x.int32, y.int32)

proc width*(window: Window): int =
  ## Returns the current width of the window.
  result = window.size.x

proc height*(window: Window): int =
  ## Returns the current height of the window.
  result = window.size.y

proc title*(window: Window): string =
  ## Returns the title of the window.
  window.title

proc `title=`*(window: Window, newTitle: string) =
  ## Sets the title of the window.
  window.title = newTitle
  window.setTitleImpl(window, newTitle)

proc IMPL_makeCurrent*(window: Window) =
  ## **Do not use this.**
  ## Makes a window's context current. You should not use this in normal code.
  ## This is left as part of the public API, but it's an implementation detail
  ## left in because of global state.

  # avoid unnecessary state changes
  if window.agl.window.AgletWindow.current != window:
    window.agl.window.AgletWindow.current = window
    window.makeCurrentImpl(window)

proc render*(window: Window): Frame =
  ## Starts rendering a single frame of animation.
  ## Only one frame may be rendered at a time. After rendering the frame, use
  ## ``finish`` to stop rendering to the frame.

  result = Frame(gl: window.gl, window: window, finished: false)

  result.useImpl = proc (target: Target, gl: OpenGl) {.nimcall.} =
    assert not target.Frame.finished,
      "cannot render to a frame that's already been finished"
    let window = target.Frame.window
    window.IMPL_makeCurrent()
    gl.bindFramebuffer({ftRead, ftDraw}, 0)
    gl.viewport(0, 0, window.width.GlSizei, window.height.GlSizei)

proc finish*(frame: Frame) =
  ## Finishes a frame blitting it onto the screen.
  frame.window.swapBuffersImpl(frame.window)

proc glVersion*(window: Window): string =
  ## Returns a string containing the version of OpenGL as reported by the
  ## driver.
  result = window.gl.version

proc initWindow*(agl: var Aglet) =
  ## Initializes the windowing submodule. You should call this before doing
  ## anything with windows.
  agl.window = AgletWindow()

proc IMPL_loadGl*(win: Window) =
  ## **Do not use this.**
  ## Initializes the OpenGL context. This is called internally by
  ## backend-specific constructors.
  win.gl = newGl()
  win.gl.load(win.getProcAddrImpl)

proc IMPL_getGlContext*(win: Window): OpenGl =
  ## **Do not use this.**
  ## Returns the raw OpenGL context for use in internal code.
  result = win.gl
