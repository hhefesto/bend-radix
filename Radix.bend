import Base

# Radix: bytes as text in base 16 and base 64 (base16-bytestring's and
# base64-bytestring's job in the Haskell backend).
#
# What it means: a byte string (each byte 0..255, one List cell) and the
# text that names it, 4 bits a digit (hex, lower case) or 6 bits a character
# (RFC 4648's alphabet, or its URL-safe one; `=` padding or none). Decoding
# is the inverse of encoding: probe/Radix.bend checks the round trip on
# every byte and on RFC 4648's examples.
#
# Every def is prefixed `rx.` (a program's defs share one namespace).

# Base 16
# -------

def rx.nib(+n: U32) -> U32:
  Bool.pick(U32, U32.is_lt(n, 10), (n + 48 : U32), (n + 87 : U32))

def rx.hex(bs: List<&2, U32>) -> String:
  match bs:
    case Nil{}:
      ""
    case Con{+b, t}:
      SCon{Chr{rx.nib(U32.shrn(b, 4n))}, SCon{Chr{rx.nib(U32.and(b, 15))}, rx.hex(t)}}

def rx.hexv.at(a: Bool, b: Bool, c2: Bool, d: Bool, e: Bool, f: Bool, +c: U32) -> U32:
  match a b c2 d e f:
    case False{} True{} _ _ _ _:
      (c - 48 : U32)
    case False{} False{} False{} True{} _ _:
      (c - 55 : U32)
    case False{} False{} False{} False{} False{} True{}:
      (c - 87 : U32)
    case _ _ _ _ _ _:
      16

# a hex digit's value (16: none)
def rx.hexv(+c: U32) -> U32:
  rx.hexv.at(U32.is_lt(c, 48), U32.is_lt(c, 58), U32.is_lt(c, 65), U32.is_lt(c, 71), U32.is_lt(c, 97), U32.is_lt(c, 103), c)

def rx.unhex.at(bad: Bool, +v: U32, more: Maybe<&2, List<&2, U32>>) -> Maybe<&2, List<&2, U32>>:
  match bad more:
    case True{} x:
      None{}
    case False{} None{}:
      None{}
    case False{} Some{bs}:
      Some{v <> bs}

def rx.unhex(s: String) -> Maybe<&2, List<&2, U32>>:
  match s:
    case SNil{}:
      Some{[]}
    case SCon{Chr{+a}, SCon{Chr{+b}, t}}:
      rx.unhex.at(U32.is_eq(rx.hexv(a), 16) || U32.is_eq(rx.hexv(b), 16), (rx.hexv(a) * 16 + rx.hexv(b) : U32), rx.unhex(t))
    case x:
      None{}

# Base 64
# -------

def rx.sym(+url: Bool, +n: U32) -> U32:
  Bool.pick(U32, U32.is_lt(n, 26), (n + 65 : U32),
    Bool.pick(U32, U32.is_lt(n, 52), (n + 71 : U32),
      Bool.pick(U32, U32.is_lt(n, 62), (n - 4 : U32),
        Bool.pick(U32, U32.is_eq(n, 62), Bool.pick(U32, url, 45, 43), Bool.pick(U32, url, 95, 47)))))

def rx.c6(+url: Bool, +n: U32, +k: Nat, out: String) -> String:
  SCon{Chr{rx.sym(url, U32.and(U32.shrn(n, k), 63))}, out}

def rx.pad(+pad: Bool, +k: Nat, out: String) -> String:
  match pad:
    case True{}:
      String.append(String.repeat("=", k), out)
    case False{}:
      out

# bytes in base 64: url, the URL-safe alphabet; pad, "=" to a multiple of 4
def rx.b64(+url: Bool, +pad: Bool, bs: List<&2, U32>) -> String:
  match bs:
    case Nil{}:
      ""
    case Con{+a, Nil{}}:
      rx.c6(url, U32.shln(a, 16n), 18n, rx.c6(url, U32.shln(a, 16n), 12n, rx.pad(pad, 2n, "")))
    case Con{+a, Con{+b, Nil{}}}:
      rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) : U32), 18n, rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) : U32), 12n,
        rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) : U32), 6n, rx.pad(pad, 1n, ""))))
    case Con{+a, Con{+b, Con{+c, t}}}:
      rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) + c : U32), 18n, rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) + c : U32), 12n,
        rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) + c : U32), 6n, rx.c6(url, (U32.shln(a, 16n) + U32.shln(b, 8n) + c : U32), 0n, rx.b64(url, pad, t)))))

