import std.net.curl;
import std.getopt;
import std.regex;
import std.stdio;
import std.json;
import std.conv;

immutable BASE_URL = "https://api.github.com/users/";

struct GthUserItem {
  int count;
  string[] arr;

  this(long count) {
    this.count = to!int(count);
    // The length will change later
    this.arr   = new string[0];
  }
}

class GthUser {
  private string url;
  private JSONValue obj;

  string name;
  string bio;
  string link;
  GthUserItem repos;
  GthUserItem gists;
  GthUserItem followers;
  GthUserItem following;

  this(string username) {
    this.url = BASE_URL ~ username;

    auto res = get(this.url);
    this.obj = parseJSON(res);

    this.name = this.obj["name"].str;
    this.bio  = this.obj["bio"].str;
    this.link = this.obj["html_url"].str;
    this.repos = GthUserItem(this.obj["public_repos"].integer);
    this.gists = GthUserItem(this.obj["public_gists"].integer);
    this.followers = GthUserItem(this.obj["followers"].integer);
    this.following = GthUserItem(this.obj["following"].integer);
  }

  void fetch(string thing) {
    auto url = this.url ~ '/' ~ thing;
    auto res = get(url);
    auto arr = parseJSON(res).array;

    switch (thing) {
      case "repos":
        for (int i = 0; i < arr.length; i++) {
          this.repos.arr.length = arr.length;
          this.repos.arr[i] = arr[i]["name"].str;
        }
        break;

      case "gists":
        for (int i = 0; i < arr.length; i++) {
          this.gists.arr.length = arr.length;
          this.gists.arr[i] = arr[i]["description"].str;
        }
        break;

      case "followers":
        for (int i = 0; i < arr.length; i++) {
          this.followers.arr.length = arr.length;
          this.followers.arr[i] = arr[i]["login"].str;
        }
        break;

      case "following":
        for (int i = 0; i < arr.length; i++) {
          this.following.arr.length = arr.length;
          this.following.arr[i] = arr[i]["login"].str;
        }
        break;
      
      default: break;
    }
  }
}

void main(string[] args) {
  auto opts = [ "repos": false, "gists": false, "followers": false, "following": false ];
  auto help = getopt(args,
    // Prevent error when passing various flags like: -rgfF
    config.bundling,
    config.caseSensitive,
    "r|repos", "Shown repos", &(opts["repos"]),
    config.caseSensitive,
    "g|gists", "Shown gists", &(opts["gists"]),
    config.caseSensitive,
    "f|followers", "Shown followers", &(opts["followers"]),
    config.caseSensitive,
    "F|following", "Shown following", &(opts["following"])
  );

  if (help.helpWanted) {
    defaultGetoptPrinter("Usage: Github <usernames...>\n\nOptions:", help.options);
    return;
  }

  if (args.length > 0) {
    for (int i = 1; i < args.length; i++) {
      auto user = new GthUser(args[i]);
      writeln("Name: ", user.name);
      writeln("Bio: ", user.bio);
      writeln("Link: ", user.link);

      writeln("Public repos: ", user.repos.count);
      if (opts["repos"]) {
        user.fetch("repos");

        foreach (idx, val; user.repos.arr)
          writefln(" | %03d. %s", idx + 1, val);
      }

      writeln("Public gists: ", user.gists.count);
      if (opts["gists"]) {
        user.fetch("gists");

        foreach (idx, val; user.gists.arr)
          writefln(" | %03d. %s", idx + 1, val);
      }

      writeln("Followers: ", user.followers.count);
      if (opts["followers"]) {
        user.fetch("followers");

        foreach (name; user.followers.arr)
          writefln(" | @%s", name);
      }

      writeln("Following: ", user.following.count);
      if (opts["following"]) {
        user.fetch("following");

        foreach (name; user.following.arr)
          writefln(" | @%s", name);
      }
    }
  } else {
    writeln("No arguments, nothing to do.");
  }
}