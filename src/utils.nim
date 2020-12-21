import macros

template ptrMath*(body: untyped) =
  template `+`[T](p: ptr T, off: int): ptr T {.used.} =
    cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

  template `+=`[T](p: ptr T, off: int) {.used.} =
    p = p + off

  template `-`[T](p: ptr T, off: int): ptr T {.used.} =
    cast[ptr type(p[])](cast[ByteAddress](p) -% off * sizeof(p[]))

  template `-=`[T](p: ptr T, off: int) {.used.} =
    p = p - off

  template `[]`[T](p: ptr T, off: int): T {.used.} =
    (p + off)[]

  template `[]=`[T](p: ptr T, off: int, val: T) {.used.} =
    (p + off)[] = val

  template `-`[T](p, r: ptr T): int {.used.} =
    (cast[ByteAddress](p) - cast[ByteAddress](r)) div sizeof(p[])

  body

proc refVar(n: NimNode): NimNode =
  if n.kind == nnkVarTy: nnkRefTy.newTree n[0] else: nnkRefTy.newTree n

macro genref*(body: untyped): untyped =
  # body.expectKind nnkProcDef
  result = newStmtList(body)
  var reffn = body.copy()
  let id = body[0][1]
  let selfid = body[3][1][0]
  var callstmt = nnkCall.newTree(id, nnkBracketExpr.newTree(selfid))
  for item in body[3][2..<body[3].len]:
    callstmt.add item[0]
  reffn[3][1][1] = refVar body[3][1][1]
  reffn[6] = callstmt
  result.add reffn

macro genrefnew*(body: untyped): untyped =
  body.expectKind nnkProcDef
  result = newStmtList(body)
  var reffn = body.copy()
  let id = body[0][1]
  reffn[0][1] = ident ("new" & body[0][1].strVal[4..^1])
  var callstmt = nnkCall.newTree(id)
  for item in body[3][1..<body[3].len]:
    callstmt.add item[0]
  reffn[3][0] = nnkRefTy.newTree body[3][0]
  reffn[6] = quote do:
    new result
    result[] = `callstmt`
  result.add reffn

template disallow_copy*(T: untyped): untyped =
  proc `=copy`*(l: var T, r: T) {.error.}

template genTree*(kind: NimNodeKind, local, body: untyped): NimNode =
  var local {.gensym.} = kind.newNimNode()
  body
  local

template addTree*(src: NimNode, kind: NimNodeKind, local, body: untyped) =
  var local {.gensym.} = kind.newNimNode()
  body
  src.add local

proc getNimIdent*(src: NimNode): string =
  case src.kind:
  of nnkIdent:
    return src.strVal
  of nnkPostfix:
    src[0].expectIdent "*"
    src[1].expectKind nnkIdent
    return src[1].strVal
  else:
    error("Not an ident node")