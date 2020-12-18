import unittest

import sqlite3/sqlite3

suite "Basic bindings":
  test "Open memory db":
    let db = opendb ":memory:"
    discard db