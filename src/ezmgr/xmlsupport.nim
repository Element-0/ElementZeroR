import htmlparser, times

import xmlio
import xmlio/typeid_default
import vtable

{.used.}

registerTypeId Time, "adab4eca-ff25-44ee-bfb9-96c9d4c91377"

const timeformat = "yyyy-MM-dd'T'HH:mm:sszzz"

buildTypedAttributeHandler Time:
  self.proxy[] = parseTime(self.cache, timeformat, local())

type ModVersion* = object of RootObj
  code*: int64
  name*: string

template checkField*(f: untyped, str: static string, cond: untyped) =
  const es = astToStr(f) & " " & str
  if cond: raise newException(ValueError, es)

generateXmlElementHandler ModVersion, "c376ff1a-ec98-4ada-8016-5923a0d13b6c":
  checkField name, "is empty": self.name.len == 0