proc cmalloc*(size: int): pointer {.importcpp: "::operator new(@)".}
proc cfree*(target: pointer) {.importcpp: "::operator delete(@)".}

proc calloc*(T: typedesc): ptr T {.inline.} =
  cast[ptr T](cmalloc(sizeof T))

proc calloc*(T: typedesc, count: int): ptr UncheckedArray[T] {.inline.} =
  cast[ptr UncheckedArray[T]](cmalloc(count * sizeof T))