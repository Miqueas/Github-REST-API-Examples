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

  void init() async {}
}

void main(List<String> args) async {
  var user = GthUser(args[0]);
  user.init();
  print(user._url);
}