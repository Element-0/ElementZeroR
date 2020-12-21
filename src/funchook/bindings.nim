const funchook_dll = "funchook.dll"

type RawFuncHook* = object

type HookResult* {.pure.} = enum
  hk_internal_error = -1,
  hk_success = 0,
  hk_out_of_memory = 1,
  hk_already_installed = 2,
  hk_disassembly = 3,
  hk_ip_relative_offset = 4,
  hk_cannot_fix_ip_relative = 5,
  hk_found_back_jump = 6,
  hk_too_short_instructions = 7,
  hk_memory_allocation = 8,
  hk_memory_function = 9,
  hk_not_installed = 10,
  hk_no_available_registers = 11

{.push dynlib: funchook_dll.}
proc funchook_create*(): ptr RawFuncHook {.importc.}
proc funchook_prepare*(p: ptr RawFuncHook, target: ptr pointer, hook: pointer): HookResult {.importc.}
proc funchook_install*(p: ptr RawFuncHook, flags: int): HookResult {.importc.}
proc funchook_uninstall*(p: ptr RawFuncHook, flags: int): HookResult {.importc.}
proc funchook_destroy*(p: ptr RawFuncHook): HookResult {.importc.}
proc funchook_error_message*(p: ptr RawFuncHook): cstring {.importc.}
proc funchook_set_debug_file*(name: cstring): HookResult {.importc.}
{.pop.}