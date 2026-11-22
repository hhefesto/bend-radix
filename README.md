# radix: base 16 and base 64 (base16-bytestring, base64-bytestring)

Bytes (0..255) and the text naming them: hex (lower case), base 64 (RFC
4648's alphabet or the URL-safe one, padded or not). Decoding is the
inverse of encoding: `probe/Radix.bend` checks the round trip on every byte
and on every tail length, and RFC 4648's examples: "radix ok".

## This repository

Written for mugen-app (mugen's chat in a browser) as part of its Bend
backend, which replaced a Haskell one: a mention above of `backend/`,
`server/` or `server/test/compare.sh` is that app's. The libraries written
with it: [bend-wire](https://github.com/hhefesto/bend-wire), [bend-route](https://github.com/hhefesto/bend-route), [bend-json](https://github.com/hhefesto/bend-json), [bend-files](https://github.com/hhefesto/bend-files), [bend-md](https://github.com/hhefesto/bend-md), [bend-sha2](https://github.com/hhefesto/bend-sha2), [bend-text](https://github.com/hhefesto/bend-text), [bend-time](https://github.com/hhefesto/bend-time), [bend-entropy](https://github.com/hhefesto/bend-entropy), [bend-bcrypt](https://github.com/hhefesto/bend-bcrypt), [bend-bucket](https://github.com/hhefesto/bend-bucket).

**Using it.** Bend imports by path: clone this repository as `bend-radix/`
beside your code,
and import it: `import ../bend-radix/Radix.bend as X`. In a Nix build, copy the flake's
source (or its `packages.default`) there.

**Checks** (`nix flake check`, with the pinned Bend 2.0.39):
`bend FILE.bend --check-only` on each module.

**License**: MIT (`LICENSE`).
