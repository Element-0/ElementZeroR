import allocator
import ../utils

type CppStringStorage {.union.} = object
  buffer: array[16, char]
  extend: ptr UncheckedArray[char]

type CppString* = object
  data: CppStringStorage
  len: int
  cap: int

proc `=destroy`*(str: var CppString) =
  if str.cap >= 16:
    cfree(str.data.extend)

proc c_str*(str: CppString): cstring {.genref.} =
  if str.cap < 16:
    return unsafeAddr str.data.buffer
  else:
    return str.data.extend

proc `=copy`*(str: var CppString, rhs: CppString) =
  if str.cap == rhs.cap and str.cap >= 16 and str.data.extend == str.data.extend:
    return
  if rhs.cap < 16:
    if str.cap >= 16:
      `=destroy`(str)
      wasMoved(str)
    copyMem(addr str, unsafeAddr rhs, sizeof CppString)
  elif str.cap >= rhs.cap:
    str.len = rhs.len
    copyMem(str.data.extend, rhs.data.extend, rhs.len + 1)
  else:
    `=destroy`(str)
    wasMoved(str)
    str.len = rhs.len
    str.cap = rhs.len
    str.data.extend = cast[ptr UncheckedArray[char]](cmalloc(rhs.len + 1))
    copyMem(str.data.extend, rhs.data.extend, rhs.len + 1)

proc initCppString*(str: string): CppString {.genrefnew.} =
  result.len = str.len
  if str.len < 16:
    result.cap = 15
    copyMem(result.data.buffer.addr, str.cstring, str.len + 1)
  else:
    result.cap = str.len
    result.data.extend = cast[ptr UncheckedArray[char]](cmalloc(str.len + 1))
    copyMem(result.data.extend, str.cstring, str.len + 1)

converter toCppString*(str: string): CppString = initCppString(str)
converter toCppStringRef*(str: string): ref CppString = newCppString(str)
converter makeRef*(str: sink CppString): ref CppString {.nodestroy.} =
  new(result)
  copyMem(addr result[], unsafeAddr str, sizeof CppString)

proc `$`*(str: CppString): string {.genref.} = $(str.c_str())