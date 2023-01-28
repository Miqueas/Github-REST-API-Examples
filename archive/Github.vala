#!/usr/bin/env valac Github.vala --pkg=json-glib-1.0 --pkg=libsoup-2.4

const string API_USERS_URL = "https://api.github.com/users/";
const string USER_AGENT    = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36";

bool followers;
bool following;
bool repos;
bool gists;

const OptionEntry[] options = {
  { "followers", 'f', OptionFlags.NONE, OptionArg.NONE, ref followers, "Shows user followers", null },
  { "following", 'F', OptionFlags.NONE, OptionArg.NONE, ref following, "Shows user following", null },
  { "repos",     'r', OptionFlags.NONE, OptionArg.NONE, ref repos,     "Shows user repos",     null },
  { "gists",     'g', OptionFlags.NONE, OptionArg.NONE, ref gists,     "Shows user gists",     null },
  { null }
};

public struct Gth.UserItem {
  int64    count;
  string[] arr;

  public UserItem(int64 count) {
    this.count = count;
    this.arr   = new string[count];
  }
}

public class Gth.User {
  private string      url;
  private Json.Object json;
  private string      username;

  public string name;
  public string bio;
  public string link;
  public Gth.UserItem repos;
  public Gth.UserItem gists;
  public Gth.UserItem followers;
  public Gth.UserItem following;

  public User(string name) {
    this.username = name;
    this.url      = API_USERS_URL + this.username;

    // The user agent is needed, otherwise, the server
    // will return an error (status code 403)
    var session = new Soup.Session.with_options("user-agent", USER_AGENT, null);
    var msg     = new Soup.Message("GET", this.url);
    var parser  = new Json.Parser();

    session.send_message(msg);
    parser.load_from_data((string) msg.response_body.data);

    this.json = parser.get_root().get_object();

    this.name = this.json.get_string_member("name");
    this.bio  = this.json.get_string_member("bio");
    this.link = this.json.get_string_member("html_url");

    this.repos     = Gth.UserItem(this.json.get_int_member("public_repos"));
    this.gists     = Gth.UserItem(this.json.get_int_member("public_gists"));
    this.followers = Gth.UserItem(this.json.get_int_member("followers"));
    this.following = Gth.UserItem(this.json.get_int_member("following"));
  }

  public void fetch(string thing) {
    Json.Array arr;
    var url = this.url + "/" + thing;

    var session = new Soup.Session.with_options("user-agent", USER_AGENT, null);
    var msg     = new Soup.Message("GET", url);
    var parser  = new Json.Parser();

    session.send_message(msg);
    parser.load_from_data((string) msg.response_body.data);

    arr = parser.get_root().get_array();

    switch (thing) {
      case "repos": {
        arr.foreach_element((self, idx, node) => {
          this.repos.arr[idx] = 
            node
              .get_object()
              .get_string_member("name");
        });

        break;
      }

      case "gists": {
        arr.foreach_element((self, idx, node) => {
          this.gists.arr[idx] =
            node
              .get_object()
              .get_string_member("description");
        });

        break;
      }

      case "followers": {
        arr.foreach_element((self, idx, node) => {
          this.followers.arr[idx] = 
            node
              .get_object()
              .get_string_member("login");
        });

        break;
      }

      case "following": {
        arr.foreach_element((self, idx, node) => {
          this.following.arr[idx] = 
            node
              .get_object()
              .get_string_member("login");
        });

        break;
      }

      default: {
        print("Unsupported endpoint: %s\n", thing);
        break;
      }
    }
  }
}

int main(string[] args) {
  var opt_ctx = new OptionContext();
  opt_ctx.add_main_entries(options, null);
  opt_ctx.parse(ref args);

  if (args.length == 1) {
    print("No arguments\n");
  } else {
    for (var i = 1; i < args.length; i++) {
      var user = new Gth.User(args[i]);

      print("Name: %s\n", user.name);
      print("Bio: %s\n",  user.bio);
      print("Link: %s\n", user.link);

      print(@"Repos: $(user.repos.count)\n");
      if (repos) {
        user.fetch("repos");

        for (var x = 0; x < user.repos.arr.length; x++)
          print("| %d. %s\n", x + 1, user.repos.arr[x]);
      }

      print(@"Gists: $(user.gists.count)\n");
      if (gists) {
        user.fetch("gists");

        for (var x = 0; x < user.gists.arr.length; x++)
          print("| %d. %s\n", x + 1, user.gists.arr[x]);
      }

      print(@"Followers: $(user.followers.count)\n");
      if (followers) {
        user.fetch("followers");

        for (var x = 0; x < user.followers.arr.length; x++)
          print("| @%s\n", user.followers.arr[x]);
      }

      print(@"Following: $(user.following.count)\n");
      if (following) {
        user.fetch("following");

        for (var x = 0; x < user.following.arr.length; x++)
          print("| @%s\n", user.following.arr[x]);
      }

      print("\n");
    }
  }

  return 0;
}