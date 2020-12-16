import winim/inc/windef

template NtChecked*(text, body: untyped) =
  let status = body
  if not NT_SUCCESS(status):
    raise newException(OSError, text)