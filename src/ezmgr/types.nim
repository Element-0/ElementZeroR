import times, strutils, sugar, strscans

import xmlio
import vtable

import xmlsupport

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

buildTypedAttributeHandler seq[ModReference]:
  self.proxy[] = collect(newSeq):
    for item in split(self.cache, ';'):
      parseModReference(item)

type ModInfo* = object of RootObj
  name*: string
  author*: string
  homepage*: string
  version*: ref ModVersion
  license*: string
  updated*: Time
  dependency*: seq[ModReference]

generateXmlElementHandler ModInfo, "e20364bd-ca4c-465e-8f93-34870b34ca5f":
  checkField name, "is empty": self.name == ""
  checkField author, "is empty": self.author == ""
  checkField version, "is not set": self.version == nil
  checkField license, "is empty": self.license == ""

trait ModRepository:
  method fetchModList*(self: ref ModRepository): seq[ref ModInfo]

registerTypeId ModRepository, "661643b0-e188-4127-bb98-f39f2467a360"

export ModRepository

type InlineRepository* = object of RootObj
  children: seq[ref ModInfo]

impl InlineRepository, ModRepository:
  method fetchModList*(self: ref InlineRepository): seq[ref ModInfo] =
    self.children
