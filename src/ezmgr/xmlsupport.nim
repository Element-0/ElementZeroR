import xmlio/typeid_default

{.used.}

template checkField*(f: untyped, str: static string, cond: untyped) =
  const es = astToStr(f) & " " & str
  if cond: raise newException(ValueError, es)