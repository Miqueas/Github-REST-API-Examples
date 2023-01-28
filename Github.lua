local req      = require("requests")
local json     = require("rapidjson")
local argparse = require("argparse")

-- Base url for requests
local BASE_URL = "https://api.github.com/users/"

---@class GthUser @Class for a github user basic info
---@field url       string (private) Url to make requests, for internal usage
---@field json      table  (private) Json response of the request
---@field name      string (public)  User name as shown in the github profile
---@field bio       string (public)  User bio as shown in the github profile
---@field link      string (public)  User profile url
---@field repos     table  (public)  Public user repositories
---@field gists     table  (public)  Public user gists
---@field followers table  (public)  User followers
---@field following table  (public)  User following
local GthUser = {}

--- Constructor for GthUser class
---@param username string The github username to get info
---@return GthUser
function GthUser:init(username)
  assert(
    type(username) == "string",
    "Bad argument for 'init', string expected, got " .. type(username)
  )

  self.url = BASE_URL .. username
  local res = req.get(self.url)
  self.json = json.decode(res.text)

  self.name = self.json['name']
  self.bio  = self.json['bio']
  self.link = self.json['html_url']

  self.repos = { count = self.json['public_repos'], arr = {} }
  self.gists = { count = self.json['public_gists'], arr = {} }
  self.followers = { count = self.json['followers'],    arr = {} }
  self.following = { count = self.json['following'],    arr = {} }

  return self
end

--- Gets the requested data (repos, gists, followers and following)
---@param thing string The data to request
---@return nil
function GthUser:fetch(thing)
  assert(
    type(thing) == "string",
    "Bad argument for 'fetch', string expected, got " .. type(thing)
  )

  local url = self.url .. '/' .. thing
  local res = req.get(url)
  local arr = json.decode(res.text)

  if thing == "repos" then
    for i, v in ipairs(arr) do
      self.repos.arr[i] = v["name"]
    end
  elseif thing == "gists" then
    for i, v in ipairs(arr) do
      self.gists.arr[i] = v["description"]
    end
  elseif thing == "followers" then
    for i, v in ipairs(arr) do
      self.followers.arr[i] = v["login"]
    end
  elseif thing == "following" then
    for i, v in ipairs(arr) do
      self.following.arr[i] = v["login"]
    end
  else
    return error("Unsupported endpoint: " .. thing)
  end
end

local opts = argparse({
  name = "Github.lua",
  description = "Simple example of the Github's REST API",
  epilog = "Check out https://github.com/M1que4s/Github-REST-API-Example"
})

opts:argument("usernames", "One or more usernames"):args("+")
opts:flag("-f --followers", "Shows user followers", false)
opts:flag("-F --following", "Shows user following", false)
opts:flag("-r --repos", "Shows user repos", false)
opts:flag("-g --gists", "Shows user gists", false)

local args = opts:parse(arg)

for _, user in ipairs(args.usernames) do
  local user = GthUser:init(user)

  print("name: " .. user.name)
  print("bio: " .. user.bio)
  print("link: " .. user.link)

  print("Public repos: " .. user.repos.count)
  if args.r or args.repos then
    user:fetch("repos")

    for i, v in ipairs(user.repos.arr) do
      print(("| %02d %s: %s"):format(i, v.name, v.Desc))
    end
  end

  print("Public gists: " .. user.gists.count)
  if args.g or args.gists then
    user:fetch("gists")

    for i, v in ipairs(user.gists.arr) do
      print(("| %02d. %s"):format(i, v))
    end
  end

  print("Followers: " .. user.followers.count)
  if args.f or args.followers then
    user:fetch("followers")

    for _, v in ipairs(user.followers.arr) do
      print("| @" .. v)
    end
  end

  print("Following: " .. user.following.count)
  if args.F or args.following then
    user:fetch("following")

    for _, v in ipairs(user.following.arr) do
      print("| @" .. v)
    end
  end

  print()
end
