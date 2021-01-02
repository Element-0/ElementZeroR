import streams, os, asyncdispatch

import winim/inc/winver
import winim/winstr

import types

import xmlio
import vtable

import ../xmlcfg/xmlcfg

declareXmlElement:
  type Repositories* {.id: "79eeea4c-9b53-4ad8-9761-3649025b6c7f".} = object of RootObj
    children*: seq[ref ModRepository]

iterator items*(repo: ref Repositories): ref ModRepository =
  for item in repo.children:
    yield item

declareXmlElement:
  type InlineRepository* {.id: "735a4e32-f58e-4871-b5b9-d3267583d9f1".} = object of RootObj
    children: seq[ref ModInfo]

impl InlineRepository, ModRepository:
  method fetchModList*(self: ref InlineRepository): Future[seq[ref ModInfo]] {.async.} =
    return self.children

proc checkFile(value: string): bool = value == "" or (not fileExists value)

declareXmlElement:
  type InlineFile {.id: "ab1d5779-c842-4ecd-b0f7-a8d0725f7b16".} = object of RootObj
    path {.check(checkFile(value), r"invalid path").}: string

impl InlineFile, ModSource:
  method checkVersion*(self: ref InlineFile): Future[seq[int64]] {.async.} =
    var size: int32
    var verhandler: int32
    size = GetFileVersionInfoSize(self.path, addr verhandler)
    if size == 0:
      return @[0i64]
    var buffer = newSeq[byte](size)
    GetFileVersionInfo(self.path, verhandler, size, addr buffer[0])
    var fixed: ptr VS_FIXEDFILEINFO
    size = int32 sizeof(VS_FIXEDFILEINFO)
    VerQueryValue(addr buffer[0], r"\", cast[ptr pointer](addr fixed), addr size)
    var ver = (int64 fixed.dwFileVersionMS) shl 32
    ver += int64 fixed.dwFileVersionLS
    return @[ver]
  method fetchFile*(self: ref InlineFile, version: int64): Future[string] {.async.} =
    discard

let stdns* = new SimpleXmlnsHandler
stdns.registerType("repositories", ref Repositories)
stdns.registerType("mod", ref ModInfo)
stdns.registerType("file", ref InlineFile, ref ModSource)
stdns.registerType("inline", ref InlineRepository, ref ModRepository)

registerXmlns("std", stdns)

proc entry(filename: string) {.async.} =
  var strs = newFileStream(filename)
  let repos = readXml(root, strs, filename, ref Repositories)
  for repo in repos:
    let list = await repo.fetchModList()
    for item in list:
      echo item[]
      for src in item.sources:
        echo await src.checkVersion()

waitFor entry("ezmgr.xml")