def rx.val.at(up: Bool, lo: Bool, dg: Bool, s62: Bool, s63: Bool, +c: U32) -> U32:
  match up lo dg s62 s63:
    case True{} _ _ _ _:
      (c - 65 : U32)
    case False{} True{} _ _ _:
      (c - 71 : U32)
    case False{} False{} True{} _ _:
      (c + 4 : U32)
    case False{} False{} False{} True{} _:
      62
    case False{} False{} False{} False{} True{}:
      63
    case _ _ _ _ _:
      64

# a base-64 character's value, either alphabet (64: none)
def rx.val(+c: U32) -> U32:
  rx.val.at(U32.is_ge(c, 65) && U32.is_le(c, 90), U32.is_ge(c, 97) && U32.is_le(c, 122), U32.is_ge(c, 48) && U32.is_le(c, 57),
    U32.is_eq(c, 43) || U32.is_eq(c, 45), U32.is_eq(c, 47) || U32.is_eq(c, 95), c)

def rx.dec.out(bad: Bool, out: List<&2, U32>, more: Maybe<&2, List<&2, U32>>) -> Maybe<&2, List<&2, U32>>:
  match bad more:
    case True{} x:
      None{}
    case False{} None{}:
      None{}
    case False{} Some{bs}:
      Some{List.append(&2, U32, out, bs)}

def rx.n4(+a: U32, +b: U32, +c: U32, +d: U32) -> U32:
  (U32.shln(a, 18n) + U32.shln(b, 12n) + U32.shln(c, 6n) + d : U32)

def rx.bytes3(+n: U32) -> List<&2, U32>:
  [U32.shrn(n, 16n), U32.and(U32.shrn(n, 8n), 255), U32.and(n, 255)]

# base 64 read back (padded or not)
def rx.unb64(s: String) -> Maybe<&2, List<&2, U32>>:
  match s:
    case SNil{}:
      Some{[]}
    case SCon{Chr{+a}, SCon{Chr{+b}, SNil{}}}:
      rx.dec.out(U32.is_eq(rx.val(a), 64) || U32.is_eq(rx.val(b), 64), [U32.shrn(rx.n4(rx.val(a), rx.val(b), 0, 0), 16n)], Some{[]})
    case SCon{Chr{+a}, SCon{Chr{+b}, SCon{Chr{61}, SCon{Chr{61}, SNil{}}}}}:
      rx.dec.out(U32.is_eq(rx.val(a), 64) || U32.is_eq(rx.val(b), 64), [U32.shrn(rx.n4(rx.val(a), rx.val(b), 0, 0), 16n)], Some{[]})
    case SCon{Chr{+a}, SCon{Chr{+b}, SCon{Chr{+c}, SNil{}}}}:
      rx.dec.out(U32.is_eq(rx.val(a), 64) || (U32.is_eq(rx.val(b), 64) || U32.is_eq(rx.val(c), 64)),
        List.take(&2, U32, rx.bytes3(rx.n4(rx.val(a), rx.val(b), rx.val(c), 0)), 2n), Some{[]})
    case SCon{Chr{+a}, SCon{Chr{+b}, SCon{Chr{+c}, SCon{Chr{61}, SNil{}}}}}:
      rx.dec.out(U32.is_eq(rx.val(a), 64) || (U32.is_eq(rx.val(b), 64) || U32.is_eq(rx.val(c), 64)),
        List.take(&2, U32, rx.bytes3(rx.n4(rx.val(a), rx.val(b), rx.val(c), 0)), 2n), Some{[]})
    case SCon{Chr{+a}, SCon{Chr{+b}, SCon{Chr{+c}, SCon{Chr{+d}, t}}}}:
      rx.dec.out(U32.is_eq(rx.val(a), 64) || (U32.is_eq(rx.val(b), 64) || (U32.is_eq(rx.val(c), 64) || U32.is_eq(rx.val(d), 64))),
        rx.bytes3(rx.n4(rx.val(a), rx.val(b), rx.val(c), rx.val(d))), rx.unb64(t))
    case x:
      None{}
