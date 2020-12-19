import ../utils

const sqlite3dll = "sqlite3.dll"

type RawDatabase* = object
type RawStatement* = object
type RawValue* = object

type Database* = object
  raw*: ptr RawDatabase

type Statement* = object
  raw*: ptr RawStatement

type ResultCode* {.pure.} = enum
  sr_ok = 0,
  sr_error = 1,
  sr_internal = 2,
  sr_perm = 3,
  sr_abort = 4,
  sr_busy = 5,
  sr_locked = 6,
  sr_nomem = 7,
  sr_readonly = 8,
  sr_interrupt = 9,
  sr_ioerr = 10,
  sr_corrupt = 11,
  sr_notfound = 12,
  sr_full = 13,
  sr_cantopen = 14,
  sr_protocol = 15,
  sr_empty = 16,
  sr_schema = 17,
  sr_toobig = 18,
  sr_constraint = 19,
  sr_mismatch = 20,
  sr_misuse = 21,
  sr_nolfs = 22,
  sr_auth = 23,
  sr_format = 24,
  sr_range = 25,
  sr_notadb = 26,
  sr_notice = 27,
  sr_warning = 28,
  sr_row = 100,
  sr_done = 101,
  sr_ok_load_permanently = 256,

type SQLiteError* = object of IOError

proc newSQLiteError(code: ResultCode): ref SQLiteError =
  newException(SQLiteError, $code)

type OpenFlag* {.pure.} = enum
  so_readonly,
  so_readwrite,
  so_create,
  so_delete_on_close,
  so_exclusive,
  so_auto_proxy,
  so_uri,
  so_memory,
  so_main_db,
  so_temp_db,
  so_transient_db,
  so_main_journal,
  so_temp_journal,
  so_subjournal,
  so_super_journal,
  so_no_mutex,
  so_full_mutex,
  so_shared_cache,
  so_private_cache,
  so_wal,
  so_no_follow = 25

type OpenFlags* = set[OpenFlag]

type PrepareFlag* = enum
  sp_persistent,
  sp_normalize,
  sp_no_vtab

type PrepareFlags* = set[PrepareFlag]

type DatabaseEncoding* = enum
  enc_utf8,
  enc_utf16,
  enc_utf16be,
  enc_utf16le,

type SqliteDestroctor* = proc (p: pointer) {.cdecl.}

const StaticDestructor* = cast[SqliteDestroctor](0)
const TransientDestructor* = cast[SqliteDestroctor](-1)

{.push dynlib: sqlite3dll.}
proc sqlite3_open_v2*(filename: cstring, db: ptr ptr RawDatabase, flags: OpenFlags, vfs: cstring): ResultCode {.importc.}
proc sqlite3_close_v2*(db: ptr RawDatabase): ResultCode {.importc.}
proc sqlite3_prepare_v3*(db: ptr RawDatabase, sql: cstring, nbyte: int, flags: PrepareFlags, pstmt: ptr ptr RawStatement, tail: ptr cstring): ResultCode {.importc.}
proc sqlite3_finalize*(st: ptr RawStatement): ResultCode {.importc.}
proc sqlite3_step*(st: ptr RawStatement): ResultCode {.importc.}
proc sqlite3_bind_blob64*(st: ptr RawStatement, idx: int, buffer: pointer, len: int, free: SqliteDestroctor): ResultCode {.importc.}
proc sqlite3_bind_double*(st: ptr RawStatement, idx: int, value: float64): ResultCode {.importc.}
proc sqlite3_bind_int64*(st: ptr RawStatement, idx: int, val: int64): ResultCode {.importc.}
proc sqlite3_bind_null*(st: ptr RawStatement, idx: int): ResultCode {.importc.}
proc sqlite3_bind_text64*(st: ptr RawStatement, idx: int, val: cstring, len: int, free: SqliteDestroctor, encoding: DatabaseEncoding): ResultCode {.importc.}
proc sqlite3_bind_value*(st: ptr RawStatement, idx: int, val: ptr RawValue): ResultCode {.importc.}
proc sqlite3_bind_pointer*(st: ptr RawStatement, idx: int, val: pointer, name: cstring, free: SqliteDestroctor): ResultCode {.importc.}
proc sqlite3_bind_zeroblob64*(st: ptr RawStatement, idx: int, len: int): ResultCode {.importc.}
proc sqlite3_changes*(st: ptr RawDatabase): int {.importc.}
{.pop.}

template check_sqlite(res: ResultCode) =
  let tmp = res
  if tmp != sr_ok:
    raise newSQLiteError tmp

proc `=destroy`*(db: var Database) =
  if db.raw != nil:
    check_sqlite sqlite3_close_v2 db.raw

disallow_copy Database

proc `=destroy`*(st: var Statement) =
  if st.raw != nil:
    check_sqlite sqlite3_finalize st.raw

disallow_copy Statement

proc initDatabase*(
  filename: string,
  flags: OpenFlags = { so_readwrite, so_create },
  vfs: cstring = nil
): Database {.genrefnew.} =
  check_sqlite sqlite3_open_v2(filename, addr result.raw, flags, vfs)

proc changes*(st: var Database): int {.genref.} =
  sqlite3_changes st.raw

proc initStatement*(db: var Database | var ref Database, sql: string, flags: PrepareFlags = {}): Statement {.genrefnew.} =
  check_sqlite sqlite3_prepare_v3(db.raw, sql, sql.len, flags, addr result.raw, nil)

proc `[]=`*(st: var Statement, idx: int, blob: openarray[byte]) {.genref.} =
  check_sqlite sqlite3_bind_blob64(st.raw, idx, blob.unsafeAddr, blob.len, TransientDestructor)

proc `[]=`*(st: var Statement, idx: int, val: float | float32 | float64) {.genref.} =
  check_sqlite sqlite3_bind_double(st.raw, idx, float64 val)

proc `[]=`*(st: var Statement, idx: int, val: int | int32 | int64 | int16 | int8 | uint8 | uint16 | uint32 | uint64) {.genref.} =
  check_sqlite sqlite3_bind_double(st.raw, idx, cast[int64](val))

proc `[]=`*(st: var Statement, idx: int, val: type(nil)) {.genref.} =
  check_sqlite sqlite3_bind_null(st.raw, idx)

proc `[]=`*(st: var Statement, idx: int, val: string) {.genref.} =
  check_sqlite sqlite3_bind_text64(st.raw, idx, val, val.len, TransientDestructor, enc_utf8)

proc step*(st: var Statement): bool {.genref.} =
  let res = sqlite3_step(st.raw)
  case res:
  of sr_row: true
  of sr_done: false
  else: raise newSQLiteError(res)