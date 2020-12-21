import unittest
import interop/cppstr

{.compile:"test.cpp".}

proc printstr(str: sink CppString) {.importc.}
proc printstrref(str: ref CppString) {.importc.}
proc printstrconstref(str: ref CppString) {.importc.}
proc returnstr(): CppString {.importc.}
proc returnlongstr(): CppString {.importc.}

suite "Basic usage":
  test "Create":
    echo initCppString("test init")
    echo newCppString("test new")

  test "Simple print":
    printstr("test")
  test "Ref print":
    var str = newCppString("test ref")
    printstr(str[])
    printstrref(str)
    printstrconstref(str)

    printstrref("test refg 2")

  test "Long print":
    printstr("testtesttesttesttesttesttesttesttestteststest")
    printstrconstref("testtesttesttesttesttesttesttest")

  # # test "Get string":
  # #   echo returnstr()
  # #   echo returnlongstr()

  # test "Advance":
  #   printstr returnstr()
  #   printstr returnlongstr()
  #   printstrref returnlongstr()
  #   printstrconstref returnlongstr()