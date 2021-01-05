import funchook/funchook

when defined(chakra):
  var ctx = newFuncHook()

  proc applyHooks*() =
    ctx.install()

  proc getHookContext*(): ref FuncHook {.exportc, dynlib.} =
    return ctx
else:
  proc applyHooks*() = discard # placeholder for ide
  proc getHookContext*(): ref FuncHook {.importc, dynlib: "chakra.dll".}
