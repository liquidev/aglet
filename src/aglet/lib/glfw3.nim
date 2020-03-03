
## This is a GLFW 3.3 wrapper generated using c2nim.

import os

import nimterop/build
import nimterop/cimport

const
  Repo = getProjectCacheDir("aglet__glfw3")
  Src = Repo/"src"
  Include = Repo/"include"
  Glfw3Header = Include/"GLFW"/"glfw3.h"

static:
  gitPull(url = "https://github.com/glfw/glfw.git",
          outdir = Repo,
          plist = "src/*\ninclude/*\n",
          checkout = "3.3")
  # override default mappings, aglet uses its own set parsed at compile time
  # to prevent long, annoying loading times
  writeFile(Src/"mappings.h", "const char *_glfwDefaultMappings[] = {};")

cIncludeDir(Repo)
cIncludeDir(Include)

when defined(windows):
  {.hint: "aglet/glfw: building for windows".}
  {.passC: "-D_GLFW_WIN32", passL: "-lopengl32 -lgdi32".}
  cCompile(Src/"win32_*.c")
  cCompile(Src/"wgl_context.c")
  cCompile(Src/"egl_context.c")
  cCompile(Src/"osmesa_context.c")
elif defined(macosx):
  {.hint: "aglet/glfw: building for OSX".}
  {.warning: "aglet/glfw: OSX is untested, please open an issue with your " &
             "compile results".}
  {.passC: "-D_GLFW_COCOA -D_GLFW_USE_CHDIR -D_GLFW_USE_MENUBAR -D_GLFW_USE_RETINA",
    passL: "-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo".}
  cCompile(Src/"cocoa_*.m")
  cCompile(Src/"cocoa_time.c")
  cCompile(Src/"posix_thread.c")
  cCompile(Src/"nsgl_context.m")
else:
  {.hint: "aglet/glfw: building for linux (or other unix)".}
  {.passL: "-pthread -lGL -lX11".}

  when defined(aglWayland):
    {.hint: "aglet/glfw: wayland backend is enabled".}
    {.passC: "-D_GLFW_WAYLAND".}
    cCompile(Src/"wl_*.c")
    cCompile(Src/"egl_context.c")
    cCompile(Src/"osmesa_context.c")
  when defined(aglMir):
    {.hint: "aglet/glfw: mir backend is enabled".}
    {.passC: "-D_GLFW_MIR".}
    cCompile(Src/"mir_*.c")
    cCompile(Src/"egl_context.c")
    cCompile(Src/"osmesa_context.c")
  {.passC: "-D_GLFW_X11".}
  cCompile(Src/"x11_*.c")
  cCompile(Src/"glx_context.c")
  cCompile(Src/"egl_context.c")
  cCompile(Src/"osmesa_context.c")

  cCompile(Src/"xkb_unicode.c")
  cCompile(Src/"linux_joystick.c")
  cCompile(Src/"posix_time.c")
  cCompile(Src/"posix_thread.c")

cCompile(Src/"context.c")
cCompile(Src/"init.c")
cCompile(Src/"input.c")
cCompile(Src/"monitor.c")
cCompile(Src/"vulkan.c")
cCompile(Src/"window.c")




const
  GLFW_VERSION_MAJOR* = 3


const
  GLFW_VERSION_MINOR* = 3


const
  GLFW_VERSION_REVISION* = 0


const
  GLFW_TRUE* = 1


const
  GLFW_FALSE* = 0


const
  GLFW_RELEASE* = 0


const
  GLFW_PRESS* = 1


const
  GLFW_REPEAT* = 2


const
  GLFW_HAT_CENTERED* = 0
  GLFW_HAT_UP* = 1
  GLFW_HAT_RIGHT* = 2
  GLFW_HAT_DOWN* = 4
  GLFW_HAT_LEFT* = 8
  GLFW_HAT_RIGHT_UP* = (GLFW_HAT_RIGHT or GLFW_HAT_UP)
  GLFW_HAT_RIGHT_DOWN* = (GLFW_HAT_RIGHT or GLFW_HAT_DOWN)
  GLFW_HAT_LEFT_UP* = (GLFW_HAT_LEFT or GLFW_HAT_UP)
  GLFW_HAT_LEFT_DOWN* = (GLFW_HAT_LEFT or GLFW_HAT_DOWN)


const
  GLFW_KEY_UNKNOWN* = -1


const
  GLFW_KEY_SPACE* = 32
  GLFW_KEY_APOSTROPHE* = 39
  GLFW_KEY_COMMA* = 44
  GLFW_KEY_MINUS* = 45
  GLFW_KEY_PERIOD* = 46
  GLFW_KEY_SLASH* = 47
  GLFW_KEY_0* = 48
  GLFW_KEY_1* = 49
  GLFW_KEY_2* = 50
  GLFW_KEY_3* = 51
  GLFW_KEY_4* = 52
  GLFW_KEY_5* = 53
  GLFW_KEY_6* = 54
  GLFW_KEY_7* = 55
  GLFW_KEY_8* = 56
  GLFW_KEY_9* = 57
  GLFW_KEY_SEMICOLON* = 59
  GLFW_KEY_EQUAL* = 61
  GLFW_KEY_A* = 65
  GLFW_KEY_B* = 66
  GLFW_KEY_C* = 67
  GLFW_KEY_D* = 68
  GLFW_KEY_E* = 69
  GLFW_KEY_F* = 70
  GLFW_KEY_G* = 71
  GLFW_KEY_H* = 72
  GLFW_KEY_I* = 73
  GLFW_KEY_J* = 74
  GLFW_KEY_K* = 75
  GLFW_KEY_L* = 76
  GLFW_KEY_M* = 77
  GLFW_KEY_N* = 78
  GLFW_KEY_O* = 79
  GLFW_KEY_P* = 80
  GLFW_KEY_Q* = 81
  GLFW_KEY_R* = 82
  GLFW_KEY_S* = 83
  GLFW_KEY_T* = 84
  GLFW_KEY_U* = 85
  GLFW_KEY_V* = 86
  GLFW_KEY_W* = 87
  GLFW_KEY_X* = 88
  GLFW_KEY_Y* = 89
  GLFW_KEY_Z* = 90
  GLFW_KEY_LEFT_BRACKET* = 91
  GLFW_KEY_BACKSLASH* = 92
  GLFW_KEY_RIGHT_BRACKET* = 93
  GLFW_KEY_GRAVE_ACCENT* = 96
  GLFW_KEY_WORLD_1* = 161
  GLFW_KEY_WORLD_2* = 162


