{.compile: "forward.cpp".}

import winim/inc/winbase

import interop/cppstr

import sqlite3/sqlutils
import pdbparser/symhash

proc selectSymbol(hash: int64): tuple[address: int] {.importdb: "SELECT address FROM symbols_hash WHERE symbol=$hash".}

var symdb = initDatabase "bedrock_server.db"
var baseaddr = cast[ByteAddress](GetModuleHandle(nil))

proc findSymbol*(symbol: static string, T: typedesc): T =
  const hash = symhash(symbol)
  try:
    let offset = symdb.selectSymbol(hash).address
    cast[T](cast[ByteAddress](offset) + baseaddr)
  except:
    quit "Symbol '" & symbol & "' not found!"

let getver = findSymbol("?getServerVersionString@Common@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@XZ", proc (): CppString {.cdecl.})

echo getver()
