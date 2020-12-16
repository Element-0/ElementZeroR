import unittest
import sugar
import interop/[vector, string]

{.compile:"test.cpp".}

proc printintvec(vec: sink CppVector[int32]) {.importc.}
proc printintvecref(vec: ref CppVector[int32]) {.importc.}
proc returnintvec(): CppVector[int32] {.importc.}
proc printstrvec(vec: CppVector[CppString]) {.importc.}

suite "Vector":
  test "Nim -> c++ (int)":
    var vec = initCppVector([1i32, 2, 5])
    echo "len: ", vec.len
    for item in vec.toOpenArray():
      echo item
    printintvec(vec)

  test "C++ -> Nim (int)":
    for item in returnintvec():
      echo item

  test "Add, collect":
    let tmp = collect(initCppVector(5)):
      for i in 0i32..<5i32:
        i
    printintvec(tmp)

  test "Simple ref":
    var vec = newCppVector([1i32, 2, 5])
    echo "len: ", vec.len
    for item in vec.toOpenArray():
      echo item
    printintvecref(vec)

  test "String vector":
    var vec = initCppVector[CppString]([toCppString"123"])
    vec.add "test"
    printstrvec(vec)