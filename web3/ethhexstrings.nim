import strutils

type
  HexQuantityStr* = distinct string
  HexDataStr* = distinct string

# Hex validation

template stripLeadingZeros(value: string): string =
  var cidx = 0
  # ignore the last character so we retain '0' on zero value
  while cidx < value.len - 1 and value[cidx] == '0':
    cidx.inc
  value[cidx .. ^1]

proc encodeQuantity*(value: SomeUnsignedInt): string =
  var hValue = value.toHex.stripLeadingZeros
  result = "0x" & hValue

func hasHexHeader*(value: string): bool =
  value.len >= 2 and value[0] == '0' and value[1] in {'x', 'X'}

template hasHexHeader*(value: HexDataStr|HexQuantityStr): bool =
  value.string.hasHexHeader

func isHexChar*(c: char): bool =
  if  c notin {'0'..'9'} and
      c notin {'a'..'f'} and
      c notin {'A'..'F'}: false
  else: true

proc validate*(value: HexQuantityStr): bool =
  template strVal: untyped = value.string
  if not value.hasHexHeader:
    return false
  # No leading zeros
  if strVal[2] == '0': return false
  for i in 2..<strVal.len:
    let c = strVal[i]
    if not c.isHexChar:
      return false
  return true

proc validate*(value: HexDataStr): bool =
  template strVal: untyped = value.string
  if not value.hasHexHeader:
    return false
  # Leading zeros are allowed
  for i in 2..<strVal.len:
    let c = strVal[i]
    if not c.isHexChar:
      return false
  # Must be even number of digits
  if strVal.len mod 2 != 0: return false
  return true

# Initialisation

template hexDataStr*(value: string): HexDataStr = value.HexDataStr
template hexQuantityStr*(value: string): HexQuantityStr = value.HexQuantityStr

# Converters

import json
from json_rpc/rpcserver import expect

proc `%`*(value: HexDataStr): JsonNode =
  if not value.validate:
    raise newException(ValueError, "HexDataStr: Invalid hex for Ethereum: " & value.string)
  else:
    result = %(value.string)

proc `%`*(value: HexQuantityStr): JsonNode =
  if not value.validate:
    raise newException(ValueError, "HexQuantityStr: Invalid hex for Ethereum: " & value.string)
  else:
    result = %(value.string)

proc fromJson*(n: JsonNode, argName: string, result: var HexDataStr) =
  # Note that '0x' is stripped after validation
  n.kind.expect(JString, argName)
  let hexStr = n.getStr()
  if not hexStr.hexDataStr.validate:
    raise newException(ValueError, "Parameter \"" & argName & "\" value is not valid as a Ethereum data \"" & hexStr & "\"")
  result = hexStr[2..hexStr.high].hexDataStr

proc fromJson*(n: JsonNode, argName: string, result: var HexQuantityStr) =
  # Note that '0x' is stripped after validation
  n.kind.expect(JString, argName)
  let hexStr = n.getStr()
  if not hexStr.hexQuantityStr.validate:
    raise newException(ValueError, "Parameter \"" & argName & "\" value is not valid as an Ethereum hex quantity \"" & hexStr & "\"")
  result = hexStr[2..hexStr.high].hexQuantityStr

