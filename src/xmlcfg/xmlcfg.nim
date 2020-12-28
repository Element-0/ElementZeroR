import tables, strutils, dynlib, strscans
import xmlio
import vtable

type ConfigXmlRegistry = object of RootObj
  nsmap: Table[string, ref XmlnsHandler]

proc loadNs(value: string)

impl ConfigXmlRegistry, XmlnsRegistry:
  method resolveProcessInstruction*(self: ref ConfigXmlRegistry, key, value: string) =
    case key:
    of "import":
      loadNs(value.strip())
    else:
      discard
    # ignore unknown
  method resolveXmlns*(self: ref ConfigXmlRegistry, name: string): ref XmlnsHandler =
    self.nsmap[name]

var registry = new ConfigXmlRegistry
registry.nsmap = initTable[string, ref XmlnsHandler] 16

proc registerXmlns*(name: string, handler: ref XmlnsHandler) =
  registry.nsmap[name] = handler

type
  FnProvideXmlns = proc (): ref XmlnsHandler {.nimcall.}

proc loadNs(value: string) =
  var name, libname: string
  if value.scanf("""name="$+"$spath="$+"$.""", name, libname):
    let lib = loadLibPattern(libname)
    if lib == nil:
      raise newException(OSError, "cannot load library")
    let f = cast[FnProvideXmlns](lib.checkedSymAddr("provideXmlns"))
    registerXmlns(name, f())
  else:
    raise newException(ValueError, "invalid import format")

let root* = toXmlnsRegistry registry