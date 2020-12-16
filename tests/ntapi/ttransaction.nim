import unittest
import ntapi/[file,handle]
import winim/mean
import os

suite "test transaction":
  test "Empty test":
    discard initNtTransaction()

  test "Empty commit":
    var tran = initNtTransaction()
    tran.commit()

  test "Empty rollback":
    var tran = initNtTransaction()
    tran.rollback()

  test "Write selfexe but rollback":
    var tran = initNtTransaction()
    defer: tran.rollback()
    let file = CreateFileTransacted(
      getAppFilename() & ":temp.exe",
      GENERIC_READ or GENERIC_WRITE,
      0,
      nil,
      CREATE_ALWAYS,
      FILE_ATTRIBUTE_NORMAL,
      0,
      tran.handle,
      nil,
      nil
    ).initFromRawHandle
    let readed = readFile("C:\\Windows\\System32\\notepad.exe")
    WriteFile(file.handle, readed.cstring, DWORD readed.len, nil, nil)
