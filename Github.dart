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
  String username;

  late String name;
  late String bio;
  late String link;
  late GthUserItem repos;
  late GthUserItem gists;
  late GthUserItem followers;
  late GthUserItem following;

  GthUser(this.username);

  static Future<GthUser> create(String user) async {
    final self = GthUser(user);
    var res = await http.get(Uri.parse(BASE_URL + self.username));
    var obj = jsonDecode(res.body);

    self.name = obj["name"];
    self.bio = obj["bio"];
    self.link = obj["html_url"];

    self.repos = GthUserItem(obj["public_repos"]);
    self.gists = GthUserItem(obj["public_gists"]);
    self.followers = GthUserItem(obj["followers"]);
    self.following = GthUserItem(obj["following"]);

    return self;
  }

  Future<void> fetch(String thing) async {
    var url = "${BASE_URL + this.username}/$thing";
    var res = await http.get(Uri.parse(url));
    var arr = jsonDecode(res.body);

    switch (thing) {
      case "repos":
        for (var v in arr)
          this.repos.arr.add(v["name"]);

        break;

      case "gists":
        for (var v in arr)
          this.gists.arr.add(v["description"]);

        break;

      case "followers":
        for (var v in arr)
          this.followers.arr.add(v["login"]);

        break;

      case "following":
        for (var v in arr)
          this.following.arr.add(v["login"]);

        break;

      default:
        break;
    }
  }
}

void showHelp() {
  print("Github [OPTIONS...] <USERNAMES...>");
  print("");
  print("Options:");
  print("  -r, --repos      Show user repos                                     [boolean]");
  print("  -g, --gists      Show user gists                                     [boolean]");
  print("  -f, --followers  Show user followers                                 [boolean]");
  print("  -F, --following  Show user following                                 [boolean]");
  print("  -h, --help       Show this help                                      [boolean]");
}

void main(final List<String> args) async {
  final parser = ArgParser();
  parser.addFlag("repos", abbr: "r", defaultsTo: false);
  parser.addFlag("gists", abbr: "g", defaultsTo: false);
  parser.addFlag("followers", abbr: "f", defaultsTo: false);
  parser.addFlag("following", abbr: "F", defaultsTo: false);
  parser.addFlag("help", abbr: "h", defaultsTo: false);

  final opts = parser.parse(args);

  if (opts["help"]) {
    showHelp();
    exit(0);
  }

  if (args.isEmpty) {
    print("Nothing to do.");
    print("Pass -h or --help to see the help.");
    exit(1);
  }

  for (final arg in opts.rest) {
    final user = await GthUser.create(arg);

    print("Name: ${user.name}");
    print("Bio: ${user.bio}");
    print("Link: ${user.link}");

    print("Public repos: ${user.repos.count}");
    if (opts["repos"]) {
      await user.fetch("repos");

      for (final r in user.repos.arr)
        print(" | $r");
    }

    print("Public gists: ${user.gists.count}");
    if (opts["gists"]) {
      await user.fetch("gists");

      for (final g in user.gists.arr)
        print(" | $g");
    }

    print("Followers: ${user.followers.count}");
    if (opts["followers"]) {
      await user.fetch("followers");

      for (final u in user.followers.arr)
        print(" | @$u");
    }

    print("Following: ${user.following.count}");
    if (opts["following"]) {
      await user.fetch("following");

      for (final u in user.following.arr)
        print(" | @$u");
    }

    print("");
  }
}