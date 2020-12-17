import std/os

import dia2
import winim/mean
import winim/winstr

CoInitializeEx(nil, 0)

proc parse(target: string) =
  var source = createDataSource()
  var session = source.loadSession(target)
  var global = session.global
  for symbol in global.findChildren(SymTagPublicSymbol):
    echo "symbol: ", symbol.virtualAddress.toHex, "=", symbol.name

if paramCount() != 1:
  echo "require 1 argument"

parse(paramStr 1)