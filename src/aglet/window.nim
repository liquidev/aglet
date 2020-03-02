import glm/vec

import input
import state

type
  AgletWindow = ref object of AgletSubmodule ## the window submodule's state
    current: Window
  WindowHints* = object ## \
    ## Window hints. For most hints, if a backend does not support them, they
    ## should be ignored.
    resizable*, visible*, decorated*, focused*, floating*, maximized*,
      transparent*, scaleToDpi*: bool
    colorBits*: tuple[red, green, blue, alpha: int]
    depthBits*, stencilBits*: int
    stereoscopic*: bool
    msaaSamples*: int
    glVersion*: tuple[major, minor: int]
    debugContext*: bool
  Window* = ref object of RootObj
    agl*: Aglet

    # events
    pollEventsImpl*: proc (win: Window, processEvent: InputProc) ## \
      ## Polls for incoming events and passes each one to ``processEvent``
    waitEventsImpl*: proc (win: Window, processEvent: InputProc,
                           timeout: float) ## \
      ## Waits for incoming events and passes each one to ``processEvent`` \
      ## Stops waiting after the given timeout if it's not -1
    pollMouseImpl*: proc (win: Window): Vec2[float] ## \
      ## Polls the OS for the mouse cursor's position

    # context
    makeCurrentImpl*: proc (win: Window) ## \
      ## Makes the window's GL context current
    setSwapIntervalImpl*: proc (win: Window, interval: int) ## \
      ## Sets the buffer swap interval (VSync). 0 means no VSync, 1 is the \
      ## monitor's refresh rate, 2 is half the monitor's refresh rate, etc.
    swapBuffersImpl*: proc (win: Window) ## \
      ## Swaps the window's front and back buffers

    # window
    requestCloseImpl*: proc (win: Window) ## \
      ## Requests that the window gets closed. This should set a "close \
      ## requested" bit in the window
    closeRequestedImpl*: proc (win: Window): bool ## \
      ## Returns the "close requested" bit

    keyStates: array[low(Key).int..high(Key).int, bool]
    mousePos: Vec2[float]

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

proc interceptEvents(win: Window, userCallback: InputProc): InputProc =
  ## Wrap the user callback in some special stuff aglet needs to do for key
  ## polling etc. to work.
  result = proc (ev: InputEvent) =
    if ev.kind in {iekKeyPress, iekKeyRelease}:
      win.keyStates[ev.key.int] = ev.kind == iekKeyPress

    userCallback(ev)

    if ev.kind == iekMouseMove:
      win.mousePos = ev.mousePos

proc pollEvents*(win: Window, processEvent: InputProc) =
  ## Poll for incoming events from the given window. ``processEvent`` will be
  ## called for each incoming event.
  win.pollEventsImpl(win, win.interceptEvents(processEvent))

proc waitEvents*(win: Window, processEvent: InputProc,
                 timeout = -1.0) =
  ## Wait for incoming events from the given window. ``processEvent`` will be
  ## called for each incoming event. If ``timeout`` is specified, the procedure
  ## will only wait for the specified amount of seconds, and then continue
  ## execution.
  win.waitEventsImpl(win, win.interceptEvents(processEvent), timeout)

proc requestClose*(win: Window) =
  ## Requests that the window gets closed. This may not *actually* close the
  ## window, it only sets a bit in the window's state, and the application
  ## determines whether the window actually closes.
  win.requestCloseImpl(win)

proc closeRequested*(win: Window): bool =
  ## Returns whether a window close request has been made.
  result = win.closeRequestedImpl(win)

proc makeCurrent*(win: Window) =
  ## **Do not use this.**
  ## Makes a window's context current. You should not use this in normal code.
  ## This is left as part of the public API, but it's an implementation detail
  ## left in because of global state.

  # avoid unnecessary state changes
  if win.agl.window.AgletWindow.current != win:
    win.agl.window.AgletWindow.current = win
    win.makeCurrentImpl(win)

proc `swapInterval=`*(win: Window, interval: int) =
  ## Sets the window's buffer swap interval.
  ## The swap interval controls whether VSync should be used. A value of 0
  ## disables VSync, a value of 1 enables VSync at the monitor's refresh rate,
  ## and any values higher than that enable VSync at the monitor's refresh rate
  ## divided by the interval.
  win.setSwapIntervalImpl(win, interval)

proc key*(win: Window, key: Key): bool =
  ## Returns the pressed state of the given key. ``true`` is pressed.
  result = win.keyStates[key.int]

proc mouse*(win: Window): Vec2[float] =
  ## Returns the current position of the mouse cursor in the window.
  ## This may be used in an input event handler to query the last mouse
  ## position.
  ##
  ## If the window is not focused, it returns the last position of the cursor
  ## when the window *was* focused. If you need the mouse position when the
  ## window is not focused, consider using the (slower) ``pollMouse``.
  result = win.mousePos

proc pollMouse*(win: Window): Vec2[float] =
  ## Polls the OS for the mouse cursor's position. Unlike ``mouse``, this works
  ## returns the current position regardless of the window's focus.
  result = win.pollMouseImpl(win)

proc initWindow*(agl: var Aglet) =
  ## Initializes the windowing submodule. You should call this before doing
  ## anything with windows.
  agl.window = AgletWindow(current: nil)
