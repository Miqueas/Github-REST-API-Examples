using System;
using System.Net;
using Mono.Options;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Gth {
  public struct UserItem {
    public int      Count;
    public string[] Arr;

    public UserItem(int count) {
      Count = count;
      Arr   = new string[count];
    }
  }

  public class User {
    private const string API_USERS_URL = "https://api.github.com/users/";
    private const string USER_AGENT    = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36";
    private Regex fetch_patt = new Regex( "(repos|gists|followers|following)" );
    private string url;
    private JObject json;

    public string Name;
    public string Bio;
    public string Link;
    public UserItem Repos;
    public UserItem Gists;
    public UserItem Followers;
    public UserItem Following;

    public User(string name) {
      this.url = API_USERS_URL + name;

      var client = new WebClient();
      client.Headers.Add("user-agent", USER_AGENT);

      var res   = client.DownloadString(this.url);
      json = JObject.Parse(res);

      this.Name = json.Value<string>("name");
      this.Bio  = json.Value<string>("bio");
      this.Link = json.Value<string>("html_url");

      this.Repos     = new UserItem(json.Value<int>("public_repos"));
      this.Gists     = new UserItem(json.Value<int>("public_gists"));
      this.Followers = new UserItem(json.Value<int>("followers"));
      this.Following = new UserItem(json.Value<int>("following"));
    }

    public void Fetch(string thing) {
      if (!fetch_patt.Match(thing).Success) {
        Console.WriteLine($"Unsupported endpoint: {thing}");
        return;
      }

      var url    = this.url +  "/" + thing;
      var client = new WebClient();
      client.Headers.Add("user-agent", USER_AGENT);

      var res = client.DownloadString(url);
      var arr = JArray.Parse(res);

      if (thing == "repos") {
        for (int i = 0; i < arr.Count; i++)
          this.Repos.Arr[i] = arr[i].Value<string>("name");
      } else if (thing == "gists") {
        for (int i = 0; i < arr.Count; i++)
          this.Gists.Arr[i] = arr[i].Value<string>("description");
      } else if (thing == "followers") {
        for (int i = 0; i < arr.Count; i++)
          this.Followers.Arr[i] = arr[i].Value<string>("login");
      } else if (thing == "following") {
        for (int i = 0; i < arr.Count; i++)
          this.Following.Arr[i] = arr[i].Value<string>("login");
      }
    }
  }
}

public class App {
  public static bool followers = false;
  public static bool following = false;
  public static bool repos = false;
  public static bool gists = false;

  public static OptionSet opts = new OptionSet {
    { "f|followers", "Shows user followers", f => followers = f != null },
    { "F|following", "Shows user following", F => following = F != null },
    { "r|repos", "Shows user repos", r => repos = r != null },
    { "g|gists", "Shows user gists", g => gists = g != null }
  };

  public static void Main(string[] argv) {
    List<string> args = opts.Parse(argv);

    if (!(args.Count > 0)) {
      Console.WriteLine("No arguments");
      return;
    } else {
      foreach (string name in args) {
        var user = new Gth.User(name);

        Console.WriteLine($"Name: {user.Name}");
        Console.WriteLine($"Bio: {user.Bio}");
        Console.WriteLine($"Link: {user.Link}");

        Console.WriteLine($"Repos: {user.Repos.Count}");
        if (repos) {
          user.Fetch("repos");

          for (var i = 0; i < user.Repos.Arr.Length; i++)
            Console.WriteLine($"| {i + 1}. {user.Repos.Arr[i]}");
        }

        Console.WriteLine($"Gists: {user.Gists.Count}");
        if (gists) {
          user.Fetch("gists");

          for (var i = 0; i < user.Gists.Arr.Length; i++)
            Console.WriteLine($"| {i + 1}. {user.Gists.Arr[i]}");
        }

        Console.WriteLine($"Followers: {user.Followers.Count}");
        if (followers) {
          user.Fetch("followers");

          for (var i = 0; i < user.Followers.Arr.Length; i++)
            Console.WriteLine($"| @{user.Followers.Arr[i]}");
        }

        Console.WriteLine($"Following: {user.Following.Count}");
        if (following) {
          user.Fetch("following");

          for (var i = 0; i < user.Following.Arr.Length; i++)
            Console.WriteLine($"| @{user.Following.Arr[i]}");
        }

        Console.Write("\n");
      }
    }
  }
}