const
  GLFW_KEY_ESCAPE* = 256
  GLFW_KEY_ENTER* = 257
  GLFW_KEY_TAB* = 258
  GLFW_KEY_BACKSPACE* = 259
  GLFW_KEY_INSERT* = 260
  GLFW_KEY_DELETE* = 261
  GLFW_KEY_RIGHT* = 262
  GLFW_KEY_LEFT* = 263
  GLFW_KEY_DOWN* = 264
  GLFW_KEY_UP* = 265
  GLFW_KEY_PAGE_UP* = 266
  GLFW_KEY_PAGE_DOWN* = 267
  GLFW_KEY_HOME* = 268
  GLFW_KEY_END* = 269
  GLFW_KEY_CAPS_LOCK* = 280
  GLFW_KEY_SCROLL_LOCK* = 281
  GLFW_KEY_NUM_LOCK* = 282
  GLFW_KEY_PRINT_SCREEN* = 283
  GLFW_KEY_PAUSE* = 284
  GLFW_KEY_F1* = 290
  GLFW_KEY_F2* = 291
  GLFW_KEY_F3* = 292
  GLFW_KEY_F4* = 293
  GLFW_KEY_F5* = 294
  GLFW_KEY_F6* = 295
  GLFW_KEY_F7* = 296
  GLFW_KEY_F8* = 297
  GLFW_KEY_F9* = 298
  GLFW_KEY_F10* = 299
  GLFW_KEY_F11* = 300
  GLFW_KEY_F12* = 301
  GLFW_KEY_F13* = 302
  GLFW_KEY_F14* = 303
  GLFW_KEY_F15* = 304
  GLFW_KEY_F16* = 305
  GLFW_KEY_F17* = 306
  GLFW_KEY_F18* = 307
  GLFW_KEY_F19* = 308
  GLFW_KEY_F20* = 309
  GLFW_KEY_F21* = 310
  GLFW_KEY_F22* = 311
  GLFW_KEY_F23* = 312
  GLFW_KEY_F24* = 313
  GLFW_KEY_F25* = 314
  GLFW_KEY_KP_0* = 320
  GLFW_KEY_KP_1* = 321
  GLFW_KEY_KP_2* = 322
  GLFW_KEY_KP_3* = 323
  GLFW_KEY_KP_4* = 324
  GLFW_KEY_KP_5* = 325
  GLFW_KEY_KP_6* = 326
  GLFW_KEY_KP_7* = 327
  GLFW_KEY_KP_8* = 328
  GLFW_KEY_KP_9* = 329
  GLFW_KEY_KP_DECIMAL* = 330
  GLFW_KEY_KP_DIVIDE* = 331
  GLFW_KEY_KP_MULTIPLY* = 332
  GLFW_KEY_KP_SUBTRACT* = 333
  GLFW_KEY_KP_ADD* = 334
  GLFW_KEY_KP_ENTER* = 335
  GLFW_KEY_KP_EQUAL* = 336
  GLFW_KEY_LEFT_SHIFT* = 340
  GLFW_KEY_LEFT_CONTROL* = 341
  GLFW_KEY_LEFT_ALT* = 342
  GLFW_KEY_LEFT_SUPER* = 343
  GLFW_KEY_RIGHT_SHIFT* = 344
  GLFW_KEY_RIGHT_CONTROL* = 345
  GLFW_KEY_RIGHT_ALT* = 346
  GLFW_KEY_RIGHT_SUPER* = 347
  GLFW_KEY_MENU* = 348
  GLFW_KEY_LAST* = GLFW_KEY_MENU


const
  GLFW_MOD_SHIFT* = 0x00000001


const
  GLFW_MOD_CONTROL* = 0x00000002


const
  GLFW_MOD_ALT* = 0x00000004


const
  GLFW_MOD_SUPER* = 0x00000008


const
  GLFW_MOD_CAPS_LOCK* = 0x00000010


const
  GLFW_MOD_NUM_LOCK* = 0x00000020


const
  GLFW_MOUSE_BUTTON_1* = 0
  GLFW_MOUSE_BUTTON_2* = 1
  GLFW_MOUSE_BUTTON_3* = 2
  GLFW_MOUSE_BUTTON_4* = 3
  GLFW_MOUSE_BUTTON_5* = 4
  GLFW_MOUSE_BUTTON_6* = 5
  GLFW_MOUSE_BUTTON_7* = 6
  GLFW_MOUSE_BUTTON_8* = 7
  GLFW_MOUSE_BUTTON_LAST* = GLFW_MOUSE_BUTTON_8
  GLFW_MOUSE_BUTTON_LEFT* = GLFW_MOUSE_BUTTON_1
  GLFW_MOUSE_BUTTON_RIGHT* = GLFW_MOUSE_BUTTON_2
  GLFW_MOUSE_BUTTON_MIDDLE* = GLFW_MOUSE_BUTTON_3


