import nimake
import sugar
import os
import parsecfg

setCurrentDir getProjectDir()

const depinc = "deps" / "include"
const cfgfile = "config.inf"
let cfg = loadConfig cfgfile

var testscategories: seq[string]

proc testtargets(subname: string, subfolder: string, deps: openarray[string], extra: openarray[string]) =
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
    capture src, extra:
      target tmprun:
        name = tmprunname
        dep tmp
        fake = true
        receipt:
          echo "here"
          withDir tmpdir / "tests" / subfolder:
            exec xexe
      target tmp:
        name = tmpname
        dep tmpdir / "tests" / subfolder
        for ex in extra:
          dep "tests" / subfolder / ex
        main = src
        clean:
          rm target
          rm target[0..^5] & ".pdb"
        receipt:
          withDir "tests":
            let rtarget = target.relativePath "tests"
            let rmain = main.relativePath "tests"
            let xsrc = "src".relativePath "tests"
            exec &"nim c -o:{rtarget} --path:{xsrc} --nimcache:{tmpcache} {rmain}"

  target tmpdir / "tests" / subfolder:
    fake = true
    for x in targets:
      cleanDep x
    clean: rm target
    receipt: mkdir target

  target "test_" & subfolder:
    name = &"{subname} test"
    fake = true
    for x in targets:
      dep x
    receipt:
      echo fgGreen &"{name} done"

testtargets("C++ Interop", "interop", ["tcppstr", "tcppvector"], ["test.cpp"])
testtargets("NT Internal API", "ntapi", ["ttransaction"], [])

target "test":
  fake = true
  for cate in testscategories:
    dep "test_" & cate
    cleanDep tmpdir / "tests" / cate
  clean: rm tmpdir / "tests"
  receipt:
    echo "Test finished".fgGreen

template generateNimSource(base, mainsrc: string, body: untyped): untyped =
  let cache {.inject.} = tmpdir / base
  block:
    main = base / (mainsrc & ".nim")
    template pattern(pat: string): untyped =
      depIt: walkPattern base / pat
    body
    deps.excl main

proc nimGenExec(target, cache, main, extra: string): string =
  &"nim c -o:{target} {extra} --nimcache:{cache} {main}"

template nimExec(target, cache, main, extra: string) =
  let xtarget = target
  let xcache = cache
  let xmain = main
  let xextra = extra
  exec nimGenExec(xtarget, xcache, xmain, xextra)

target "dist" / "chakra.dll":
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
      nimExec target, cache, main, "--app:lib"

template downloadTask(basename, filename, field: string) =
  target basename / filename:
    dep cfgfile
    lazy = true
    receipt:
      mkdir basename
      let url = cfg.getSectionValue("Dependencies", field)
      echo "Downloading ", filename," from ", url.fgYellow
      exec "curl -#Lo " & (basename / filename) & " " & url

downloadTask(tmpdir / "chakra-core", "chakra-core.zip", "ChakraCoreRelease")

target tmpdir / "chakra-core" / "x64_release" / "ChakraCore.dll":
  lazy = true
  main = tmpdir / "chakra-core" / "chakra-core.zip"
  receipt:
    withDir tmpdir / "chakra-core":
      exec &"tar xf chakra-core.zip"

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
  receipt: discard

target "chakra":
  fake = true
  dep "chakra-core"
  dep "dist" / "chakra.dll"
  receipt: discard

downloadTask("dist", "msdia140.dll", "MSDiaSDK")

target "dist" / "pdbparser.exe":
  generateNimSource("src" / "pdbparser", "parser"):
    pattern "*.nim"
  depIt: walkPattern "src" / "interop" / "*.nim"
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
      nimExec target, cache, main, &"--app:console --cincludes:{depinc}"

target "pdbparser":
  fake = true
  dep "dist" / "pdbparser.exe"
  cleanDep "dist" / "pdbparser.exe"
  receipt: discard

default "chakra"

handleCLI()