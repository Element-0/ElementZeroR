import os, tables, strutils

import winim/lean

import ../hookos

{.used.}

let appdata = getAppDir()
let workdir = absolutePath getCurrentDir()
let apphandle = CreateFile(appdata, GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0)

proc relative(x: string): string = relativePath(x, workdir)
proc basepath(x: string): string = x.split('\\', 2)[0]

proc MySetCurrentDirectoryA(s: cstring): bool
    {.stdcall, hookos(r"kernelbase.dll", r"SetCurrentDirectoryA").} = discard

type MapStrategy = enum
  ms_instance
  ms_asset
  ms_temp
  ms_null

let filemap = {
  "behavior_packs": ms_asset,
  "resource_packs": ms_asset,
  "definitions": ms_asset,
  "data": ms_asset,
  "world_templates": ms_instance,
  "development_behavior_packs": ms_instance,
  "development_resource_packs": ms_instance,
  "development_skin_packs": ms_instance,
  "internalStorage": ms_instance,
  "worlds": ms_instance,
  "server.properties": ms_instance,
  "permissions.json": ms_instance,
  "whitelist.json": ms_instance,
  "invalid_known_packs.json": ms_temp,
  "valid_known_packs.json": ms_temp,
  "ops.json": ms_null,
}.toTable()

proc realPath(attr: OBJECT_ATTRIBUTES): string =
  if attr.RootDirectory != 0:
    var buffer: array[4096, WCHAR]
    let len = GetFinalPathNameByHandle(
      attr.RootDirectory,
      cast[LPWSTR](addr buffer),
      4095,
      FILE_NAME_NORMALIZED)
    assert len > 8
    result =
      $$cast[LPWSTR](cast[int](addr buffer) + 8) / $attr.ObjectName.Buffer
  else:
    result = $attr.ObjectName.Buffer
    if result.startsWith(r"\??\") and result[5] == ':':
      result = relative result.substr(4)
    elif result.startsWith(r"\"):
      return
  result = relative result

proc fixupPath[TAG: static string](objectAttributes: POBJECT_ATTRIBUTES) =
  let brel = realPath(objectAttributes[])
  if brel[0] in {'.', '\\'} or isAbsolute(brel):
    return
  case filemap.getOrDefault(basepath brel):
  of ms_asset:
    let buffer = +$brel
    var tmp: UNICODE_STRING
    RtlInitUnicodeString(addr tmp, buffer)
    objectAttributes[].RootDirectory = apphandle
    objectAttributes[].ObjectName = addr tmp
  else:
    discard

proc NtCreateFile(
  phandle: PHANDLE;
  access: ACCESS_MASK;
  objectAttributes: POBJECT_ATTRIBUTES;
  ioStatusBlock: PIO_STATUS_BLOCK;
  allocationSize: int64;
  fileAttributes, shareAccess, createDisposition, createOptions: int32;
  eaBuffer: ptr UncheckedArray[byte];
  eaLength: int32;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtCreateFile").} =
  fixupPath["CREATE"](objectAttributes)
  NtCreateFile_origin(
    phandle,
    access,
    objectAttributes,
    ioStatusBlock,
    allocationSize,
    fileAttributes,
    shareAccess,
    createDisposition,
    createOptions,
    eaBuffer,
    eaLength
  )

proc NtOpenFile(
  phandle: PHANDLE;
  access: ACCESS_MASK;
  objectAttributes: POBJECT_ATTRIBUTES;
  ioStatusBlock: PIO_STATUS_BLOCK;
  shareAccess, openOptions: int32;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtOpenFile").} =
  fixupPath["OPEN"](objectAttributes)
  NtOpenFile_origin(
    phandle,
    access,
    objectAttributes,
    ioStatusBlock,
    shareAccess,
    openOptions,
  )

proc NtDeleteFile(
  objectAttributes: POBJECT_ATTRIBUTES
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtDeleteFile").} =
  fixupPath["OPEN"](objectAttributes)
  NtDeleteFile_origin(objectAttributes)

proc NtQueryAttributesFile(
  objectAttributes: POBJECT_ATTRIBUTES;
  attributes: pointer;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtQueryAttributesFile").} =
  fixupPath["ATTR"](objectAttributes)
  NtQueryAttributesFile_origin(objectAttributes, attributes)

proc NtQueryFullAttributesFile(
  objectAttributes: POBJECT_ATTRIBUTES;
  attributes: pointer;
): NTSTATUS {.stdcall, hookos(r"ntdll.dll", r"NtQueryFullAttributesFile").} =
  fixupPath["FULLATTR"](objectAttributes)
  NtQueryFullAttributesFile_origin(objectAttributes, attributes)
