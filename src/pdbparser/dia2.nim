import ../interop/com
import winim/lean

export com

const diaheader = "<dia2.h>"

type DiaError* = object of OSError

type DiaSource* {.importcpp, header: diaheader, nodecl.} = object
type IDiaDataSource* {.importcpp, header: diaheader, nodecl.} = object
type IDiaSession* {.importcpp, header: diaheader, nodecl.} = object
type IDiaSymbol* {.importcpp, header: diaheader, nodecl.} = object
type IDiaEnumSymbols* {.importcpp, header: diaheader, nodecl.} = object

type SymTags* {.importcpp: "enum SymTagEnum", header: diaheader.} = enum
  SymTagNull,
  SymTagExe,
  SymTagCompiland,
  SymTagCompilandDetails,
  SymTagCompilandEnv,
  SymTagFunction,
  SymTagBlock,
  SymTagData,
  SymTagAnnotation,
  SymTagLabel,
  SymTagPublicSymbol,
  SymTagUDT,
  SymTagEnum,
  SymTagFunctionType,
  SymTagPointerType,
  SymTagArrayType,
  SymTagBaseType,
  SymTagTypedef,
  SymTagBaseClass,
  SymTagFriend,
  SymTagFunctionArgType,
  SymTagFuncDebugStart,
  SymTagFuncDebugEnd,
  SymTagUsingNamespace,
  SymTagVTableShape,
  SymTagVTable,
  SymTagCustom,
  SymTagThunk,
  SymTagCustomType,
  SymTagManagedType,
  SymTagDimension,
  SymTagCallSite,
  SymTagInlineSite,
  SymTagBaseInterface,
  SymTagVectorType,
  SymTagMatrixType,
  SymTagHLSLType,
  SymTagCaller,
  SymTagCallee,
  SymTagExport,
  SymTagHeapAllocationSite,
  SymTagCoffGroup,
  SymTagInlinee,
  SymTagMax

proc loadDataFromPdb*(src: ptr IDiaDataSource, path: realwstring): HRESULT {.importcpp.}
proc openSession*(src: ptr IDiaDataSource, sess: ptr ptr IDiaSession): HRESULT {.importcpp.}

proc get_globalScope*(src: ptr IDiaSession, psym: ptr ptr IDiaSymbol): HRESULT {.importcpp.}

proc findChildren*(src: ptr IDiaSymbol, tag: SymTags, name: realwstring, flags: DWORD, result: ptr ptr IDiaEnumSymbols): HRESULT {.importcpp.}
proc get_name*(src: ptr IDiaSymbol, pname: ptr sysstring): HRESULT {.importcpp.}
proc get_undecoratedName*(src: ptr IDiaSymbol, pname: ptr sysstring): HRESULT {.importcpp.}
proc get_virtualAddress*(src: ptr IDiaSymbol, paddr: ptr culonglong): HRESULT {.importcpp.}

proc Next*(src: ptr IDiaEnumSymbols, celt: culong, psym: ptr ptr IDiaSymbol, pcelt: ptr culong): HRESULT {.importcpp.}

proc createDataSource*(): ComPtr[IDiaDataSource] =
  createComObject[DiaSource, IDiaDataSource]("msdia140.dll")

template checkres(name: string, err: HRESULT): untyped =
  if err < 0:
    raise newException(DiaError, name)

proc loadSession*(src: ptr IDiaDataSource, path: string): ComPtr[IDiaSession] =
  checkres "failed to load pdb":
    src.loadDataFromPdb(path)
  checkres "failed to open session":
    src.openSession(+&result)

proc global*(src: ptr IDiaSession): ComPtr[IDiaSymbol] =
  checkres "failed to get global":
    src.get_globalScope(+&result)

proc findChildren*(src: ptr IDiaSymbol, tag: SymTags, name: realwstring = nil, flags: DWORD = 0): ComPtr[IDiaEnumSymbols] =
  checkres "failed to find children":
    src.findChildren(tag, name, flags, +&result)

proc name*(src: ptr IDiaSymbol): string =
  var str: sysstring
  checkres "failed to get name":
    src.get_name(addr str)
  return $str
proc undecoratedName*(src: ptr IDiaSymbol): string =
  var str: sysstring
  checkres "failed to get name":
    src.get_undecoratedName(addr str)
  return $str
proc virtualAddress*(src: ptr IDiaSymbol): ByteAddress =
  var r: culonglong
  checkres "failed to get VA":
    src.get_virtualAddress(addr r)
  return cast[ByteAddress](r)

iterator items*(src: ptr IDiaEnumSymbols): ComPtr[IDiaSymbol] =
  var celt: culong = 0
  while true:
    var ret: ComPtr[IDiaSymbol]
    checkres "failed to iterate symbols":
      src.Next(1, +&ret, addr celt)
    if celt == 0: break
    yield ret
