import unittest

import sqlite3/sqlite3

suite "Basic bindings":
  setup:
    var db {.used.} = initDatabase ""

  test "Open memory db":
    check true

  test "Create prepared stmt":
    var st = db.initStatement("CREATE TABLE test(id)")
    discard st

  test "Insert and count changes":
    var createtable = db.initStatement("CREATE TABLE test(id)")
    check createtable.step() == false
    var insertdata = db.initStatement("INSERT INTO test VALUES (?)")
    insertdata[1] = 123
    check insertdata.step() == false
    check insertdata.changes == 1

  test "Complete test":
    var createtable = db.initStatement("CREATE TABLE test(id INTEGER PRIMARY KEY, value TEXT)")
    check createtable.step() == false
    checkpoint "created db"
    block:
      var st = db.fetchStatement("INSERT INTO test (value) VALUES (?)")
      st[1] = "test"
      check st.step() == false
      check db.changes == 1
    checkpoint "inserted data"
    block:
      var st = db.initStatement("SELECT * FROM test")
      check st.step()
      check st.getColumn(0, int) == 1
      check st.getColumn(1, string) == "test"
      check st.step() == false
      checkpoint "query first"
      # test auto reset
      check st.step()
      check st.getColumn(0, int) == 1
      check st.getColumn(1, string) == "test"
      check st.step() == false
      checkpoint "query second"