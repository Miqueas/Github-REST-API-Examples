-- luarocks install lua-requests
local Requests = require("requests")
-- luarocks install rapidjson
local JSON     = require("rapidjson")
-- luarocks install argparse
local ArgParse = require("argparse")

local APIUsersURL = "https://api.github.com/users/"
local GithubUser  = {}

function GithubUser:new(username)
  assert(
    type(username) == "string",
    "Bad argument for 'new', string expected, got " .. type(username)
  )

  local Res = Requests.get(APIUsersURL .. username)
  self.Url = APIUsersURL .. username
  self.Obj = JSON.decode(Res.text)

  self.Name           = self.Obj['name']
  self.Bio            = self.Obj['bio']
  self.Link           = self.Obj['html_url']
  self.ReposCount     = self.Obj['public_repos']
  self.GistsCount     = self.Obj['public_gists']
  self.FollowersCount = self.Obj['followers']
  self.FollowingCount = self.Obj['following']
  self.ReposArr       = {}
  self.GistsArr       = {}
  self.FollowersArr   = {}
  self.FollowingArr   = {}

  return self
end

function GithubUser:Fetch(kind)
  assert(
    type(kind) == "string",
    "Bad argument for 'new', string expected, got " .. type(kind)
  )

  local url = self.Url .. '/' .. kind
  local res = Requests.get(url)
  local arr = JSON.decode(res.text)

  if kind == "repos" then
    for i, v in ipairs(arr) do
      self.ReposArr[i] = { Name = v["name"], Desc = v["description"] }
    end

  elseif kind == "gists" then
    for i, v in ipairs(arr) do
      self.GistsArr[i] = v["description"]
    end

  elseif kind == "followers" then
    for i, v in ipairs(arr) do
      self.FollowersArr[i] = v["login"]
    end

  elseif kind == "following" then
    for i, v in ipairs(arr) do
      self.FollowingArr[i] = v["login"]
    end

  else
    return error("Unsupported endpoint: " .. kind)
  end
end

local Opts = ArgParse({
  name = "Github.lua",
  description = "Simple example of the Github's REST API",
  epilog = "Check out https://github.com/M1que4s/Github-REST-API-Example"
})

Opts:argument("usernames", "One or more usernames"):args("+")
Opts:flag("-f --followers", "Shows user followers", false)
Opts:flag("-F --following", "Shows user following", false)
Opts:flag("-r --repos", "Shows user repos", false)
Opts:flag("-g --gists", "Shows user gists", false)

local Args = Opts:parse(arg)

for _, v in ipairs(Args.usernames) do
  local User = GithubUser:new(v)

  print("Name: " .. User.Name)
  print("Bio: " .. User.Bio)
  print("Link: " .. User.Link)

  print("Public repos: " .. User.ReposCount)
  if Args.r or Args.repos then
    User:Fetch("repos")

    for i, v in ipairs(User.ReposArr) do
      print(("| %02d %s: %s"):format(i, v.Name, v.Desc))
    end
  end

  print("Public gists: " .. User.GistsCount)
  if Args.g or Args.gists then
    User:Fetch("gists")

    for i, v in ipairs(User.GistsArr) do
      print(("| %02d. %s"):format(i, v))
    end
  end

  print("Followers: " .. User.FollowersCount)
  if Args.f or Args.followers then
    User:Fetch("followers")

    for i, v in ipairs(User.FollowersArr) do
      print("| @" .. v)
    end
  end

  print("Following: " .. User.FollowingCount)
  if Args.F or Args.following then
    User:Fetch("following")

    for i, v in ipairs(User.FollowingArr) do
      print("| @" .. v)
    end
  end
end
