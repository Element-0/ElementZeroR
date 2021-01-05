type LogLevel* {.pure.} = enum
  llvl_debug,
  llvl_info,
  llvl_warn,
  llvl_error,
  llvl_unknown

type LogHandlerObj* = object of RootObj

type LogHandler* = ref LogHandlerObj

type SourceInfo* = tuple
  filename: string
  line, column: int

method log*(handler: LogHandler, tag: string, llvl: LogLevel, info: SourceInfo, message: string) {.base.} =
  discard

when defined(chakra):
  {.used.}
  var handlers: seq[LogHandler] = newSeqOfCap[LogHandler] 16

  proc doLog(tag: string, llvl: LogLevel, info: SourceInfo, message: string) {.exportc, dynlib.} =
    for handler in handlers:
      handler.log(tag, llvl, info, message)

  proc addLogHandler*(handler: LogHandler) {.exportc, dynlib.} =
    handlers.add handler
else:
  {.push dynlib: "chakra.dll".}
  proc doLog*(tag: string, llvl: LogLevel, info: SourceInfo, message: string) {.importc.}
  proc addLogHandler*(handler: LogHandler) {.importc.}
  {.pop.}

type Logger* = distinct string

template log*(logger: Logger, llvl: LogLevel, message: string) =
  doLog(string logger, llvl, instantiationInfo(), message)

template debug*(logger: Logger, message: string) =
  doLog(string logger, llvl_debug, instantiationInfo(), message)

template info*(logger: Logger, message: string) =
  doLog(string logger, llvl_info, instantiationInfo(), message)

template warn*(logger: Logger, message: string) =
  doLog(string logger, llvl_warn, instantiationInfo(), message)

template error*(logger: Logger, message: string) =
  doLog(string logger, llvl_error, instantiationInfo(), message)
