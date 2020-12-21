import bindings
import utils

type FuncHook* = object
  raw: ptr RawFuncHook

type FuncHookError* = object of ValueError

template check_result(res: HookResult) =
  let re = res
  if re != HookResult.hk_success:
    raise newException(FuncHookError, $re)

proc `=destroy`*(fh: var FuncHook) =
  if fh.raw != nil:
    check_result fh.raw.funchook_destroy()

proc `=copy`*(self: var FuncHook, rhs: FuncHook) {.error.}

proc initFuncHook*(): FuncHook {.genrefnew.} =
  result.raw = funchook_create()
  if result.raw == nil:
    raise newException(FuncHookError, "Failed to create funchook instance")

proc hook*[T](hk: var FuncHook, target: T, hooked: T): T {.genref.} =
  result = target
  check_result funchook_prepare(hk.raw, cast[ptr pointer](addr result), hooked)

proc install*(hk: var FuncHook) {.genref.} =
  check_result funchook_install(hk.raw, 0)

proc uninstall*(hk: var FuncHook) {.genref.} =
  check_result funchook_uninstall(hk.raw, 0)