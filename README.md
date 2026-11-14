# radix: base 16 and base 64 (base16-bytestring, base64-bytestring)

Bytes (0..255) and the text naming them: hex (lower case), base 64 (RFC
4648's alphabet or the URL-safe one, padded or not). Decoding is the
inverse of encoding: `probe/Radix.bend` checks the round trip on every byte
and on every tail length, and RFC 4648's examples: "radix ok".
