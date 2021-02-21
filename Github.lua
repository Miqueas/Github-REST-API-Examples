-- luarocks install lua-requests
local Requests = require("requests")
-- luarocks install rapidjson
local JSON     = require("rapidjson")

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

user = GithubUser:new('M1que4s')
print(user.Name, user.Bio, user.Link)
user:Fetch("repos")
user:Fetch("gists")
