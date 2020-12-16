import nimake
import sugar
import os
import parsecfg

setCurrentDir getProjectDir()

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

target "dist" / "chakra.dll":
  main = "src" / "chakra" / "chakra.nim"
  depIt: walkPattern "src" / "chakra" / "*.cpp"
  depIt: walkPattern "src" / "chakra" / "*.nim"
  deps = deps.filterIt(it != main)
  let cache = tmpdir / "src" / "chakra"
  clean:
    rm cache
    rm target
  receipt:
    withDir "src":
      let rmain = main.relativePath "src"
      let rtarget = target.relativePath "src"
      let rcache = cache.relativePath "src"
      exec &"nim c -o:{rtarget} --app:lib --nimcache:{rcache} {rmain}"

target tmpdir / "chakra-core" / "chakra-core.zip":
  dep cfgfile
  lazy = true
  receipt:
    mkdir tmpdir / "chakra-core"
    let url = cfg.getSectionValue("Dependencies", "ChakraCoreRelease")
    echo "Downloading chakracore from ", url.fgYellow
    exec &"curl -#Lo {target} {url}"

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

default "chakra"

handleCLI()