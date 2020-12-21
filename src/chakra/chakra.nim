{.compile: "forward.cpp".}

import interop/cppstr

import importmc
import hookmc
import funchook/funchook

proc getServerVersionString(): CppString {.hookmc: "?getServerVersionString@Common@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@XZ".} =
  return $getServerVersionString_origin() & " with EZR"

applyHooks()