const
  GLFW_JOYSTICK_1* = 0
  GLFW_JOYSTICK_2* = 1
  GLFW_JOYSTICK_3* = 2
  GLFW_JOYSTICK_4* = 3
  GLFW_JOYSTICK_5* = 4
  GLFW_JOYSTICK_6* = 5
  GLFW_JOYSTICK_7* = 6
  GLFW_JOYSTICK_8* = 7
  GLFW_JOYSTICK_9* = 8
  GLFW_JOYSTICK_10* = 9
  GLFW_JOYSTICK_11* = 10
  GLFW_JOYSTICK_12* = 11
  GLFW_JOYSTICK_13* = 12
  GLFW_JOYSTICK_14* = 13
  GLFW_JOYSTICK_15* = 14
  GLFW_JOYSTICK_16* = 15
  GLFW_JOYSTICK_LAST* = GLFW_JOYSTICK_16


const
  GLFW_GAMEPAD_BUTTON_A* = 0
  GLFW_GAMEPAD_BUTTON_B* = 1
  GLFW_GAMEPAD_BUTTON_X* = 2
  GLFW_GAMEPAD_BUTTON_Y* = 3
  GLFW_GAMEPAD_BUTTON_LEFT_BUMPER* = 4
  GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER* = 5
  GLFW_GAMEPAD_BUTTON_BACK* = 6
  GLFW_GAMEPAD_BUTTON_START* = 7
  GLFW_GAMEPAD_BUTTON_GUIDE* = 8
  GLFW_GAMEPAD_BUTTON_LEFT_THUMB* = 9
  GLFW_GAMEPAD_BUTTON_RIGHT_THUMB* = 10
  GLFW_GAMEPAD_BUTTON_DPAD_UP* = 11
  GLFW_GAMEPAD_BUTTON_DPAD_RIGHT* = 12
  GLFW_GAMEPAD_BUTTON_DPAD_DOWN* = 13
  GLFW_GAMEPAD_BUTTON_DPAD_LEFT* = 14
  GLFW_GAMEPAD_BUTTON_LAST* = GLFW_GAMEPAD_BUTTON_DPAD_LEFT
  GLFW_GAMEPAD_BUTTON_CROSS* = GLFW_GAMEPAD_BUTTON_A
  GLFW_GAMEPAD_BUTTON_CIRCLE* = GLFW_GAMEPAD_BUTTON_B
  GLFW_GAMEPAD_BUTTON_SQUARE* = GLFW_GAMEPAD_BUTTON_X
  GLFW_GAMEPAD_BUTTON_TRIANGLE* = GLFW_GAMEPAD_BUTTON_Y


const
  GLFW_GAMEPAD_AXIS_LEFT_X* = 0
  GLFW_GAMEPAD_AXIS_LEFT_Y* = 1
  GLFW_GAMEPAD_AXIS_RIGHT_X* = 2
  GLFW_GAMEPAD_AXIS_RIGHT_Y* = 3
  GLFW_GAMEPAD_AXIS_LEFT_TRIGGER* = 4
  GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER* = 5
  GLFW_GAMEPAD_AXIS_LAST* = GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER


const
  GLFW_NO_ERROR* = 0


const
  GLFW_NOT_INITIALIZED* = 0x00010001


const
  GLFW_NO_CURRENT_CONTEXT* = 0x00010002


const
  GLFW_INVALID_ENUM* = 0x00010003


const
  GLFW_INVALID_VALUE* = 0x00010004


const
  GLFW_OUT_OF_MEMORY* = 0x00010005


const
  GLFW_API_UNAVAILABLE* = 0x00010006


const
  GLFW_VERSION_UNAVAILABLE* = 0x00010007


const
  GLFW_PLATFORM_ERROR* = 0x00010008


const
  GLFW_FORMAT_UNAVAILABLE* = 0x00010009


const
  GLFW_NO_WINDOW_CONTEXT* = 0x0001000A


const
  GLFW_FOCUSED* = 0x00020001


const
  GLFW_ICONIFIED* = 0x00020002


const
  GLFW_RESIZABLE* = 0x00020003


const
  GLFW_VISIBLE* = 0x00020004


const
  GLFW_DECORATED* = 0x00020005


const
  GLFW_AUTO_ICONIFY* = 0x00020006


const
  GLFW_FLOATING* = 0x00020007


const
  GLFW_MAXIMIZED* = 0x00020008


const
  GLFW_CENTER_CURSOR* = 0x00020009


const
  GLFW_TRANSPARENT_FRAMEBUFFER* = 0x0002000A


const
  GLFW_HOVERED* = 0x0002000B


const
  GLFW_FOCUS_ON_SHOW* = 0x0002000C


const
  GLFW_RED_BITS* = 0x00021001


const
  GLFW_GREEN_BITS* = 0x00021002


const
  GLFW_BLUE_BITS* = 0x00021003


const
  GLFW_ALPHA_BITS* = 0x00021004


const
  GLFW_DEPTH_BITS* = 0x00021005


const
  GLFW_STENCIL_BITS* = 0x00021006


const
  GLFW_ACCUM_RED_BITS* = 0x00021007


const
  GLFW_ACCUM_GREEN_BITS* = 0x00021008


const
  GLFW_ACCUM_BLUE_BITS* = 0x00021009


const
  GLFW_ACCUM_ALPHA_BITS* = 0x0002100A


const
  GLFW_AUX_BUFFERS* = 0x0002100B


const
  GLFW_STEREO* = 0x0002100C


const
  GLFW_SAMPLES* = 0x0002100D


