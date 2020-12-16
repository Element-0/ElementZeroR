import allocator
import ../utils

type CppVector*[T] = object
  data: ptr UncheckedArray[T]
  last, rend: ptr T

proc len*[T](arr: CppVector[T]): int {.inline, genref.} =
  ptrMath: arr.last - cast[ptr T](arr.data)

proc low*[T](arr: CppVector[T]): int {.inline, genref.} = 0
proc high*[T](arr: CppVector[T]): int {.inline, genref.} = len(arr) - 1

proc cap*[T](arr: CppVector[T]): int {.inline, genref.} =
  ptrMath: arr.rend - cast[ptr T](arr.data)

iterator items*[T](arr: CppVector[T]): T {.inline, genref.} =
  for i in 0..<arr.len:
    yield arr.data[i]

iterator mitems*[T](arr: var CppVector[T]): var T {.inline, genref.} =
  for i in 0..<arr.len:
    yield arr.data[i]

iterator pairs*[T](arr: CppVector[T]): (int, T) {.inline, genref.} =
  for i in 0..<arr.len:
    yield (i, arr.data[i])

iterator mpairs*[T](arr: var CppVector[T]): (int, var T) {.inline.} =
  for i in 0..<arr.len:
    yield (i, arr.data[i])

proc `=destroy`*[T](arr: var CppVector[T]) =
  if arr.data.isNil: return
  for item in arr.mitems:
    `=destroy` item
  cfree arr.data

proc unsafeSet[T](arr: var CppVector[T], rhs: openarray[T]) {.inline.} =
  for i, item in rhs:
    wasMoved arr.data[i]
    arr.data[i] = rhs[i]
  arr.last = ptrMath: cast[ptr T](arr.data) + rhs.len

proc set*[T](arr: var CppVector[T], rhs: openarray[T]) {.inline, genref.} =
  if arr.cap < rhs.len:
    `=destroy` arr
    wasMoved arr
    arr.data = calloc(T, rhs.len)
    arr.rend = ptrMath: cast[ptr T](arr.data) + rhs.len
  else:
    for item in arr.mitems:
      `=destroy` item
      wasMoved item
  arr.unsafeSet(rhs)

proc `[]`*[T](arr: CppVector[T], i: int): T {.genref.} =
  arr.data[i]

proc `[]=`*[T](arr: var CppVector[T], i: int, rhs: sink T) {.genref.} =
  arr.data[i] = rhs

proc reserve*[T](arr: var CppVector[T], newsize: int) {.genref.} =
  if newsize <= arr.len or newsize == arr.cap: return
  let tmp = calloc(T, newsize)
  for i, item in arr.mpairs:
    wasMoved tmp[i]
    tmp[i] = move item
  cfree(arr.data)
  let slen = arr.len
  arr.data = tmp
  ptrMath:
    arr.last = cast[ptr T](tmp) + slen
    arr.rend = cast[ptr T](tmp) + newsize

proc add*[T](arr: var CppVector[T], rhs: sink T) {.genref.} =
  if unlikely(arr.cap < arr.len + 1):
    arr.reserve ((arr.len + 1).toFloat * 1.5).toInt
  wasMoved arr.last[]
  arr.last[] = rhs
  ptrMath: arr.last += 1

template toOpenArray*[T](arr: CppVector[T]): openarray[T] =
  arr.data.toOpenArray(0, arr.len - 1)

template toOpenArray*[T](arr: ref CppVector[T]): openarray[T] =
  arr[].data.toOpenArray(0, arr.len - 1)

proc `=copy`*[T](arr: var CppVector[T], rhs: CppVector[T]) =
  if arr.data == rhs.data: return
  arr.set(rhs.toOpenArray())

proc initCppVector*[T](cap: int): CppVector[T] {.genrefnew.} =
  result.data = calloc(T, cap)
  result.last = cast[ptr T](result.data)
  result.rend = ptrMath: cast[ptr T](result.data) + cap

proc initCppVector*[T](arr: openarray[T]): CppVector[T] {.genrefnew.} =
  if arr.len == 0: return
  result.set(arr)
