import tables

import winim/mean
import clapfn

import dia2

CoInitializeEx(nil, 0)

var cliparser = ArgumentParser(
  programName: "pdbparser",
  fullName: "PDB Parser",
  description: "Parse bedrock_server.pdb file",
  version: "0.0.0"
)

cliparser.addRequiredArgument(name = "pdb_file", help = "PDB file")

proc main(target: string) =
  var source = createDataSource()
  var session = source.loadSession(target)
  var global = session.global
  for symbol in global.findChildren(SymTagPublicSymbol):
    echo "symbol: ", symbol.virtualAddress.toHex, "=", symbol.name

let args = cliparser.parse()

main(args["pdb_file"])