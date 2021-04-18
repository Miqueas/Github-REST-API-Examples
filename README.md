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

### C#

__Note__: I made this on Linux and I tested the example using [Mono][Mono] (compiling with command line tools), Idk how this can be compiled on Windows. Also, this is my first time using C#, so the code can suck a lot.

Before to compile, you'll need [Newtonsoft.Json][Json] and [Mono.Options][Options], install it using [NuGet][NuGet]:

```
nuget install Newtonsoft.Json
nuget install Mono.Options
```

[Mono.Options][Options] is included with [Mono][Mono], but when I try to use it compiling the example, I give an error, so I used [NuGet][NuGet] to solve that.

Anyway, after you have all the dependencies, just copy the downloaded .dll file by [NuGet][NuGet] to the root folder where is the C# example and compile it:

```
csc Github.cs -r:Newtonsoft.Json.dll -r:Mono.Options.dll
```

And, finally, run it:

```
mono Github.exe
```

### Python

Just run:

```
python3 Github.py ...
```

[Mono]: https://mono-project.com
[NuGet]: https://nuget.org
[Json]: https://www.nuget.org/packages/Newtonsoft.Json/
[Options]: https://www.nuget.org/packages/Mono.Options/
[LicenseBadge]: https://img.shields.io/badge/License-Zlib-brightgreen?style=for-the-badge
[LicenseURL]: https://opensource.org/licenses/Zlib