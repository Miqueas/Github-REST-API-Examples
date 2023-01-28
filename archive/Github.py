import json
import argparse
import re
from http import client

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36"
API_HOST = "api.github.com"
API_PATH = "/users/"

class GithubUser:
  def __init__(self, username: str):
    self.url = API_PATH + username

    conn = client.HTTPSConnection(API_HOST)
    conn.request("GET", self.url, headers = { "User-Agent": USER_AGENT })

    res = conn.getresponse()
    self.json = json.loads(res.read())

    self.name      = self.json["name"]
    self.bio       = self.json["bio"]
    self.link      = self.json["html_url"]

    self.repos     = { "count": self.json["public_repos"], "arr": [] }
    self.gists     = { "count": self.json["public_gists"], "arr": [] }
    self.followers = { "count": self.json["followers"],    "arr": [] }
    self.following = { "count": self.json["following"],    "arr": [] }

    res.close()
    conn.close()

  def fetch(self, thing: str):
    assert (re.match(r'(repos|gists|followers|following)', thing) is not None), f"Unsupported endpoint: {thing}"

    url  = self.url + '/' + thing
    conn = client.HTTPSConnection(API_HOST)
    conn.request("GET", url, headers = { "User-Agent": USER_AGENT })

    res = conn.getresponse()
    arr = json.loads(res.read())

    if thing == "repos":
      for obj in arr:
        self.repos["arr"].append(obj["name"])

    elif thing == "gists":
      for obj in arr:
        self.gists["arr"].append(obj["description"])

    elif thing == "followers":
      for obj in arr:
        self.followers["arr"].append(obj["login"])

    elif thing == "following":
      for obj in arr:
        self.following["arr"].append(obj["login"])

parser = argparse.ArgumentParser(
  usage       = "Github.py [OPTIONS] usernames",
  description = "Commandline app demostrating the Github REST API",
  epilog      = "https://github.com/Miqueas/Github-REST-API-Example"
)

parser.add_argument("usernames", nargs = '+')
parser.add_argument("-f", "--followers", action = "store_true", default = False)
parser.add_argument("-F", "--following", action = "store_true", default = False)
parser.add_argument("-r", "--repos",     action = "store_true", default = False)
parser.add_argument("-g", "--gists",     action = "store_true", default = False)

args = parser.parse_args()

for name in args.usernames:
  user = GithubUser(name)

  print(f"Name: {user.name}")
  print(f"Bio: {user.bio}")
  print(f"Link: {user.link}")

  print(f"Repos: {user.repos['count']}")
  if args.repos:
    user.fetch("repos")

    for i in range(len(user.repos['arr'])):
      print(f"| {i + 1}. {user.repos['arr'][i]}")

  print(f"Gists: {user.gists['count']}")
  if args.gists:
    user.fetch("gists")

    for i in range(len(user.gists["arr"])):
      print(f"| {i + 1}. {user.gists['arr'][i]}")

  print(f"Followers: {user.followers['count']}")
  if args.followers:
    user.fetch("followers")

    for i in range(len(user.followers["arr"])):
      print(f"| @{user.followers['arr'][i]}")

  print(f"Following: {user.following['count']}")
  if args.following:
    user.fetch("following")

    for i in range(len(user.following["arr"])):
      print(f"| @{user.following['arr'][i]}")

  print()