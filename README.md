[![License][LicenseBadge]][LicenseURL]

## What is this?

A set of basic examples of what you can do with Github's REST API written in different programming languages.

## Running/Building

### Lua

The Lua example needs some libraries:

```bash
# For easy GET requests to the API
luarocks install lua-requests
# Fast JSON encoding/decoding
luarocks install rapidjson
# Commandline options, flags and arguments parsing
luarocks install argparse
```

After you have all these libraries, then run the example:

```bash
lua Github.lua
```

### Nim

Build the Nim example with:

```
nim c -d:ssl Github.nim
```

And run:

```
./Github ...
```

__NOTE__: On Windows (and probably macOS too) you'll need to download a [SSL/TLS Certificate](https://curl.se/ca/cacert.pem) and put it into the folder where you compiled the example. This is due to a [Nim bug](https://github.com/nim-lang/Nim/issues/782) and that's the temporary fix.

[LicenseBadge]: https://img.shields.io/badge/License-Zlib-brightgreen?style=for-the-badge
[LicenseURL]: https://opensource.org/licenses/Zlib