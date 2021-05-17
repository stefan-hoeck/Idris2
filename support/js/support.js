class IdrisError extends Error { }

function __prim_js2idris_array(x){
  if(x.length === 0){
    return {h:0}
  } else {
    return {h:1,a1:x[0],a2: __prim_js2idris_array(x.slice(1))}
  }
}

function __prim_idris2js_array(x){
  const result = Array();
  while (x.h != 0) {
    result.push(x.a1); x = x.a2;
  }
  return result;
}

function __prim_stringIteratorNew(str) {
  return 0
}

function __prim_stringIteratorToString(_, str, it, f) {
  return f(str.slice(it))
}

function __prim_stringIteratorNext(str, it) {
  if (it >= str.length)
    return {h: 0};
  else
    return {h: 1, a1: str.charAt(it), a2: it + 1};
}

const __esPrim_crashExp = x=>{throw new IdrisError(x)}

const __esPrim_bigIntOfString = s=>{
  const idx = s.indexOf('.')
  return idx === -1 ? BigInt(s) : BigInt(s.slice(0, idx))
}

const __esPrim_truncToChar = x=> String.fromCodePoint(
  (x >= 0 && x <= 55295) || (x >= 57344 && x <= 1114111) ? x : 0
)

const __esPrim_truncSignedWithMask = (x,mi,ma) =>
  (mi & x) == mi ? (x | -mi) : (x & ma)

const __esPrim_truncSigned = (x,ma) =>
  (x >= ma || x < -ma) ? x % ma : x

const __esPrim_truncUnsigned = (x,ma) =>
  if (x < 0) return x % ma + ma
  else return __esPrim_truncUnsignedMask
  (x >= ma || x < -ma) ? x % ma : x

const __esPrim_truncSignedWithMask8 = x =>
  __esPrim_truncSignedWithMask(x,0x80,0x7f)

const __esPrim_truncSignedWithMask16 = x =>
  __esPrim_truncSignedWithMask(x,0x8000,0x7fff)

const __esPrim_truncSignedWithMask64 = x =>
  __esPrim_truncSignedWithMask(x,0x8000000000000000n,0x7fffffffffffffffn)

const __esPrim_truncSigned8 = x =>
  __esPrim_truncSigned(x,0x80)

const __esPrim_truncSigned16 = x =>
  __esPrim_truncSigned(x,0x8000)

const __esPrim_truncSigned32 = x =>
  __esPrim_truncSigned(x,0x80000000)

const __esPrim_truncSignedBigInt8 = x =>
  __esPrim_truncSigned(x,0x80n)

const __esPrim_truncSignedBigInt16 = x =>
  __esPrim_truncSigned(x,0x8000n)

const __esPrim_truncSignedBigInt32 = x =>
  __esPrim_truncSigned(x,0x80000000n)

const __esPrim_truncSignedBigInt64 = x =>
  __esPrim_truncSigned(x,0x8000000000000000n)
