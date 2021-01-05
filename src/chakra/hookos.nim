import macros

import winim/lean

import funchook/funchook
import utils

import hookctx
export hookctx

proc osmodule(name: static string): HANDLE =
  let cache {.global.} = GetModuleHandle(name)
  doAssert cache != 0, "Cannot find moudle: " & name
  cache

proc osfunc(modname: static string, fnname: static string, T: typedesc): T =
  result = cast[T](GetProcAddress(osmodule modname, fnname))
  doAssert result != nil, "Cannot find proc address: " & fnname

macro hookos*(dllname, sym: static string, body: untyped) =
  let xtype = nnkProcTy.newTree(
    body[3].copy(),
    body[4].copy()
  )
  let fname = getNimIdent(body[0])
  let origin_id = ident(fname & "_origin")
  let hooked_id = ident(fname & "_hooked")
  result = nnkStmtList.newTree()
  result.add nnkLetSection.newTree(
    nnkIdentDefs.newTree(
      body[0],
      newEmptyNode(),
      nnkCall.newTree(
        bindSym "osfunc",
        newLit dllname,
        newLit sym,
        xtype,
      )
    )
  )
  result.add nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      origin_id,
      xtype,
      newEmptyNode()
    )
  )
  let hooked = body.copy()
  hooked[0] = hooked_id
  result.add hooked
  result.add nnkAsgn.newTree(
    origin_id,
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          bindSym "getHookContext"
        ),
        bindSym "hook"
      ),
      ident fname,
      hooked_id,
    )
  )