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