const
  GLFW_SRGB_CAPABLE* = 0x0002100E


const
  GLFW_REFRESH_RATE* = 0x0002100F


const
  GLFW_DOUBLEBUFFER* = 0x00021010


const
  GLFW_CLIENT_API* = 0x00022001


const
  GLFW_CONTEXT_VERSION_MAJOR* = 0x00022002


const
  GLFW_CONTEXT_VERSION_MINOR* = 0x00022003


const
  GLFW_CONTEXT_REVISION* = 0x00022004


const
  GLFW_CONTEXT_ROBUSTNESS* = 0x00022005


const
  GLFW_OPENGL_FORWARD_COMPAT* = 0x00022006


const
  GLFW_OPENGL_DEBUG_CONTEXT* = 0x00022007


const
  GLFW_OPENGL_PROFILE* = 0x00022008


const
  GLFW_CONTEXT_RELEASE_BEHAVIOR* = 0x00022009


const
  GLFW_CONTEXT_NO_ERROR* = 0x0002200A


const
  GLFW_CONTEXT_CREATION_API* = 0x0002200B


const
  GLFW_SCALE_TO_MONITOR* = 0x0002200C


const
  GLFW_COCOA_RETINA_FRAMEBUFFER* = 0x00023001


const
  GLFW_COCOA_FRAME_NAME* = 0x00023002


const
  GLFW_COCOA_GRAPHICS_SWITCHING* = 0x00023003


const
  GLFW_X11_CLASS_NAME* = 0x00024001


const
  GLFW_X11_INSTANCE_NAME* = 0x00024002


const
  GLFW_NO_API* = 0
  GLFW_OPENGL_API* = 0x00030001
  GLFW_OPENGL_ES_API* = 0x00030002
  GLFW_NO_ROBUSTNESS* = 0
  GLFW_NO_RESET_NOTIFICATION* = 0x00031001
  GLFW_LOSE_CONTEXT_ON_RESET* = 0x00031002
  GLFW_OPENGL_ANY_PROFILE* = 0
  GLFW_OPENGL_CORE_PROFILE* = 0x00032001
  GLFW_OPENGL_COMPAT_PROFILE* = 0x00032002

const
  cGLFW_CURSOR* = 0x00033001
  GLFW_STICKY_KEYS* = 0x00033002
  GLFW_STICKY_MOUSE_BUTTONS* = 0x00033003
  GLFW_LOCK_KEY_MODS* = 0x00033004
  GLFW_RAW_MOUSE_MOTION* = 0x00033005
  GLFW_CURSOR_NORMAL* = 0x00034001
  GLFW_CURSOR_HIDDEN* = 0x00034002
  GLFW_CURSOR_DISABLED* = 0x00034003
  GLFW_ANY_RELEASE_BEHAVIOR* = 0
  GLFW_RELEASE_BEHAVIOR_FLUSH* = 0x00035001
  GLFW_RELEASE_BEHAVIOR_NONE* = 0x00035002
  GLFW_NATIVE_CONTEXT_API* = 0x00036001
  GLFW_EGL_CONTEXT_API* = 0x00036002
  GLFW_OSMESA_CONTEXT_API* = 0x00036003


const
  GLFW_ARROW_CURSOR* = 0x00036001


const
  GLFW_IBEAM_CURSOR* = 0x00036002


const
  GLFW_CROSSHAIR_CURSOR* = 0x00036003


const
  GLFW_HAND_CURSOR* = 0x00036004


const
  GLFW_HRESIZE_CURSOR* = 0x00036005


const
  GLFW_VRESIZE_CURSOR* = 0x00036006


const
  GLFW_CONNECTED* = 0x00040001
  GLFW_DISCONNECTED* = 0x00040002


const
  GLFW_JOYSTICK_HAT_BUTTONS* = 0x00050001


const
  GLFW_COCOA_CHDIR_RESOURCES* = 0x00051001


const
  GLFW_COCOA_MENUBAR* = 0x00051002


const
  GLFW_DONT_CARE* = -1


type
  GLFWglproc* = proc () {.cdecl.}

type
  GLFWwindow* {.incompletestruct.} = object
  GLFWmonitor* {.incompletestruct.} = object
  GLFWcursor* {.incompletestruct.} = object

type
  GLFWerrorfun* = proc (a1: cint; a2: cstring) {.cdecl.}


type
  GLFWwindowposfun* = proc (a1: ptr GLFWwindow; a2: cint; a3: cint) {.cdecl.}


type
  GLFWwindowsizefun* = proc (a1: ptr GLFWwindow; a2: cint; a3: cint) {.cdecl.}


type
  GLFWwindowclosefun* = proc (a1: ptr GLFWwindow) {.cdecl.}


type
  GLFWwindowrefreshfun* = proc (a1: ptr GLFWwindow) {.cdecl.}


type
  GLFWwindowfocusfun* = proc (a1: ptr GLFWwindow; a2: cint) {.cdecl.}


type
  GLFWwindowiconifyfun* = proc (a1: ptr GLFWwindow; a2: cint) {.cdecl.}


type
  GLFWwindowmaximizefun* = proc (a1: ptr GLFWwindow; a2: cint) {.cdecl.}


type
  GLFWframebuffersizefun* = proc (a1: ptr GLFWwindow; a2: cint; a3: cint) {.cdecl.}


type
  GLFWwindowcontentscalefun* = proc (a1: ptr GLFWwindow; a2: cfloat; a3: cfloat) {.cdecl.}


type
  GLFWmousebuttonfun* = proc (a1: ptr GLFWwindow; a2: cint; a3: cint; a4: cint) {.cdecl.}


