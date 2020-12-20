import unittest

import sqlite3/sqlutils

iterator selectIds(id: int): tuple[value: string] {.importdb: "select value from test where id=$id".} = discard
proc insertPair(value: string): int {.importdb: "INSERT INTO test (value) VALUES ($value)".}
proc createTestTable() {.importdb: "CREATE TABLE test(id INTEGER PRIMARY KEY, value TEXT)".}

suite "Macro test":
  setup:
    var db {.used.} = initDatabase ""
    db.createTestTable()
    checkpoint "created db"
    block:
      var st = db.fetchStatement("INSERT INTO test (value) VALUES (?)")
      st[1] = "test"
      check st.step() == false
      check db.changes == 1
    checkpoint "inserted data"

  test "query first data":
    for x in db.selectIds(1):
      check x == (value: "test")

  test "update data":
    check 2 == db.insertPair("test2")

  test "query first data with transaction commit":
    var tran = db.initTransaction()
    check 2 == db.insertPair("test2")
    tran.commit()
    for x in db.selectIds(2):
      check x == (value: "test2")

  test "query first data with transaction rollback":
    var tran = db.initTransaction()
    check 2 == db.insertPair("test3")
    tran.rollback()
    check 2 == db.insertPair("test2")