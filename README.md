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

### Go

Just run with:

```bash
go run Github.go
```

Or build if you want:

```bash
go build Github.go
```

### Vala

You'll need this before compile the example:

  - `json-glib-1.0`
  - `libsoup-2.4`

Then:

```
valac Github.vala --pkg=json-glib-1.0 --pkg=libsoup-2.4
```

### Ruby

Same as the Go example:

```bash
ruby Github.rb
```

[LicenseBadge]: https://img.shields.io/badge/License-Zlib-brightgreen?style=for-the-badge
[LicenseURL]: https://opensource.org/licenses/Zlib