type
  GLFWcursorposfun* = proc (a1: ptr GLFWwindow; a2: cdouble; a3: cdouble) {.cdecl.}


type
  GLFWcursorenterfun* = proc (a1: ptr GLFWwindow; a2: cint) {.cdecl.}


type
  GLFWscrollfun* = proc (a1: ptr GLFWwindow; a2: cdouble; a3: cdouble) {.cdecl.}


type
  GLFWkeyfun* = proc (a1: ptr GLFWwindow; a2: cint; a3: cint; a4: cint; a5: cint) {.cdecl.}


type
  GLFWcharfun* = proc (a1: ptr GLFWwindow; a2: cuint) {.cdecl.}


type
  GLFWcharmodsfun* = proc (a1: ptr GLFWwindow; a2: cuint; a3: cint) {.cdecl.}


type
  GLFWdropfun* = proc (a1: ptr GLFWwindow; a2: cint; a3: cstringArray) {.cdecl.}


type
  GLFWmonitorfun* = proc (a1: ptr GLFWmonitor; a2: cint) {.cdecl.}


type
  GLFWjoystickfun* = proc (a1: cint; a2: cint) {.cdecl.}


type
  GLFWvidmode* {.importc: "GLFWvidmode", header: Glfw3Header, bycopy.} = object
    width* {.importc: "width".}: cint
    height* {.importc: "height".}: cint
    redBits* {.importc: "redBits".}: cint
    greenBits* {.importc: "greenBits".}: cint
    blueBits* {.importc: "blueBits".}: cint
    refreshRate* {.importc: "refreshRate".}: cint



type
  GLFWgammaramp* {.importc: "GLFWgammaramp", header: Glfw3Header, bycopy.} = object
    red* {.importc: "red".}: ptr cushort
    green* {.importc: "green".}: ptr cushort
    blue* {.importc: "blue".}: ptr cushort
    size* {.importc: "size".}: cuint



type
  GLFWimage* {.importc: "GLFWimage", header: Glfw3Header, bycopy.} = object
    width* {.importc: "width".}: cint
    height* {.importc: "height".}: cint
    pixels* {.importc: "pixels".}: ptr cuchar



type
  GLFWgamepadstate* {.importc: "GLFWgamepadstate", header: Glfw3Header, bycopy.} = object
    buttons* {.importc: "buttons".}: array[15, cuchar]
    axes* {.importc: "axes".}: array[6, cfloat]



proc glfwInit*(): cint {.importc: "glfwInit", header: Glfw3Header.}

proc glfwTerminate*() {.importc: "glfwTerminate", header: Glfw3Header.}

proc glfwInitHint*(hint: cint; value: cint) {.importc: "glfwInitHint",
    header: Glfw3Header.}

proc glfwGetVersion*(major: ptr cint; minor: ptr cint; rev: ptr cint) {.
    importc: "glfwGetVersion", header: Glfw3Header.}

proc glfwGetVersionString*(): cstring {.importc: "glfwGetVersionString",
                                     header: Glfw3Header.}

proc glfwGetError*(description: cstringArray): cint {.importc: "glfwGetError",
    header: Glfw3Header.}

proc glfwSetErrorCallback*(cbfun: GLFWerrorfun): GLFWerrorfun {.discardable,
    importc: "glfwSetErrorCallback", header: Glfw3Header.}

proc glfwGetMonitors*(count: ptr cint): ptr ptr GLFWmonitor {.
    importc: "glfwGetMonitors", header: Glfw3Header.}

proc glfwGetPrimaryMonitor*(): ptr GLFWmonitor {.importc: "glfwGetPrimaryMonitor",
    header: Glfw3Header.}

proc glfwGetMonitorPos*(monitor: ptr GLFWmonitor; xpos: ptr cint; ypos: ptr cint) {.
    importc: "glfwGetMonitorPos", header: Glfw3Header.}

proc glfwGetMonitorWorkarea*(monitor: ptr GLFWmonitor; xpos: ptr cint; ypos: ptr cint;
                            width: ptr cint; height: ptr cint) {.
    importc: "glfwGetMonitorWorkarea", header: Glfw3Header.}

proc glfwGetMonitorPhysicalSize*(monitor: ptr GLFWmonitor; widthMM: ptr cint;
                                heightMM: ptr cint) {.
    importc: "glfwGetMonitorPhysicalSize", header: Glfw3Header.}

proc glfwGetMonitorContentScale*(monitor: ptr GLFWmonitor; xscale: ptr cfloat;
                                yscale: ptr cfloat) {.
    importc: "glfwGetMonitorContentScale", header: Glfw3Header.}

proc glfwGetMonitorName*(monitor: ptr GLFWmonitor): cstring {.
    importc: "glfwGetMonitorName", header: Glfw3Header.}

proc glfwSetMonitorUserPointer*(monitor: ptr GLFWmonitor; pointer: pointer) {.
    importc: "glfwSetMonitorUserPointer", header: Glfw3Header.}

proc glfwGetMonitorUserPointer*(monitor: ptr GLFWmonitor): pointer {.
    importc: "glfwGetMonitorUserPointer", header: Glfw3Header.}

proc glfwSetMonitorCallback*(cbfun: GLFWmonitorfun): GLFWmonitorfun {.discardable,
    importc: "glfwSetMonitorCallback", header: Glfw3Header.}

proc glfwGetVideoModes*(monitor: ptr GLFWmonitor; count: ptr cint): ptr GLFWvidmode {.
    importc: "glfwGetVideoModes", header: Glfw3Header.}

proc glfwGetVideoMode*(monitor: ptr GLFWmonitor): ptr GLFWvidmode {.
    importc: "glfwGetVideoMode", header: Glfw3Header.}

