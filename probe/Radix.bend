import Base
import ../Radix.bend as R

# Radix's round trips on every byte (alone and in threes, so each of base
# 64's tails is met) and RFC 4648's examples; prints "radix ok" or what
# failed.

def rp.bytes(+n: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      0 <> acc
    case 1n+p:
      rp.bytes(p, U32.from_nat(1n+p) <> acc)

def rp.eqb(a: List<&2, U32>, b: List<&2, U32>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Con{+x, xs} Con{+y, ys}:
      U32.is_eq(x, y) && rp.eqb(xs, ys)
    case x y:
      False{}

def rp.back(+bs: List<&2, U32>, m: Maybe<&2, List<&2, U32>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{cs}:
      rp.eqb(bs, cs)

def rp.round(+bs: List<&2, U32>) -> Bool:
  rp.back(bs, R.rx.unhex(R.rx.hex(bs))) && (rp.back(bs, R.rx.unb64(R.rx.b64(False{}, True{}, bs)))
    && (rp.back(bs, R.rx.unb64(R.rx.b64(True{}, False{}, bs))) && rp.back(bs, R.rx.unb64(R.rx.b64(True{}, True{}, bs)))))

# every prefix of every suffix up to 3 bytes long
def rp.all(bs: List<&2, U32>) -> Bool:
  match bs:
    case Nil{}:
      True{}
    case Con{+a, +t}:
      rp.round([a]) && (rp.round(List.take(&2, U32, a <> t, 2n)) && (rp.round(List.take(&2, U32, a <> t, 3n)) && rp.all(t)))

def rp.utf(s: String) -> List<&2, U32>:
  match s:
    case SNil{}:
      []
    case SCon{Chr{c}, t}:
      c <> rp.utf(t)

def rp.rfc(s: String, +want: String) -> Bool:
  String.eq(R.rx.b64(False{}, True{}, rp.utf(s)), want)

def main() -> String:
  Bool.pick(String, rp.all(rp.bytes(255n, [])) && rp.round(rp.bytes(255n, []))
    && (rp.rfc("", "") && (rp.rfc("f", "Zg==") && (rp.rfc("fo", "Zm8=") && (rp.rfc("foo", "Zm9v") && (rp.rfc("foob", "Zm9vYg==")
    && (rp.rfc("fooba", "Zm9vYmE=") && rp.rfc("foobar", "Zm9vYmFy"))))))),
    "radix ok", "radix WRONG")
