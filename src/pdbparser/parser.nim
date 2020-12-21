import parseopt
import options

import winim/mean

import dia2
import symhash

import ../sqlite3/sqlutils

CoInitializeEx(nil, 0)

proc parsePrint(target: string) =
  echo target
  var source = createDataSource()
  var session = source.loadSession(target)
  var global = session.global
  for symbol in global.findChildren(SymTagPublicSymbol):
    echo "symbol: ", symbol.virtualAddress.toHex, "=", symbol.name

proc create_table() {.importdb: "CREATE TABLE IF NOT EXISTS symbols_hash (symbol INTEGER PRIMARY KEY, address INTEGER) WITHOUT ROWID".}
proc insert_symbol(symbol: int64, address: int) {.importdb: "REPLACE INTO symbols_hash VALUES ($symbol, $address)".}

proc parseSave(target: string, db: string) =
  var source = createDataSource()
  var session = source.loadSession(target)
  var global = session.global
  var db = newDatabase(db)
  db[].create_table()
  var tran = db.initTransaction()
  for symbol in global.findChildren(SymTagPublicSymbol):
    db[].insert_symbol(symhash(symbol.name), symbol.virtualAddress)
  tran.commit()

proc writeHelp() =
  echo "pdb parser"
  echo "usage:"
  echo "pdbparser <bedrock_server.pdb> [--database:sqlite3db]"

var p = initOptParser()

var filename = none string
var database = none string

for kind, key, val in p.getopt():
  case kind:
  of cmdEnd: assert(false)
  of cmdArgument:
    if filename.isNone():
      filename = some key
    else:
      quit "too many arguments"
  of cmdShortOption, cmdLongOption:
    case key:
    of "h", "help":
      writeHelp()
      quit 0
    of "database":
      if val == "":
        quit "need database filename"
      database = some val
    else:
      echo "invalid option: ", key
      quit 1

if filename.isNone():
  writeHelp()
  quit 0

if database.isNone():
  parsePrint(filename.unsafeGet())
  quit 0

parseSave(filename.unsafeGet(), database.unsafeGet())