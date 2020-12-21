import macros
import pdbparser/symhash

when defined(chakra):
  import winim/inc/winbase
  import sqlite3/sqlutils

  proc selectSymbol(hash: int64): tuple[address: int] {.importdb: "SELECT address FROM symbols_hash WHERE symbol=$hash".}

  var symdb = initDatabase "bedrock_server.db"
  var baseaddr = cast[ByteAddress](GetModuleHandle(nil))

  proc findSymbolByHash*(hash: int64): ByteAddress {.exportc, dynlib.} =
    cast[ByteAddress](symdb.selectSymbol(hash).address) + baseaddr
else:
  proc findSymbolByHash*(hash: int64): ByteAddress {.importc, dynlib: "chakra.dll".}

proc findSymbol*(symbol: static string, T: typedesc): T =
  const hash = symhash(symbol)
  var cached {.global.}: T
  if cached == nil:
    try:
      result = cast[T](findSymbolByHash(hash))
      cached = result
    except:
      quit "Symbol '" & symbol & "' not found!"
  else:
    result = cached

macro importmc*(sym: static string, body: untyped) =
  let xtype = nnkProcTy.newTree(
    body[3].copy(),
    nnkPragma.newTree(ident "cdecl")
  )
  let fname = body[0].copy()
  result = quote do:
    let `fname` = findSymbol(`sym`, `xtype`)