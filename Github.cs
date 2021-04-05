using System;
using System.Net;
using Mono.Options;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public class GithubUser {
  private const string APIUsersURL = "https://api.github.com/users/";
  private const string UserAgent   = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36";
  private Regex   fetch_patt       = new Regex( "(repos|gists|followers|following)" );
  private string  url;
  private JObject json;

  public struct GithubRepo {
    public string Name;
    public string Desc;

    public GithubRepo(string name, string desc) {
      Name = name;
      Desc = desc;
    }
  }

  public string Name;
  public string Bio;
  public string Link;
  public int ReposCount;
  public int GistsCount;
  public int FollowersCount;
  public int FollowingCount;
  public GithubRepo[] ReposArr;
  public string[] GistsArr;
  public string[] FollowersArr;
  public string[] FollowingArr;

  public GithubUser(string name) {
    url = APIUsersURL + name;

    var client = new WebClient();
    client.Headers.Add("user-agent", UserAgent);

    var res = client.DownloadString(this.url);
    json    = JObject.Parse(res);

    this.Name           = json.Value<string>("name");
    this.Bio            = json.Value<string>("bio");
    this.Link           = json.Value<string>("html_url");
    this.ReposCount     = json.Value<int>("public_repos");
    this.GistsCount     = json.Value<int>("public_gists");
    this.FollowersCount = json.Value<int>("followers");
    this.FollowingCount = json.Value<int>("following");
  }

  public void Fetch(string kind) {
    if (!fetch_patt.Match(kind).Success) {
      Console.WriteLine($"Unsupported endpoint: {kind}");
      return;
    }

    var url    = this.url +  "/" + kind;
    var client = new WebClient();
    client.Headers.Add("user-agent", UserAgent);

    var res = client.DownloadString(url);
    var arr = JArray.Parse(res);

    if (kind == "repos") {
      this.ReposArr = new GithubRepo[arr.Count];

      for (int i = 0; i < arr.Count; i++) {
        var name = arr[i].Value<string>("name");
        var desc = arr[i].Value<string>("description");
        this.ReposArr[i] = new GithubRepo(name, desc);
      }
    } else if (kind == "gists") {
      this.GistsArr = new string[arr.Count];

      for (int i = 0; i < arr.Count; i++) {
        var desc = arr[i].Value<string>("description");
        this.GistsArr[i] = desc;
      }
    } else if (kind == "followers") {
      this.FollowersArr = new string[arr.Count];

      for (int i = 0; i < arr.Count; i++) {
        var user = arr[i].Value<string>("login");
        this.FollowersArr[i] = user;
      }
    } else if (kind == "following") {
      this.FollowingArr = new string[arr.Count];

      for (int i = 0; i < arr.Count; i++) {
        var user = arr[i].Value<string>("login");
        this.FollowingArr[i] = user;
      }
    }
  }
}

public class App {
  public static void Main(string[] argv) {
    var followers = false;
    var following = false;
    var repos = false;
    var gists = false;

    var opts = new OptionSet {
      { "f|followers", "Shows user followers", f => followers = f != null },
      { "F|following", "Shows user following", F => following = F != null },
      { "r|repos", "Shows user repos", r => repos = r != null },
      { "g|gists", "Shows user gists", g => gists = g != null }
    };

    List<string> args = opts.Parse(argv);

    if (args.Count > 0) {
      foreach (string name in args) {
        var user = new GithubUser(name);

        Console.WriteLine($"Name: {user.Name}");
        Console.WriteLine($"Bio: {user.Bio}");
        Console.WriteLine($"Link: {user.Link}");

        // Repos
        Console.WriteLine($"Public repos: {user.ReposCount}");
        if (repos) {
          user.Fetch("repos");

          for (var i = 0; i < user.ReposArr.Length; i++) {
            Console.WriteLine($"| {i + 1}. {user.ReposArr[i].Name}: {user.ReposArr[i].Desc}");
          }
        }

        // Gists
        Console.WriteLine($"Public gists: {user.GistsCount}");
        if (gists) {
          user.Fetch("gists");

          for (var i = 0; i < user.GistsArr.Length; i++) {
            Console.WriteLine($"| {i + 1}. {user.GistsArr[i]}");
          }
        }

        // Followers
        Console.WriteLine($"Followers: {user.FollowersCount}");
        if (followers) {
          user.Fetch("followers");

          for (var i = 0; i < user.FollowersArr.Length; i++) {
            Console.WriteLine($"| @{user.FollowersArr[i]}");
          }
        }

        // Following
        Console.WriteLine($"Following: {user.FollowingCount}");
        if (following) {
          user.Fetch("following");

          for (var i = 0; i < user.FollowingArr.Length; i++) {
            Console.WriteLine($"| @{user.FollowingArr[i]}");
          }
        }

        Console.Write("\n");
      }
    } else {
      Console.WriteLine("No arguments");
      return;
    }
  }
}