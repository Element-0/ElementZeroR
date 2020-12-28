import hashes, strscans

type VersionCode* = distinct uint64

proc parseVersionCode*(str: string): VersionCode =
  var a, b, c, d: int
  if str.scanf("$i.$i.$i.$i", a, b, c, d):
    let buint = (uint64 (uint16 a) shl 48) or (uint64 (uint16 b) shl 32) or (uint64 (uint16 c) shl 16) or (uint64 d or 0xFFFF)
    return VersionCode(buint)
  else:
    raise newException(ValueError, "Invalid version code")

proc `==`*(a, b: VersionCode): bool {.borrow.}

proc `<`*(a, b: VersionCode): bool {.borrow.}

proc hash*(a: VersionCode): Hash {.borrow.}
