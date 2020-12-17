import winim/mean
import winim/winstr

type realwstring* {.importcpp: "wchar_t *".} = object

converter toRealWstring*(str: wstring): realwstring = cast[realwstring](winstrConverterWStringToLPWSTR str)
converter toRealWstring*(str: string): realwstring = cast[realwstring](winstrConverterStringToLPWSTR str)
converter toRealWstring*(niltype: typeof(nil)): realwstring = cast[realwstring](0)

type sysstring* {.importcpp: "wchar_t *".} = object

converter `$`*(str: sysstring): string = `$$`(cast[LPWSTR](str))

proc `=destroy`*(self: var sysstring) =
  if cast[int](self) != 0:
    SysFreeString cast[BSTR](self)

proc `=copy`*(self: var sysstring, rhs: sysstring) {.error.}

type ComPtr*[T] = object
  raw: ptr T

proc `=destroy`*[T](self: var ComPtr[T]) =
  if self.raw != nil:
    discard cast[ptr IUnknown](self.raw).lpVtbl.Release(cast[ptr IUnknown](self.raw))

proc `=copy`*[T](self: var ComPtr[T], rhs: ComPtr[T]) =
  if self.raw != rhs.raw:
    `=destroy`(self)
    wasMoved self
    if rhs.raw != nil:
      self.raw = rhs.raw
      discard cast[ptr IUnknown](self.raw).lpVtbl.AddRef(cast[ptr IUnknown](self.raw))

proc `=sink`*[T](self: var ComPtr[T], rhs: ComPtr[T]) =
  `=destroy`(self)
  wasMoved self
  self.raw = rhs.raw

converter raw*[T](p: ComPtr[T]): ptr T = p.raw

proc `+&`*[T](self: var ComPtr[T]): ptr ptr T =
  `=destroy`(self)
  wasMoved self
  addr self.raw

proc newComPtr*[T](p: ptr T): ComPtr[T] =
  result.raw = p

proc uuidof*[T](desc: typedesc[T]): ptr GUID =
  const typename = static: $T
  {.emit: [r"result = (decltype(result))&__uuidof(", typename, r");"].}

proc createComObject*[R, T](): ComPtr[T] =
  let res = CoCreateInstance(uuidof(R), nil, CLSCTX_INPROC_SERVER, uuidof(T), cast[ptr PVOID](addr result.raw))
  if res < 0:
    raise newException(OSError, "Failed to create instance for " & $T & " code: " & $res)

template checkres(res: HRESULT): untyped =
  let tmp = res
  if tmp < 0:
    return tmp

proc NoRegCoCreate(dllname: LPWSTR, rclsid: REFCLSID, riid: REFIID, ppv: ptr PVOID): HRESULT =
  let dll = LoadLibrary(dllname)
  if dll == 0:
    return E_INVALIDARG
  type pDllGetClassObject = proc (rclsid: REFCLSID, riid: REFIID, ppv: ptr PVOID): HRESULT {.stdcall.}
  let getobj = cast[pDllGetClassObject](GetProcAddress(dll, "DllGetClassObject"))
  if getobj == nil:
    return E_INVALIDARG
  var factory: ptr IClassFactory
  checkres getobj(rclsid, &IID_IClassFactory, cast[ptr PVOID](addr factory))
  factory.lpVtbl.CreateInstance(factory, nil, riid, ppv)

proc createComObject*[R, T](dll: string): ComPtr[T] =
  let res = NoRegCoCreate(winstrConverterStringToLPWSTR dll, uuidof(R), uuidof(T), cast[ptr PVOID](addr result.raw))
  if res < 0:
    raise newException(OSError, "Failed to create instance for " & $T & " code: " & $res)