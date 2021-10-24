import std/httpclient
import std/strformat
import std/parseopt
import std/json
from std/os import commandLineParams

const BASE_URL = "https://api.github.com/users/"

type
  GthUserItem* = object
    count*: int
    arr*: seq[string]

  GthUser* = object
    # Private
    obj: JsonNode
    url: string
    # Public
    name*: string
    bio*: string
    link*: string
    repos*: GthUserItem
    gists*: GthUserItem
    followers*: GthUserItem
    following*: GthUserItem

proc init*(self: var GthUser; username: string) =
  self.url = BASE_URL & username
    
  var res  = newHttpClient().getContent(self.url)
  self.obj = parseJson(res)

  self.name = self.obj["name"].getStr()
  self.bio  = self.obj["bio"].getStr()
  self.link = self.obj["html_url"].getStr()

  self.repos = GthUserItem(count: self.obj["public_repos"].getInt())
  self.gists = GthUserItem(count: self.obj["public_gists"].getInt())
  self.followers = GthUserItem(count: self.obj["followers"].getInt())
  self.following = GthUserItem(count: self.obj["following"].getInt())

proc fetch*(self: var GthUser; thing: string) =
  var
    url = self.url & '/' & thing
    res = newHttpClient().getContent(url)
    arr = parseJson(res)
  
  case thing
    of "repos":
      for v in arr.items():
        self.repos.arr.add(v["name"].getStr())
    of "gists":
      for v in arr.items():
        self.gists.arr.add(v["description"].getStr())
    of "followers":
      for v in arr.items():
        self.followers.arr.add(v["login"].getStr())
    of "following":
      for v in arr.items():
        self.following.arr.add(v["login"].getStr())
    else:
      echo "Unsupported endpoint: ", thing

var
  cmdline = commandLineParams()
  args: seq[string]
  opts: tuple[
    repos: bool,
    gists: bool,
    followers: bool,
    following: bool
  ]

for kind, name, value in getopt(cmdline):
  case kind:
    of cmdArgument: args.add(name)
    of cmdShortOption, cmdLongOption:
      case name:
        of "r", "repos": opts.repos = true
        of "g", "gists": opts.gists = true
        of "f", "followers": opts.followers = true
        of "F", "following": opts.following = true
        else: continue
    of cmdEnd: break

if args.len() == 0:
  echo "No arguments, nothing to do."
else:
  for username in args:
    var user = GthUser()
    user.init(username)

    echo "Name: ", user.name
    echo "Bio: ", user.bio
    echo "Link: ", user.link

    echo "Public repos: ", user.repos.count
    if opts.repos:
      user.fetch("repos")

      for i, v in user.repos.arr:
        echo fmt"| {(i + 1):03}. {v}"
    
    echo "Public gists: ", user.gists.count
    if opts.gists:
      user.fetch("gists")

      for i, v in user.gists.arr:
        echo fmt"| {(i + 1):03}. {v}"
    
    echo "Public followers: ", user.followers.count
    if opts.followers:
      user.fetch("followers")

      for v in user.followers.arr:
        echo fmt"| @{v}"
    
    echo "Public following: ", user.following.count
    if opts.following:
      user.fetch("following")

      for v in user.following.arr:
        echo fmt"| @{v}"
    
    echo ""