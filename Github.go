// Ghost: an small cli Gists utility
package main

import (
  OS "os"
  Fmt "fmt"
  Flag "flag"
  Str "strings"
  Bytes "bytes"
  HTTP "net/http"
  IOUtil "io/ioutil"
  JSON "encoding/json"
)

const APIUsersURL = "https://api.github.com/users/"

// Commandline flags
var ShowFollowers = Flag.Bool("followers", false, "Show a list of who follow this user")
var ShowFollowing = Flag.Bool("following", false, "Show a list of who the user follow")
var ShowRepos     = Flag.Bool("repos", false, "Show a list of public user repos")
var ShowGists     = Flag.Bool("gists", false, "Show a list of public user gists")

// The type Githubuser holds some basic information
type GithubUser struct {
  // Private
  dec *JSON.Decoder
  obj map[string]interface{}
  url string
  // Public
  Name string
  Bio string
  Link string
  ReposCount float64
  GistsCount float64
  FollowersCount float64
  FollowingCount float64
  ReposArr []map[string]string
  GistsArr []string
  FollowersArr []string
  FollowingArr []string
}

// Error checking function
func Check(e error, msg string, args ...interface{}) {
  if e != nil {
    Fmt.Printf(msg, args...)
    panic(e)
  }
}

func main() {
  Flag.Parse()

  var args = Flag.Args()
  var argc = len(args)

  if argc == 0 {
    Fmt.Println("No arguments, exiting!")
    OS.Exit(1)
  } else {
    for _, v := range args {
      var user = NewGithubUser(v)

      Fmt.Printf(
        "Name: %s\nBio: %s\nLink: %s\n",
        user.Name, user.Bio, user.Link,
      )

      Fmt.Printf("Public repos: %.0f\n", user.ReposCount)
      if *ShowRepos {
        user.Fetch("repos")

        if len(user.ReposArr) != 0 {
          for i, v := range user.ReposArr {
            Fmt.Printf("| %03d. %s: %s\n", i + 1, v["Name"], v["Desc"])
          }
        }
      }

      Fmt.Printf("Public gists: %.0f\n", user.GistsCount)
      if *ShowGists {
        user.Fetch("gists")

        if len(user.GistsArr) != 0 {
          for i, v := range user.GistsArr {
            Fmt.Printf("| %03d. %s\n", i + 1, v)
          }
        }
      }

      Fmt.Printf("Followers: %.0f\n", user.FollowersCount)
      if *ShowFollowers {
        user.Fetch("followers")

        if len(user.FollowersArr) != 0 {
          for _, v := range user.FollowersArr {
            Fmt.Printf("| @%s\n", v)
          }
        }
      }

      Fmt.Printf("Following: %.0f\n", user.FollowingCount)
      if *ShowFollowing {
        user.Fetch("following")

        if len(user.FollowingArr) != 0 {
          for _, v := range user.FollowingArr {
            Fmt.Printf("| @%s\n", v)
          }
        }
      }

      Fmt.Println()
      user = nil
    }
  }
}

// GithubUser "constructor"
func NewGithubUser(username string) *GithubUser {
  var self = &GithubUser{}

  var err error
  var url = APIUsersURL + username
  self.url = url

  res, err := HTTP.Get(url)
  Check(err, "Error fetching url: %s\n", url)

  defer res.Body.Close()

  cont, err := IOUtil.ReadAll(res.Body)
  Check(err, "Error reading response content.\n")

  var read = Str.NewReader(string(cont))

  self.dec = JSON.NewDecoder(read)
  Check(self.dec.Decode(&self.obj), "Error decoding the JSON response.\n")

  self.Name          , _ = self.obj["name"].(string)
  self.Bio           , _ = self.obj["bio"].(string)
  self.Link          , _ = self.obj["html_url"].(string)
  self.ReposCount    , _ = self.obj["public_repos"].(float64)
  self.GistsCount    , _ = self.obj["public_gists"].(float64)
  self.FollowersCount, _ = self.obj["followers"].(float64)
  self.FollowingCount, _ = self.obj["following"].(float64)

  return self
}

// Fills an array with info of: repos, gists, followers and following
func (self *GithubUser) Fetch(kind string) {
  var arr []map[string]interface{}
  var dec *JSON.Decoder
  var err error
  var url = self.url + "/" + kind

  res, err := HTTP.Get(url)
  Check(err, "Error fetching gists.\n")

  defer res.Body.Close()

  cont, err := IOUtil.ReadAll(res.Body)
  Check(err, "Error reading the gists response.\n")

  var read = Str.NewReader(string(cont))
  dec = JSON.NewDecoder(read)
  Check(dec.Decode(&arr), "Error decoding the gists JSON response.\n")

  switch kind {
    case "repos":
      self.ReposArr = make([]map[string]string, len(arr))

      for i, v := range arr {
        var name, _ = v["name"].(string)
        var desc, _ = v["description"].(string)
        self.ReposArr[i] = map[string]string { "Name": name, "Desc": desc }
      }

    case "gists":
      self.GistsArr = make([]string, len(arr))

      for i, v := range arr {
        var desc, _ = v["description"].(string)
        self.GistsArr[i] = desc
      }

    case "followers":
      self.FollowersArr = make([]string, len(arr))

      for i, v := range arr {
        var username, _ = v["login"].(string)
        self.FollowersArr[i] = username
      }

    case "following":
      self.FollowingArr = make([]string, len(arr))

      for i, v := range arr {
        var username, _ = v["login"].(string)
        self.FollowingArr[i] = username
      }

    default:
      Fmt.Println("Unsupported endpoint:", kind)
  }
}