proc glfwSetGamma*(monitor: ptr GLFWmonitor; gamma: cfloat) {.importc: "glfwSetGamma",
    header: Glfw3Header.}

proc glfwGetGammaRamp*(monitor: ptr GLFWmonitor): ptr GLFWgammaramp {.
    importc: "glfwGetGammaRamp", header: Glfw3Header.}

proc glfwSetGammaRamp*(monitor: ptr GLFWmonitor; ramp: ptr GLFWgammaramp) {.
    importc: "glfwSetGammaRamp", header: Glfw3Header.}

proc glfwDefaultWindowHints*() {.importc: "glfwDefaultWindowHints",
                               header: Glfw3Header.}

proc glfwWindowHint*(hint: cint; value: cint) {.importc: "glfwWindowHint",
    header: Glfw3Header.}

proc glfwWindowHintString*(hint: cint; value: cstring) {.
    importc: "glfwWindowHintString", header: Glfw3Header.}

proc glfwCreateWindow*(width: cint; height: cint; title: cstring;
                      monitor: ptr GLFWmonitor; share: ptr GLFWwindow): ptr GLFWwindow {.
    importc: "glfwCreateWindow", header: Glfw3Header.}

proc glfwDestroyWindow*(window: ptr GLFWwindow) {.importc: "glfwDestroyWindow",
    header: Glfw3Header.}

proc glfwWindowShouldClose*(window: ptr GLFWwindow): cint {.
    importc: "glfwWindowShouldClose", header: Glfw3Header.}

proc glfwSetWindowShouldClose*(window: ptr GLFWwindow; value: cint) {.
    importc: "glfwSetWindowShouldClose", header: Glfw3Header.}

proc glfwSetWindowTitle*(window: ptr GLFWwindow; title: cstring) {.
    importc: "glfwSetWindowTitle", header: Glfw3Header.}

proc glfwSetWindowIcon*(window: ptr GLFWwindow; count: cint; images: ptr GLFWimage) {.
    importc: "glfwSetWindowIcon", header: Glfw3Header.}

proc glfwGetWindowPos*(window: ptr GLFWwindow; xpos: ptr cint; ypos: ptr cint) {.
    importc: "glfwGetWindowPos", header: Glfw3Header.}

proc glfwSetWindowPos*(window: ptr GLFWwindow; xpos: cint; ypos: cint) {.
    importc: "glfwSetWindowPos", header: Glfw3Header.}

proc glfwGetWindowSize*(window: ptr GLFWwindow; width: ptr cint; height: ptr cint) {.
    importc: "glfwGetWindowSize", header: Glfw3Header.}

proc glfwSetWindowSizeLimits*(window: ptr GLFWwindow; minwidth: cint; minheight: cint;
                             maxwidth: cint; maxheight: cint) {.
    importc: "glfwSetWindowSizeLimits", header: Glfw3Header.}

proc glfwSetWindowAspectRatio*(window: ptr GLFWwindow; numer: cint; denom: cint) {.
    importc: "glfwSetWindowAspectRatio", header: Glfw3Header.}

proc glfwSetWindowSize*(window: ptr GLFWwindow; width: cint; height: cint) {.
    importc: "glfwSetWindowSize", header: Glfw3Header.}

proc glfwGetFramebufferSize*(window: ptr GLFWwindow; width: ptr cint; height: ptr cint) {.
    importc: "glfwGetFramebufferSize", header: Glfw3Header.}

proc glfwGetWindowFrameSize*(window: ptr GLFWwindow; left: ptr cint; top: ptr cint;
                            right: ptr cint; bottom: ptr cint) {.
    importc: "glfwGetWindowFrameSize", header: Glfw3Header.}

proc glfwGetWindowContentScale*(window: ptr GLFWwindow; xscale: ptr cfloat;
                               yscale: ptr cfloat) {.
    importc: "glfwGetWindowContentScale", header: Glfw3Header.}

proc glfwGetWindowOpacity*(window: ptr GLFWwindow): cfloat {.
    importc: "glfwGetWindowOpacity", header: Glfw3Header.}

proc glfwSetWindowOpacity*(window: ptr GLFWwindow; opacity: cfloat) {.
    importc: "glfwSetWindowOpacity", header: Glfw3Header.}

proc glfwIconifyWindow*(window: ptr GLFWwindow) {.importc: "glfwIconifyWindow",
    header: Glfw3Header.}

proc glfwRestoreWindow*(window: ptr GLFWwindow) {.importc: "glfwRestoreWindow",
    header: Glfw3Header.}

proc glfwMaximizeWindow*(window: ptr GLFWwindow) {.importc: "glfwMaximizeWindow",
    header: Glfw3Header.}

proc glfwShowWindow*(window: ptr GLFWwindow) {.importc: "glfwShowWindow",
    header: Glfw3Header.}

proc glfwHideWindow*(window: ptr GLFWwindow) {.importc: "glfwHideWindow",
    header: Glfw3Header.}

proc glfwFocusWindow*(window: ptr GLFWwindow) {.importc: "glfwFocusWindow",
    header: Glfw3Header.}

proc glfwRequestWindowAttention*(window: ptr GLFWwindow) {.
    importc: "glfwRequestWindowAttention", header: Glfw3Header.}

proc glfwGetWindowMonitor*(window: ptr GLFWwindow): ptr GLFWmonitor {.
    importc: "glfwGetWindowMonitor", header: Glfw3Header.}

proc glfwSetWindowMonitor*(window: ptr GLFWwindow; monitor: ptr GLFWmonitor;
                          xpos: cint; ypos: cint; width: cint; height: cint;
                          refreshRate: cint) {.importc: "glfwSetWindowMonitor",
    header: Glfw3Header.}

