import nimake
import os
import parsecfg
import support/buildhelper
import support/sqlite3

setCurrentDir getProjectDir()

const depinc = "deps" / "include"
const cfgfile = "config.inf"
let cfg = loadConfig cfgfile

template updateVersion(file, version: string) =
  exec "rcedit " & file & " --set-file-version " & version

testtargets("C++ Interop", "interop", ["tcppstr", "tcppvector"], ["test.cpp"], [])
testtargets("NT Internal API", "ntapi", ["ttransaction"], [], [])
testtargets("SQLite3", "sqlite3", ["basic", "tmacro"], [], ["dist" / "sqlite3.dll", "src" / "sqlite3" / "*.nim"])
testtargets("FuncHook", "funchook", ["simple"], [], ["dist" / "funchook.dll", "src" / "funchook" / "*.nim"])

target "dist":
  fake = true
  clean:
    rm target
  receipt:
    mkdir target

target "dist" / "chakra.dll":
  dep "dist"
  generateNimSource("src" / "chakra", "chakra"):
    pattern "*.cpp"
    pattern "*.nim"
  clean:
    rm cache
    rm target
  receipt:
    absolute main
    absolute target
    absolute cache
    withDir "src":
      nimExec target, cache, main, "--app:lib -d:chakra"

downloadTask(tmpdir / "chakra-core", "chakra-core.zip", "ChakraCoreRelease")

target tmpdir / "chakra-core" / "x64_release" / "ChakraCore.dll":
  lazy = true
  main = tmpdir / "chakra-core" / "chakra-core.zip"
  output tmpdir / "chakra-core" / "x64_release" / "ChakraCore.pdb"
  receipt:
    withDir tmpdir / "chakra-core":
      exec "tar xf chakra-core.zip"

target "chakra-core":
  fake = true
  depCopy(tmpdir / "chakra-core" / "x64_release" / "ChakraCore.dll", "dist" / "ChakraCore.dll")
  depCopy(tmpdir / "chakra-core" / "x64_release" / "ChakraCore.pdb", "dist" / "ChakraCore.pdb")
  clean:
    rm tmpdir / "chakra-core"
  receipt: discard

target "chakra":
  fake = true
  dep "chakra-core"
  dep "dist" / "chakra.dll"
  dep "dist" / "funchook.dll"
  receipt: discard

downloadTask("dist", "msdia140.dll", "MSDiaSDK")

target "dist" / "pdbparser.exe":
  dep "dist"
  generateNimSource("src" / "pdbparser", "parser"):
    pattern "*.nim"
  depIt: walkPattern "src" / "interop" / "*.nim"
  depIt: walkPattern "src" / "sqlite3" / "*.nim"
  dep "dist" / "msdia140.dll"
  clean:
    rm cache
    rm target
  receipt:
    absolute main
    absolute target
    absolute depinc
    absolute cache
    withDir "src":
      nimExec target, cache, main, "--app:console --cincludes:$1" % [depinc]

target "pdbparser":
  fake = true
  dep "dist" / "pdbparser.exe"
  cleanDep "dist" / "pdbparser.exe"
  receipt: discard

downloadTask(tmpdir / "sqlite3", "sqlite3.zip", "SQLite3")

target "sqlite3":
  fake = true
  main = "dist" / "sqlite3.dll"
  receipt: discard

target tmpdir / "FuncHook" / "CMakeCache.txt":
  main = "deps" / "funchook" / "CMakeLists.txt"
  receipt:
    let tgt = tmpdir / "FuncHook"
    let src = "deps" / "funchook"
    exec "cmake -B $1 $2" % [tgt, src]

target tmpdir / "FuncHook" / "MinSizeRel" / "funchook.dll":
  main = tmpdir / "FuncHook" / "CMakeCache.txt"
  receipt:
    withDir tmpdir / "FuncHook":
      exec "cmake --build . --config MinSizeRel"

target "dist" / "funchook.dll":
  main = tmpdir / "FuncHook" / "MinSizeRel" / "funchook.dll"
  receipt:
    cp(main, target)

target "dist" / "demomod.dll":
  dep "dist"
  generateNimSource("src" / "chakra" / "demomod", "demo"):
    pattern "*.nim"
  depIt: walkPattern "src" / "chakra" / "*.nim"
  receipt:
    absolute main
    absolute target
    absolute cache
    withDir "src":
      nimExec target, cache, main, "--app:lib"
    updateVersion target, "0.0.1.0"

target "dist" / "ezmgr.exe":
  dep "dist"
  generateNimSource("src" / "ezmgr", "config"):
    pattern "*.nim"
  depIt: walkPattern "src" / "xmlcfg" / "*.nim"
  receipt:
    absolute main
    absolute target
    absolute cache
    withDir "src":
      nimExec target, cache, main, "--app:console"

default "chakra"

handleCLI()