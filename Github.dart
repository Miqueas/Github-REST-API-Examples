import 'package:args/args.dart';
import 'package:dio/dio.dart';
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
    var obj = await Dio().get(this._url).data;

    this.name = obj["name"];
    this.bio = obj["bio"];
    this.link = obj["html_url"];

    this.repos = GthUserItem(obj["public_repos"]);
    this.gists = GthUserItem(obj["public_gists"]);
    this.followers = GthUserItem(obj["followers"]);
    this.following = GthUserItem(obj["following"]);
  }

  Future<void> fetch(String thing) async {}
}

void main(List<String> args) async {
  var user = GthUser(args[0]);
  await user.init();
}