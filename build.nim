import nimake
import sugar
import os
import parsecfg

setCurrentDir getProjectDir()

const depinc = "deps" / "include"
const cfgfile = "config.inf"
let cfg = loadConfig cfgfile

var testscategories: seq[string]

proc testtargets(subname: string, subfolder: string, deps, extra, external: openarray[string]) =
  testscategories.add subfolder
  var targets: seq[string]
  for x in deps:
    let tmp = tmpdir / "tests" / subfolder / x.toExe()
    let tmpcache = tmpdir / "tests" / subfolder / "nimcache"
    let tmpname = subname & " test: " & x
    let tmprun = "test_" & subfolder & "_" & x
    let tmprunname = tmpname & " run"
    let src = "tests" / subfolder / ( x & ".nim")
    let xexe = x.toExe()
    targets.add tmprun
    capture xexe, src, extra, external:
      target tmprun:
        name = tmprunname
        dep tmp
        fake = true
        receipt:
          let dist = "dist".absolutePath
          putEnv "PATH", dist & ";" & getEnv("PATH")
          withDir tmpdir / "tests" / subfolder:
            exec xexe
      target tmp:
        name = tmpname
        dep tmpdir / "tests" / subfolder
        for ex in extra:
          dep "tests" / subfolder / ex
        for ex in external:
          if ex.contains "*":
            depIt walkPattern ex
          else:
            dep ex
        main = src
        clean:
          rm target
          rm target[0..^5] & ".pdb"
        receipt:
          absolute target
          absolute main
          absolute src
          absolute tmpcache
          withDir "tests":
            exec "nim c -o:$1 --path:$2 --nimcache:$3 $4" % [target, src, tmpcache, main]

  target tmpdir / "tests" / subfolder:
    fake = true
    for x in targets:
      cleanDep x
    clean: rm target
    receipt: mkdir target

  target "test_" & subfolder:
    name = "$1 test" % [subname]
    fake = true
    for x in targets:
      dep x
    receipt:
      echo "$1 done" % [name]

testtargets("C++ Interop", "interop", ["tcppstr", "tcppvector"], ["test.cpp"], [])
testtargets("NT Internal API", "ntapi", ["ttransaction"], [], [])
testtargets("SQLite3", "sqlite3", ["basic", "tmacro"], [], ["dist" / "sqlite3.dll", "src" / "sqlite3" / "*.nim"])
testtargets("FuncHook", "funchook", ["simple"], [], ["dist" / "funchook.dll", "src" / "funchook" / "*.nim"])

target "test":
  fake = true
  for cate in testscategories:
    dep "test_" & cate
    cleanDep tmpdir / "tests" / cate
  clean: rm tmpdir / "tests"
  receipt:
    echo "$1".colorfmt { "Test finished": fgGreen }

target "dist":
  fake = true
  clean:
    rm target
  receipt:
    mkdir target

template generateNimSource(base, mainsrc: string, body: untyped): untyped =
  let cache {.inject.} = tmpdir / base
  block:
    main = base / (mainsrc & ".nim")
    template pattern(pat: string): untyped =
      depIt: walkPattern base / pat
    body
    deps.excl main

proc nimGenExec(target, cache, main, extra: string): string =
  let xcolor = if colorMode():
    "--colors:on"
  else:
    "--colors:off"
  "nim c -o:$1 $2 $3 --nimcache:$4 $5" % [target, extra, xcolor, cache, main]

template nimExec(target, cache, main, extra: string) =
  exec nimGenExec(target, cache, main, extra)

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

template downloadTask(basename, filename, field: string) =
  target basename / filename:
    dep cfgfile
    lazy = true
    receipt:
      mkdir basename
      let url = cfg.getSectionValue("Dependencies", field)
      echo "Downloading $1 from $2".colorfmt [(filename, bold), (url, fgYellow)]
      exec "curl -#Lo " & (basename / filename) & " " & url

downloadTask(tmpdir / "chakra-core", "chakra-core.zip", "ChakraCoreRelease")

target tmpdir / "chakra-core" / "x64_release" / "ChakraCore.dll":
  lazy = true
  main = tmpdir / "chakra-core" / "chakra-core.zip"
  output tmpdir / "chakra-core" / "x64_release" / "ChakraCore.pdb"
  receipt:
    withDir tmpdir / "chakra-core":
      exec "tar xf chakra-core.zip"

template depCopy(src, dest: static[string]): untyped =
  target dest:
    lazy = true
    main = src
    receipt:
      cp src, dest
  dep dest

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

template extractSqlite3(filename: string): untyped =
  target tmpdir / "sqlite3" / filename:
    main = tmpdir / "sqlite3" / "sqlite3.zip"
    receipt:
      withDir tmpdir / "sqlite3":
        relative main
        exec "tar xOf $1 */$2 > $2".format(main, filename)

extractSqlite3("sqlite3.c")
extractSqlite3("sqlite3ext.h")
extractSqlite3("sqlite3.h")

target "dist" / "sqlite3.dll":
  dep "dist"
  output "dist" / "sqlite3.lib"
  main = tmpdir / "sqlite3" / "sqlite3.c"
  dep "src" / "sqlite3" / "sqlite3init.c"
  const defs = [
    "SQLITE_API=__declspec(dllexport)",
    "SQLITE_DQS=0",
    "SQLITE_THREADSAFE=0",
    "SQLITE_DEFAULT_MEMSTATUS=0",
    "SQLITE_DEFAULT_WAL_SYNCHRONOUS=1",
    "SQLITE_LIKE_DOESNT_MATCH_BLOBS=1",
    "SQLITE_MAX_EXPR_DEPTH=0",
    "SQLITE_OMIT_DEPRECATED",
    "SQLITE_OMIT_PROGRESS_CALLBACK",
    "SQLITE_OMIT_SHARED_CACHE",
    "SQLITE_USE_ALLOCA",
    "SQLITE_OMIT_AUTOINIT",
    "SQLITE_OMIT_DEPRECATED",
    "SQLITE_WIN32_MALLOC",
    "SQLITE_ENABLE_FTS5",
    "SQLITE_ENABLE_JSON1",
    "SQLITE_ENABLE_RTREE",
    "SQLITE_ENABLE_SNAPSHOT",
    "SQLITE_DISABLE_LFS",
    "SQLITE_DISABLE_DIRSYNC",
  ]
  receipt:
    let csrc = deps.toSeq.filterIt(it.endsWith ".c").join(" ")
    let diacolor = if colorMode():
      "-fcolor-diagnostics"
    else:
      "-fno-color-diagnostics"
    exec "clang-cl /LD /MD /O2 /Qvec /Fe$1 $2 -Wno-deprecated-declarations $3 $4 $5" % [
      target,
      diacolor,
      main,
      csrc,
      defs.mapIt("/D " & it).join(" ")
    ]

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

default "chakra"

handleCLI()