proc glfwGetWindowAttrib*(window: ptr GLFWwindow; attrib: cint): cint {.
    importc: "glfwGetWindowAttrib", header: Glfw3Header.}

proc glfwSetWindowAttrib*(window: ptr GLFWwindow; attrib: cint; value: cint) {.
    importc: "glfwSetWindowAttrib", header: Glfw3Header.}

proc glfwSetWindowUserPointer*(window: ptr GLFWwindow; pointer: pointer) {.
    importc: "glfwSetWindowUserPointer", header: Glfw3Header.}

proc glfwGetWindowUserPointer*(window: ptr GLFWwindow): pointer {.
    importc: "glfwGetWindowUserPointer", header: Glfw3Header.}

proc glfwSetWindowPosCallback*(window: ptr GLFWwindow; cbfun: GLFWwindowposfun): GLFWwindowposfun {.
    discardable, importc: "glfwSetWindowPosCallback", header: Glfw3Header.}

proc glfwSetWindowSizeCallback*(window: ptr GLFWwindow; cbfun: GLFWwindowsizefun): GLFWwindowsizefun {.
    discardable, importc: "glfwSetWindowSizeCallback", header: Glfw3Header.}

proc glfwSetWindowCloseCallback*(window: ptr GLFWwindow; cbfun: GLFWwindowclosefun): GLFWwindowclosefun {.
    discardable, importc: "glfwSetWindowCloseCallback", header: Glfw3Header.}

proc glfwSetWindowRefreshCallback*(window: ptr GLFWwindow;
                                  cbfun: GLFWwindowrefreshfun): GLFWwindowrefreshfun {.
    discardable, importc: "glfwSetWindowRefreshCallback", header: Glfw3Header.}

proc glfwSetWindowFocusCallback*(window: ptr GLFWwindow; cbfun: GLFWwindowfocusfun): GLFWwindowfocusfun {.
    discardable, importc: "glfwSetWindowFocusCallback", header: Glfw3Header.}

proc glfwSetWindowIconifyCallback*(window: ptr GLFWwindow;
                                  cbfun: GLFWwindowiconifyfun): GLFWwindowiconifyfun {.
    discardable, importc: "glfwSetWindowIconifyCallback", header: Glfw3Header.}

proc glfwSetWindowMaximizeCallback*(window: ptr GLFWwindow;
                                   cbfun: GLFWwindowmaximizefun): GLFWwindowmaximizefun {.
    discardable, importc: "glfwSetWindowMaximizeCallback", header: Glfw3Header.}

proc glfwSetFramebufferSizeCallback*(window: ptr GLFWwindow;
                                    cbfun: GLFWframebuffersizefun): GLFWframebuffersizefun {.
    discardable, importc: "glfwSetFramebufferSizeCallback", header: Glfw3Header.}

proc glfwSetWindowContentScaleCallback*(window: ptr GLFWwindow;
                                       cbfun: GLFWwindowcontentscalefun): GLFWwindowcontentscalefun {.
    discardable, importc: "glfwSetWindowContentScaleCallback", header: Glfw3Header.}

proc glfwPollEvents*() {.importc: "glfwPollEvents", header: Glfw3Header.}

proc glfwWaitEvents*() {.importc: "glfwWaitEvents", header: Glfw3Header.}

proc glfwWaitEventsTimeout*(timeout: cdouble) {.importc: "glfwWaitEventsTimeout",
    header: Glfw3Header.}

proc glfwPostEmptyEvent*() {.importc: "glfwPostEmptyEvent", header: Glfw3Header.}

proc glfwGetInputMode*(window: ptr GLFWwindow; mode: cint): cint {.
    importc: "glfwGetInputMode", header: Glfw3Header.}

proc glfwSetInputMode*(window: ptr GLFWwindow; mode: cint; value: cint) {.
    importc: "glfwSetInputMode", header: Glfw3Header.}

proc glfwRawMouseMotionSupported*(): cint {.importc: "glfwRawMouseMotionSupported",
    header: Glfw3Header.}

proc glfwGetKeyName*(key: cint; scancode: cint): cstring {.importc: "glfwGetKeyName",
    header: Glfw3Header.}

proc glfwGetKeyScancode*(key: cint): cint {.importc: "glfwGetKeyScancode",
                                        header: Glfw3Header.}

proc glfwGetKey*(window: ptr GLFWwindow; key: cint): cint {.importc: "glfwGetKey",
    header: Glfw3Header.}

proc glfwGetMouseButton*(window: ptr GLFWwindow; button: cint): cint {.
    importc: "glfwGetMouseButton", header: Glfw3Header.}

proc glfwGetCursorPos*(window: ptr GLFWwindow; xpos: ptr cdouble; ypos: ptr cdouble) {.
    importc: "glfwGetCursorPos", header: Glfw3Header.}

proc glfwSetCursorPos*(window: ptr GLFWwindow; xpos: cdouble; ypos: cdouble) {.
    importc: "glfwSetCursorPos", header: Glfw3Header.}

proc glfwCreateCursor*(image: ptr GLFWimage; xhot: cint; yhot: cint): ptr GLFWcursor {.
    importc: "glfwCreateCursor", header: Glfw3Header.}

proc glfwCreateStandardCursor*(shape: cint): ptr GLFWcursor {.
    importc: "glfwCreateStandardCursor", header: Glfw3Header.}

proc glfwDestroyCursor*(cursor: ptr GLFWcursor) {.importc: "glfwDestroyCursor",
    header: Glfw3Header.}

