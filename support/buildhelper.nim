import nimake
import os
import sugar

var testscategories: seq[string]

proc testtargets*(
  subname: string,
  subfolder: string,
  deps, extra, external: openarray[string]
) =
  testscategories.add subfolder
  var targets: seq[string]
  for x in deps:
    let tmp = tmpdir / "tests" / subfolder / x.toExe()
    let tmpcache = tmpdir / "tests" / subfolder / "nimcache"
    let tmpname = subname & " test: " & x
    let tmprun = "test_" & subfolder & "_" & x
    let tmprunname = tmpname & " run"
    let src = "tests" / subfolder / (x & ".nim")
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
            exec "nim c -o:$1 --path:$2 --nimcache:$3 $4" % [
              target, src, tmpcache, main]

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

target "test":
  fake = true
  for cate in testscategories:
    dep "test_" & cate
    cleanDep tmpdir / "tests" / cate
  clean: rm tmpdir / "tests"
  receipt:
    echo "$1".colorfmt {"Test finished": fgGreen}

template generateNimSource*(base, mainsrc: string, body: untyped): untyped =
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

template nimExec*(target, cache, main, extra: string) =
  exec nimGenExec(target, cache, main, extra)

template downloadTask*(basename, filename, field: string) =
  target basename / filename:
    dep cfgfile
    lazy = true
    receipt:
      mkdir basename
      let url = cfg.getSectionValue("Dependencies", field)
      echo "Downloading $1 from $2".colorfmt [(filename, bold), (url, fgYellow)]
      exec "curl -#Lo " & (basename / filename) & " " & url

template depCopy*(src, dest: static[string]): untyped =
  target dest:
    lazy = true
    main = src
    receipt:
      cp src, dest
  dep dest
