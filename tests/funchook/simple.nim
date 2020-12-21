import unittest

import funchook/funchook

proc myfunc(): int {.cdecl, locks: "unknown".} =
  checkpoint "inside origin"
  echo "hello"
  return 0

proc myhooked(): int {.cdecl, locks: "unknown".} =
  checkpoint "inside myhooked"
  echo "hooked"
  return 1

var origin: proc(): int {.cdecl, locks: "unknown".}

proc myhooked2(): int {.cdecl, locks: "unknown".} =
  {.gcsafe.}:
    checkpoint "inside myhooked2"
    echo "origin: ", cast[int](origin)
    require origin != nil
    return origin() + 2

suite "Test funchook":
  test "before hook":
    check myfunc() == 0

  test "apply myhooked":
    var ctx = initFuncHook()
    checkpoint "inited funchook instance"
    discard ctx.hook(myfunc, myhooked)
    checkpoint "before install hook"
    check myfunc() == 0
    checkpoint "install hook"
    ctx.install()
    checkpoint "after apply"
    check myfunc() == 1
    checkpoint "uninstall hook"
    ctx.uninstall()
    checkpoint "after uninstall hook"
    check myfunc() == 0

  test "apply myhooked2":
    var ctx = initFuncHook()
    checkpoint "inited funchook instance"
    origin = ctx.hook(myfunc, myhooked2)
    checkpoint "before install hook"
    check myfunc() == 0
    checkpoint "install hook"
    ctx.install()
    checkpoint "after apply"
    check myfunc() == 2
    checkpoint "uninstall hook"
    ctx.uninstall()
    checkpoint "after uninstall hook"
    check myfunc() == 0