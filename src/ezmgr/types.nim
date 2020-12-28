import strutils, sugar, strscans, asyncfutures

import xmlio
import vtable

import xmlsupport

import ../common/version_code

registerTypeId VersionCode, "1dd35952-3e97-48d2-aefa-112b305ebd92"

buildTypedAttributeHandler VersionCode, parseVersionCode

type ModReference* = object
  name*: string
  minVersion*, maxVersion*: int64

proc verifyModName(str: string) =
  for idx, ch in str:
    case ch:
    of 'a'..'z', 'A'..'Z', '.':
      discard
    of '0'..'9':
      if idx == 0: raise newException(ValueError, "illegal digit character")
      discard
    else:
      raise newException(ValueError, "illegal character")

proc parseModReference(str: string): ModReference =
  # name(1,2) or name(1) or name
  var tmp, min, max: int
  if scanf(str, "$+($i,$i)", result.name, min, max):
    result.minVersion = int64 min
    result.maxVersion = int64 max
  elif scanf(str, "$+($i)", result.name, tmp):
    result.minVersion = int64 tmp
    result.maxVersion = int64 tmp
  elif not ('-' in str):
    result.name = str
    result.minVersion = 0
    result.maxVersion = high(int64)
  else:
    raise newException(ValueError, "invalid mod reference: " & str)
  verifyModName(result.name)

registerTypeId seq[ModReference], "bd77a8a3-71ef-400d-9557-7ef77a150f10"

buildTypedAttributeHandler(seq[ModReference]) do(str: string) -> seq[ModReference]:
  collect(newSeq):
    for item in split(str, ';'):
      parseModReference(item)

trait ModSource:
  method checkVersion*(self: ref ModSource): Future[seq[int64]]
  method fetchFile*(self: ref ModSource, version: int64): Future[string]

registerTypeId(ref ModSource, "c9667691-1654-483d-afda-78c8c47abc66")

type ModInfo* = object of RootObj
  name*: string
  description*: string
  author*: string
  homepage*: string
  license*: string
  dependencies*: seq[ModReference]
  optionalDependencies*: seq[ModReference]
  sources*: seq[ref ModSource]

generateXmlElementHandler ModInfo, "e20364bd-ca4c-465e-8f93-34870b34ca5f":
  checkField name, "is empty": self.name == ""
  checkField author, "is empty": self.author == ""
  checkField license, "is empty": self.license == ""
  checkField sources, "is empty": self.sources.len == 0

trait ModRepository:
  method fetchModList*(self: ref ModRepository): Future[seq[ref ModInfo]]

registerTypeId(ref ModRepository, "661643b0-e188-4127-bb98-f39f2467a360")

export ModRepository, ModSource, toXmlElementHandler