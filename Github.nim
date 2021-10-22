# TODO: write the example
import std/httpclient
import std/json
import std/uri

const BASE_URL = parseUri("https://api.github.com/users")

type
  GthUserItem* = ref object
    count*: int
    arr*: seq[string]

  GthUser* = ref object
    # Private
    obj: JsonNode
    url: Uri
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
  self.url = parseUri($(BASE_URL / username))

  var res  = newHttpClient().getContent($self.url)
  self.obj = parseJson(res)

  self.name = self.obj["name"].getStr()
  self.bio  = self.obj["bio"].getStr()
  self.link = self.obj["html_url"].getStr()

  self.repos = GthUserItem(count: self.obj["public_repos"].getInt())
  self.gists = GthUserItem(count: self.obj["public_gists"].getInt())
  self.followers = GthUserItem(count: self.obj["followers"].getInt())
  self.following = GthUserItem(count: self.obj["following"].getInt())

  return self

var user = newGthUser("Miqueas")
echo user[]