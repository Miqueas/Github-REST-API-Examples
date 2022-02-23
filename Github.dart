import 'package:http/http.dart' as http;
import 'package:args/args.dart';
import 'dart:convert';
import 'dart:io';

const BASE_URL = "https://api.github.com/users/";

class GthUserItem {
  int count;
  var arr = <String>[];

  GthUserItem(this.count);
}

class GthUser {
  late String _url;

  late String name;
  late String bio;
  late String link;
  late GthUserItem repos;
  late GthUserItem gists;
  late GthUserItem followers;
  late GthUserItem following;

  GthUser(String username) : this._url = BASE_URL + username;

  Future<void> init() async {
    var res = await http.get(Uri.parse(this._url));
    var obj = jsonDecode(res.body);

    this.name = obj["name"];
    this.bio = obj["bio"];
    this.link = obj["html_url"];

    this.repos = GthUserItem(obj["public_repos"]);
    this.gists = GthUserItem(obj["public_gists"]);
    this.followers = GthUserItem(obj["followers"]);
    this.following = GthUserItem(obj["following"]);
  }

  Future<void> fetch(String thing) async {
    var url = "${this._url}/$thing";
    var res = await http.get(Uri.parse(url));
    var arr = jsonDecode(res.body);

    switch (thing) {
      case "repos":
        for (var v in arr) this.repos.arr.add(v["name"]);
        break;
      case "gists":
        for (var v in arr) this.gists.arr.add(v["description"]);
        break;
      case "followers":
        for (var v in arr) this.followers.arr.add(v["login"]);
        break;
      case "following":
        for (var v in arr) this.following.arr.add(v["login"]);
        break;
      default: break;
    }
  }
}

void main(List<String> args) async {
  var parser = ArgParser();
  parser.addFlag("repos", abbr: "r", defaultsTo: false);
  parser.addFlag("gists", abbr: "g", defaultsTo: false);
  parser.addFlag("followers", abbr: "f", defaultsTo: false);
  parser.addFlag("following", abbr: "F", defaultsTo: false);

  var opts = parser.parse(args);
  args = opts.rest;

  if (args.isNotEmpty) {
    for (var arg in args) {
      var user = GthUser(arg);
      await user.init();

      print("Name: ${user.name}");
      print("Bio: ${user.bio}");
      print("Link: ${user.link}");

      print("Public repos: ${user.repos.count}");
      if (opts["repos"]) {
        await user.fetch("repos");

        for (var i = 0; i < user.repos.arr.length; i++)
          print(" | ${i + 1}. ${user.repos.arr[i]}");
      }

      print("Public gists: ${user.gists.count}");
      if (opts["gists"]) {
        await user.fetch("gists");

        for (var i = 0; i < user.gists.arr.length; i++)
          print(" | ${i + 1}. ${user.gists.arr[i]}");
      }

      print("Followers: ${user.followers.count}");
      if (opts["followers"]) {
        await user.fetch("followers");

        for (var i = 0; i < user.followers.arr.length; i++)
          print(" | ${i + 1}. ${user.followers.arr[i]}");
      }

      print("Following: ${user.following.count}");
      if (opts["following"]) {
        await user.fetch("following");

        for (var i = 0; i < user.following.arr.length; i++)
          print(" | ${i + 1}. ${user.following.arr[i]}");
      }
    }
  } else {
    print("No arguments, nothing to do.");
  }
}