import streams, os, asyncdispatch

import types

import xmlio
import vtable

import xmlsupport
import ../xmlcfg/xmlcfg

type Repositories* = object of RootObj
  children*: seq[ref ModRepository]

generateXmlElementHandler Repositories, "280c836f-b65f-4b20-91d3-192e407d4beb":
  discard

iterator items*(repo: ref Repositories): ref ModRepository =
  for item in repo.children:
    yield item

type InlineRepository* = object of RootObj
  children: seq[ref ModInfo]

generateXmlElementHandler InlineRepository, "735a4e32-f58e-4871-b5b9-d3267583d9f1":
  discard

impl InlineRepository, ModRepository:
  method fetchModList*(self: ref InlineRepository): Future[seq[ref ModInfo]] {.async.} =
    return self.children

type InlineFile = object of RootObj
  path: string

impl InlineFile, ModSource:
  method checkVersion*(self: ref InlineFile): Future[seq[int64]] =
    discard
  method fetchFile*(self: ref InlineFile, version: int64): Future[string] =
    discard

generateXmlElementHandler InlineFile, "b7ff682e-05d8-4a73-a7d5-1e8f144c7137":
  checkField path, "is invalid": self.path == "" or (not fileExists self.path)

let stdns* = newSimpleXmlnsHandler()
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

waitFor entry("ezmgr.xml")