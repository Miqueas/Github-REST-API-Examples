import http.client as Client
import json        as JSON
import argparse    as ArgParse
import re          as RegExp

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36"
API_HOST = "api.github.com"
API_PATH = "/users/"

class GithubRepo(object):
  def __init__(self, name, desc):
    super(GithubRepo, self).__init__()
    self.Name = name
    self.Desc = desc


class GithubUser(object):
  def __init__(self, username):
    super(GithubUser, self).__init__()
    self.url = API_PATH + username

    conn = Client.HTTPSConnection(API_HOST)
    conn.request("GET", self.url, headers={ "User-Agent": USER_AGENT })

    res = conn.getresponse()
    self.json = JSON.loads(res.read())

    self.Name      = self.json["name"]
    self.Bio       = self.json["bio"]
    self.Link      = self.json["html_url"]
    self.Repos     = { "count": self.json["public_repos"], "arr": [] }
    self.Gists     = { "count": self.json["public_gists"], "arr": [] }
    self.Followers = { "count": self.json["followers"], "arr": [] }
    self.Following = { "count": self.json["following"], "arr": [] }

    res.close()
    conn.close()

  def Fetch(self, kind):
    assert (RegExp.match(r'(repos|gists|followers|following)', kind) is not None), f"Unsupported endpoint: {kind}"

    url  = f"{self.url}/{kind}"
    conn = Client.HTTPSConnection(API_HOST)
    conn.request("GET", url, headers={ "User-Agent": USER_AGENT })

    res = conn.getresponse()
    arr = JSON.loads(res.read())

    if kind == "repos":
      for obj in arr:
        n = obj["name"]
        d = obj["description"]
        self.Repos["arr"].append(GithubRepo(n, d))

    elif kind == "gists":
      for obj in arr:
        self.Gists["arr"].append(obj["description"])

    elif kind == "followers":
      for obj in arr:
        self.Followers["arr"].append(obj["login"])

    elif kind == "following":
      for obj in arr:
        self.Following["arr"].append(obj["login"])

parser = ArgParse.ArgumentParser(
  usage="Github.py [OPTIONS] usernames",
  description="Commandline app demostrating the Github REST API",
  epilog="https://github.com/Miqueas/Github-REST-API-Example"
)

parser.add_argument("usernames", nargs='+')
parser.add_argument("-f", "--followers", action="store_true", default=False)
parser.add_argument("-F", "--following", action="store_true", default=False)
parser.add_argument("-r", "--repos",     action="store_true", default=False)
parser.add_argument("-g", "--gists",     action="store_true", default=False)

args = parser.parse_args()

for name in args.usernames:
  user = GithubUser(name)

  print(f"Name: {user.Name}")
  print(f"Bio: {user.Bio}")
  print(f"Link: {user.Link}")

  print(f"Public repos: {user.Repos['count']}")
  if args.repos:
    user.Fetch("repos")

    for i in range(len(user.Repos["arr"])):
      n = user.Repos['arr'][i].Name
      d = user.Repos['arr'][i].Desc
      print(f"| {i + 1}. {n}: {d}")

  print(f"Public gists: {user.Gists['count']}")
  if args.gists:
    user.Fetch("gists")

    for i in range(len(user.Gists["arr"])):
      print(f"| {i + 1}. {user.Gists['arr'][i]}")

  print(f"Followers: {user.Followers['count']}")
  if args.followers:
    user.Fetch("followers")

    for i in range(len(user.Followers["arr"])):
      print(f"| @{user.Followers['arr'][i]}")

  print(f"Following: {user.Following['count']}")
  if args.following:
    user.Fetch("following")

    for i in range(len(user.Following["arr"])):
      print(f"| @{user.Following['arr'][i]}")

  print()