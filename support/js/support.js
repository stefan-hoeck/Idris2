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

const __esPrim_signedToUnsigned = (x,ma) => {
  if (x < 0) {
    const x2 = x % (ma +1);
    return x2 < 0 ? x2 + ma + 1 : x2;
  } else {
    return x | ma;
  }
}

// Int8
const __esPrim_truncSigned8 = x =>
  __esPrim_truncSigned(x,0x80)

const __esPrim_truncSignedBigInt8 = x =>
  __esPrim_truncSigned(x,0x80n)

const __esPrim_truncSignedWithMask8 = x =>
  __esPrim_truncSignedWithMask(x,0x80,0x7f)

const _add8s = (a,b) => __esPrim_truncSigned8(a + b)
const _sub8s = (a,b) => __esPrim_truncSigned8(a - b)
const _mul8s = (a,b) => __esPrim_truncSigned8(a * b)
const _shl8s = (a,b) => __esPrim_truncSignedWithMask8(a << b)
const _shr8s = (a,b) => __esPrim_truncSignedWithMask8(a >> b)

// Int16
const __esPrim_truncSigned16 = x =>
  __esPrim_truncSigned(x,0x8000)

const __esPrim_truncSignedBigInt16 = x =>
  __esPrim_truncSigned(x,0x8000n)

const __esPrim_truncSignedWithMask16 = x =>
  __esPrim_truncSignedWithMask(x,0x8000,0x7fff)

const _add16s = (a,b) => __esPrim_truncSigned16(a + b)
const _sub16s = (a,b) => __esPrim_truncSigned16(a - b)
const _mul16s = (a,b) => __esPrim_truncSigned16(a * b)
const _shl16s = (a,b) => __esPrim_truncSignedWithMask16(a << b)
const _shr16s = (a,b) => __esPrim_truncSignedWithMask16(a >> b)

//Int32
const __esPrim_truncSigned32 = x =>
  __esPrim_truncSigned(x,0x80000000)

const __esPrim_truncSignedBigInt32 = x =>
  __esPrim_truncSigned(x,0x80000000n)

const _add32s = (a,b) => __esPrim_truncSigned32(a + b)
const _sub32s = (a,b) => __esPrim_truncSigned32(a - b)

const _mul32s = (a,b) => __esPrim_truncSigned32{
  const res = a * b;
  if (res <= Number.MIN_SAFE_INTEGER || res >= Number.MAX_SAFE_INTEGER) {
    return Number(__esPrim_truncSigned(BigInt(a) * BigInt(b), 0x80000000n))
  } else {
    return __esPrim_truncSigned32(res)
  }
}

//Int64
const __esPrim_truncSignedBigInt64 = x =>
  __esPrim_truncSigned(x,0x8000000000000000n)

const __esPrim_truncSignedWithMask64 = x =>
  __esPrim_truncSignedWithMask(x,0x8000000000000000n,0x7fffffffffffffffn)

const _add64s = (a,b) => __esPrim_truncSignedBigInt64(a + b)
const _sub64s = (a,b) => __esPrim_truncSignedBigInt64(a - b)
const _mul64s = (a,b) => __esPrim_truncSignedBigInt64(a * b)
const _shl64s = (a,b) => __esPrim_truncSignedWithMask64(a << b)
const _shr64s = (a,b) => __esPrim_truncSignedWithMask64(a >> b)

//Bits8
const _add8u = (a,b) => (a + b) & 0xff
const _sub8u = (a,b) => { const res = (a - b); return res < 0 ? res + 0x100 }
const _mul8u = (a,b) => (a * b) & 0xff
const _shl8u = (a,b) => (a << b) & 0xff
const _shr8u = (a,b) => (a >> b) & 0xff

//Bits16
const _add16u = (a,b) => (a + b) & 0xffff
const _sub16u = (a,b) => { const res = (a - b); return res < 0 ? res + 0x10000 }
const _mul16u = (a,b) => (a * b) & 0xffff
const _shl16u = (a,b) => (a << b) & 0xffff
const _shr16u = (a,b) => (a >> b) & 0xffff

//Bits32
const _add32u = (a,b) => {
  const res = a + b
  return res > 0xffffffff ? res - 0x100000000 : res
}

const _sub32u = (a,b) => {
  const res = a - b
  return res < 0 ? res + 0x100000000
}

const _mul32u = (a,b) => __esPrim_truncSigned32{
  const res = a * b;
  if (res >= Number.MAX_SAFE_INTEGER) {
    return Number((BigInt(a) * BigInt(b)) & 0xffffffffn)
  } else {
    return res > 0xffffffff ? res % 0x100000000 | res
  }
}

const _shl32u = (a,b) => Number((BigInt(a) << BigInt(b)) & 0xffffffffn)
const _shr32u = (a,b) => Number((BigInt(a) >> BigInt(b)) & 0xffffffffn)

//Bits64
const _add64u = (a,b) => (a + b) & 0xffffffffffffffffn
const _mul64u = (a,b) => (a * b) & 0xffffffffffffffffn
const _shl64u = (a,b) => (a << b) & 0xffffffffffffffffn
const _shr64u = (a,b) => (a >> b) & 0xffffffffffffffffn

const _sub64u = (a,b) => {
  const res = (a - b);
  return res < 0 ? res + 0x10000000000000000n
}
