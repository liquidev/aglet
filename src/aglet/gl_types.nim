type
  GlBitfield* = uint32
  GlBool* = bool
  GlByte* = int8
  GlChar* = char
  GlCharArb* = byte
  GlClampd* = float64
  GlClampf* = float32
  GlClampx* = int32
  GlDouble* = float64
  GlEglImageOes* = distinct pointer
  GlEnum* = distinct uint32
  GlFixed* = int32
  GlFloat* = float32
  GlHalf* = uint16
  GlHalfArb* = uint16
  GlHalfNv* = uint16
  GlHandleArb* = uint32
  GlInt* = int32
  GlInt64* = int64
  GlInt64Ext* = int64
  GlIntptr* = int
  GlIntptrArb* = int
  GlShort* = int16
  GlSizei* = int32
  GlSizeiptr* = int
  GlSizeiptrArb* = int
  GlSync* = distinct pointer
  GlUbyte* = uint8
  GlUint* = uint32
  GlUint64* = uint64
  GlUint64Ext* = uint64
  GlUshort* = uint16
  GlVdpauSurfaceNv* = int32
  GlVoid* = pointer

proc `==`*(a, b: GlEnum): bool {.borrow.}
