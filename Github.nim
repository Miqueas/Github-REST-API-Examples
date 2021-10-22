# TODO: write the example
import std/httpclient
import std/json
# import std/parseopt
from std/os import commandLineParams

const BASE_URL = "https://api.github.com/users/"

type
  GthUserItem* = ref object
    count*: int
    arr*: seq[string]

  GthUser* = ref object
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

proc newGthUser*(username: string): GthUser =
  var self = GthUser()
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

  return self

method fetch*(self: GthUser, thing: string): void {.base.} =
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

let
  args = commandLineParams()
  # TODO: handle commandline switches
  # opts = initOptParser(args)

if args.len() > 0:
  for username in args:
    var user = newGthUser(username)
    echo user.name
    echo user.bio
    echo user.link
    echo ""