proc glfwSetCursor*(window: ptr GLFWwindow; cursor: ptr GLFWcursor) {.
    importc: "glfwSetCursor", header: Glfw3Header.}

proc glfwSetKeyCallback*(window: ptr GLFWwindow; cbfun: GLFWkeyfun): GLFWkeyfun {.
    discardable, importc: "glfwSetKeyCallback", header: Glfw3Header.}

proc glfwSetCharCallback*(window: ptr GLFWwindow; cbfun: GLFWcharfun): GLFWcharfun {.
    discardable, importc: "glfwSetCharCallback", header: Glfw3Header.}

proc glfwSetCharModsCallback*(window: ptr GLFWwindow; cbfun: GLFWcharmodsfun): GLFWcharmodsfun {.
    discardable, importc: "glfwSetCharModsCallback", header: Glfw3Header.}

proc glfwSetMouseButtonCallback*(window: ptr GLFWwindow; cbfun: GLFWmousebuttonfun): GLFWmousebuttonfun {.
    discardable, importc: "glfwSetMouseButtonCallback", header: Glfw3Header.}

proc glfwSetCursorPosCallback*(window: ptr GLFWwindow; cbfun: GLFWcursorposfun): GLFWcursorposfun {.
    discardable, importc: "glfwSetCursorPosCallback", header: Glfw3Header.}

proc glfwSetCursorEnterCallback*(window: ptr GLFWwindow; cbfun: GLFWcursorenterfun): GLFWcursorenterfun {.
    discardable, importc: "glfwSetCursorEnterCallback", header: Glfw3Header.}

proc glfwSetScrollCallback*(window: ptr GLFWwindow; cbfun: GLFWscrollfun): GLFWscrollfun {.
    discardable, importc: "glfwSetScrollCallback", header: Glfw3Header.}

proc glfwSetDropCallback*(window: ptr GLFWwindow; cbfun: GLFWdropfun): GLFWdropfun {.
    discardable, importc: "glfwSetDropCallback", header: Glfw3Header.}

proc glfwJoystickPresent*(jid: cint): cint {.importc: "glfwJoystickPresent",
    header: Glfw3Header.}

proc glfwGetJoystickAxes*(jid: cint; count: ptr cint): ptr cfloat {.
    importc: "glfwGetJoystickAxes", header: Glfw3Header.}

proc glfwGetJoystickButtons*(jid: cint; count: ptr cint): ptr cuchar {.
    importc: "glfwGetJoystickButtons", header: Glfw3Header.}

proc glfwGetJoystickHats*(jid: cint; count: ptr cint): ptr cuchar {.
    importc: "glfwGetJoystickHats", header: Glfw3Header.}

proc glfwGetJoystickName*(jid: cint): cstring {.importc: "glfwGetJoystickName",
    header: Glfw3Header.}

proc glfwGetJoystickGUID*(jid: cint): cstring {.importc: "glfwGetJoystickGUID",
    header: Glfw3Header.}

proc glfwSetJoystickUserPointer*(jid: cint; pointer: pointer) {.
    importc: "glfwSetJoystickUserPointer", header: Glfw3Header.}

proc glfwGetJoystickUserPointer*(jid: cint): pointer {.
    importc: "glfwGetJoystickUserPointer", header: Glfw3Header.}

proc glfwJoystickIsGamepad*(jid: cint): cint {.importc: "glfwJoystickIsGamepad",
    header: Glfw3Header.}

proc glfwSetJoystickCallback*(cbfun: GLFWjoystickfun): GLFWjoystickfun {.
    discardable, importc: "glfwSetJoystickCallback", header: Glfw3Header.}

proc glfwUpdateGamepadMappings*(string: cstring): cint {.
    importc: "glfwUpdateGamepadMappings", header: Glfw3Header.}

proc glfwGetGamepadName*(jid: cint): cstring {.importc: "glfwGetGamepadName",
    header: Glfw3Header.}

proc glfwGetGamepadState*(jid: cint; state: ptr GLFWgamepadstate): cint {.
    importc: "glfwGetGamepadState", header: Glfw3Header.}

proc glfwSetClipboardString*(window: ptr GLFWwindow; string: cstring) {.
    importc: "glfwSetClipboardString", header: Glfw3Header.}

proc glfwGetClipboardString*(window: ptr GLFWwindow): cstring {.
    importc: "glfwGetClipboardString", header: Glfw3Header.}

proc glfwGetTime*(): cdouble {.importc: "glfwGetTime", header: Glfw3Header.}

proc glfwSetTime*(time: cdouble) {.importc: "glfwSetTime", header: Glfw3Header.}

proc glfwGetTimerValue*(): uint64 {.importc: "glfwGetTimerValue", header: Glfw3Header.}

proc glfwGetTimerFrequency*(): uint64 {.importc: "glfwGetTimerFrequency",
                                     header: Glfw3Header.}

proc glfwMakeContextCurrent*(window: ptr GLFWwindow) {.
    importc: "glfwMakeContextCurrent", header: Glfw3Header.}

proc glfwGetCurrentContext*(): ptr GLFWwindow {.importc: "glfwGetCurrentContext",
    header: Glfw3Header.}

proc glfwSwapBuffers*(window: ptr GLFWwindow) {.importc: "glfwSwapBuffers",
    header: Glfw3Header.}

proc glfwSwapInterval*(interval: cint) {.importc: "glfwSwapInterval",
                                      header: Glfw3Header.}

proc glfwExtensionSupported*(extension: cstring): cint {.
    importc: "glfwExtensionSupported", header: Glfw3Header.}

proc glfwGetProcAddress*(procname: cstring): GLFWglproc {.
    importc: "glfwGetProcAddress", header: Glfw3Header.}
