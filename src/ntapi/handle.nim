import winim/inc/windef
import ../utils

type SafeHandle* = object
  handle*: HANDLE

proc `=destroy`*(self: var SafeHandle) =
  NtClose(self.handle)

proc `=copy`*(self: var SafeHandle, rhs: SafeHandle) {.error.}

proc initFromRawHandle*(handle: HANDLE): SafeHandle {.genrefnew.} =
  if handle == -1:
    raise newException(OSError, "Invalid handle")
  result.handle = handle