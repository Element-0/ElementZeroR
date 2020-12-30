import strutils
import os
import nimake

{.used.}

template extractSqlite3(filename: static string): untyped =
  target tmpdir / "sqlite3" / filename:
    main = tmpdir / "sqlite3" / "sqlite3.zip"
    receipt:
      withDir tmpdir / "sqlite3":
        relative main
        exec "tar xOf $1 */$2 > $2" % [main, filename]

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
