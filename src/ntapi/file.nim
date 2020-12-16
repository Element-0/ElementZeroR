import winim/inc/windef
import handle
import checked
import shared
import ../utils

{.push dynlib: ntdll.}
proc NtCreateTransaction(
  handle: ptr HANDLE,
  access: int,
  attributes: ptr OBJECT_ATTRIBUTES,
  uow: int,
  tmHandle: int,
  createOptions: int,
  isolationLevel: int,
  isolationFlags: int,
  timeout: int,
  desc: int,
): NTSTATUS {.importc.}

proc NtRollbackTransaction(
  handle: HANDLE,
  wait: bool
): NTSTATUS {.importc.}

proc NtCommitTransaction(
  handle: HANDLE,
  wait: bool
): NTSTATUS {.importc.}
{.pop.}

type NtTransaction = distinct SafeHandle

proc handle(self: var NtTransaction): var HANDLE =
  SafeHandle(self).handle
proc handle*(self: NtTransaction): HANDLE {.genref.} =
  SafeHandle(self).handle

proc initNtTransaction*(): NtTransaction {.genrefnew.} =
  var tmp: OBJECT_ATTRIBUTES
  InitializeObjectAttributes(addr tmp, nil, 0, 0, nil)
  NtChecked "Failed to create transaction":
    NtCreateTransaction(addr result.handle, 0x12003F, addr tmp,0, 0, 0, 0, 0, 0, 0)

proc rollback*(self: var NtTransaction) {.genref.} =
  NtChecked "Failed to rollback transaction":
    NtRollbackTransaction(self.handle, true)

proc commit*(self: var NtTransaction) {.genref.} =
  NtChecked "Failed to commit transaction":
    NtCommitTransaction(self.handle, true)