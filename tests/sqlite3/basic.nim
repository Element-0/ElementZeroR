import unittest

import sqlite3/sqlite3

suite "Basic bindings":
  test "Open memory db":
    let db = initDatabase ":memory:"
    discard db

  test "Create prepared stmt":
    var db = initDatabase ""
    var st = db.initStatement("CREATE TABLE test(id)")
    discard st

  test "Insert and count changes":
    var db = initDatabase ""
    var createtable = db.initStatement("CREATE TABLE test(id)")
    check createtable.step() == false
    var insertdata = db.initStatement("INSERT INTO test VALUES (1)")
    check insertdata.step() == false
    check db.changes == 1