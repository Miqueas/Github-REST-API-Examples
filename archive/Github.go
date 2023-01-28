package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strings"
	"flag"
	"fmt"
	"os"
)

const API_USERS_URL = "https://api.github.com/users/"

var show_repos     = flag.Bool("repos",     false, "Show a list of public user repos")
var show_gists     = flag.Bool("gists",     false, "Show a list of public user gists")
var show_followers = flag.Bool("followers", false, "Show a list of who follow this user")
var show_following = flag.Bool("following", false, "Show a list of who the user follow")

type GthUserItem struct {
	Count float64
	Arr   []string
}

type GthUser struct {
	// Private
	dec *json.Decoder
	obj map[string]interface{}
	url string
	// Public
	Name      string
	Bio       string
	Link      string
	Repos     *GthUserItem
	Gists     *GthUserItem
	Followers *GthUserItem
	Following *GthUserItem
}

func check(e error, msg string, args ...interface{}) {
	if e != nil {
		fmt.Printf(msg, args...)
		panic(e)
	}
}

func main() {
	flag.Parse()

	var args = flag.Args()
	var argc = len(args)

	if argc == 0 {
		fmt.Println("No arguments, exiting!")
		os.Exit(1)
	} else {
		for _, v := range args {
			var user = NewGthUser(v)

			fmt.Printf(
				"Name: %s\nBio: %s\nLink: %s\n",
				user.Name, user.Bio, user.Link,
			)

			fmt.Printf("Public repos: %.0f\n", user.Repos.Count)
			if *show_repos {
				user.Fetch("repos")

				if len(user.Repos.Arr) != 0 {
					for i, v := range user.Repos.Arr {
						fmt.Printf("| %03d. %s\n", i+1, v)
					}
				}
			}

			fmt.Printf("Public gists: %.0f\n", user.Gists.Count)
			if *show_gists {
				user.Fetch("gists")

				if len(user.Gists.Arr) != 0 {
					for i, v := range user.Gists.Arr {
						fmt.Printf("| %03d. %s\n", i+1, v)
					}
				}
			}

			fmt.Printf("Followers: %.0f\n", user.Followers.Count)
			if *show_followers {
				user.Fetch("followers")

				if len(user.Followers.Arr) != 0 {
					for _, v := range user.Followers.Arr {
						fmt.Printf("| @%s\n", v)
					}
				}
			}

			fmt.Printf("Following: %.0f\n", user.Following.Count)
			if *show_following {
				user.Fetch("following")

				if len(user.Following.Arr) != 0 {
					for _, v := range user.Following.Arr {
						fmt.Printf("| @%s\n", v)
					}
				}
			}

			fmt.Println()
			user = nil
		}
	}
}

func NewGthUserItem(count float64) *GthUserItem {
	var self = &GthUserItem{}
	self.Count = count
	self.Arr = make([]string, int(count))
	return self
}

func NewGthUser(username string) *GthUser {
	var self = &GthUser{}

	var err error
	var url = API_USERS_URL + username
	self.url = url

	res, err := http.Get(url)
	check(err, "Error fetching url: %s\n", url)

	defer res.Body.Close()

	cont, err := ioutil.ReadAll(res.Body)
	check(err, "Error reading response content.\n")

	var read = strings.NewReader(string(cont))

	self.dec = json.NewDecoder(read)
	check(self.dec.Decode(&self.obj), "Error decoding the json response.\n")

	self.Name, _ = self.obj["name"].(string)
	self.Bio,  _ = self.obj["bio"].(string)
	self.Link, _ = self.obj["html_url"].(string)

	self.Repos     = NewGthUserItem(self.obj["public_repos"].(float64))
	self.Gists     = NewGthUserItem(self.obj["public_gists"].(float64))
	self.Followers = NewGthUserItem(self.obj["followers"].(float64))
	self.Following = NewGthUserItem(self.obj["following"].(float64))

	return self
}

func (self *GthUser) Fetch(thing string) {
	var arr []map[string]interface{}
	var dec *json.Decoder
	var err error
	var url = self.url + "/" + thing

	res, err := http.Get(url)
	check(err, "Error fetching %s.\n", thing)

	defer res.Body.Close()

	cont, err := ioutil.ReadAll(res.Body)
	check(err, "Error reading the %s response.\n", thing)

	var read = strings.NewReader(string(cont))
	dec = json.NewDecoder(read)
	check(dec.Decode(&arr), "Error decoding the %s json response.\n", thing)

	switch thing {
	case "repos":
		for i, v := range arr {
			self.Repos.Arr[i], _ = v["name"].(string)
		}

	case "gists":
		for i, v := range arr {
			self.Gists.Arr[i], _ = v["description"].(string)
		}

	case "followers":
		for i, v := range arr {
			self.Followers.Arr[i], _ = v["login"].(string)
		}

	case "following":
		for i, v := range arr {
			self.Following.Arr[i], _ = v["login"].(string)
		}

	default:
		fmt.Println("Unsupported endpoint:", thing)
	}
}
