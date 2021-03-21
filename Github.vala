const string api_users_url = "https://api.github.com/users/";
const string user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36";

public struct GithubRepo {
  string name;
  string desc;
}

bool followers = false;
bool following = false;
bool repos     = false;
bool gists     = false;

const OptionEntry[] options = {
  { "followers", 'f', OptionFlags.NONE, OptionArg.NONE, ref followers, "Shows user followers", null },
  { "following", 'F', OptionFlags.NONE, OptionArg.NONE, ref following, "Shows user following", null },
  { "repos",     'r', OptionFlags.NONE, OptionArg.NONE, ref repos,     "Shows user repos",     null },
  { "gists",     'g', OptionFlags.NONE, OptionArg.NONE, ref gists,     "Shows user gists",     null },
  { null }
};

public class GithubUser : Object {
  private string      url;
  private Json.Object json;
  public string username { private get; construct; }

  public string name;
  public string bio ;
  public string link;
  public int64 repos_count;
  public int64 gists_count;
  public int64 followers_count;
  public int64 following_count;
  public GithubRepo[] repos_arr;
  public string[] gists_arr;
  public string[] followers_arr;
  public string[] following_arr;

  public GithubUser(string name) {
    Object(
      username: name
    );
  }

  construct {
    this.url = api_users_url + this.username;

    var session = new Soup.Session();
    var msg     = new Soup.Message("GET", this.url);
    var parser  = new Json.Parser();

    // Needed, otherwise, you'll get an error (status code 403)
    msg.request_headers.append("User-Agent", user_agent);
    session.send_message(msg);

    Soup.MessageBody res = msg.response_body;
    parser.load_from_data((string) res.data);

    this.json = parser.get_root().get_object();

    this.name            = this.json.get_string_member("name");
    this.bio             = this.json.get_string_member("bio");
    this.link            = this.json.get_string_member("html_url");
    this.repos_count     = this.json.get_int_member("public_repos");
    this.gists_count     = this.json.get_int_member("public_gists");
    this.followers_count = this.json.get_int_member("followers");
    this.following_count = this.json.get_int_member("following");
  }

  public void fetch(string kind) {
    Json.Array arr;
    var url = this.url + "/" + kind;

    var session = new Soup.Session();
    var msg     = new Soup.Message("GET", url);
    var parser  = new Json.Parser();

    msg.request_headers.append("User-Agent", user_agent);
    session.send_message(msg);

    Soup.MessageBody res = msg.response_body;
    parser.load_from_data((string) res.data);

    arr = parser.get_root().get_array();

    switch (kind) {
      case "repos": {
        this.repos_arr = new GithubRepo[arr.get_length()];

        arr.foreach_element((self, idx, node) => {
          var obj  = node.get_object();
          var name = obj.get_string_member("name");
          var desc = obj.get_string_member("description");
          this.repos_arr[idx] = GithubRepo() {
            name = name,
            desc = (desc == null) ? "(no description)" : desc
          };
        });

        break;
      }

      case "gists": {
        this.gists_arr = new string[arr.get_length()];

        arr.foreach_element((self, idx, node) => {
          var obj  = node.get_object();
          var desc = obj.get_string_member("description");
          this.gists_arr[idx] = desc;
        });

        break;
      }

      case "followers": {
        this.followers_arr = new string[arr.get_length()];

        arr.foreach_element((self, idx, node) => {
          var obj  = node.get_object();
          var user = obj.get_string_member("login");
          this.followers_arr[idx] = user;
        });

        break;
      }

      case "following": {
        this.following_arr = new string[arr.get_length()];

        arr.foreach_element((self, idx, node) => {
          var obj  = node.get_object();
          var user = obj.get_string_member("login");
          this.following_arr[idx] = user;
        });

        break;
      }

      default: {
        print("Unsupported endpoint: %s\n", kind);
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
      var user = new GithubUser(args[i]);

      print("Name: %s\n", user.name);
      print("Bio: %s\n",  user.bio);
      print("Link: %s\n", user.link);

      print(@"Public repos: $(user.repos_count)\n");
      if (repos) {
        user.fetch("repos");

        for (var x = 0; x < user.repos_arr.length; x++) {
          print("| %d. %s: %s\n", x + 1, user.repos_arr[x].name, user.repos_arr[x].desc);
        }
      }

      print(@"Public gists: $(user.gists_count)\n");
      if (gists) {
        user.fetch("gists");

        for (var x = 0; x < user.gists_arr.length; x++) {
          print("| %d. %s\n", x + 1, user.gists_arr[x]);
        }
      }

      print(@"Public followers: $(user.followers_count)\n");
      if (followers) {
        user.fetch("followers");

        for (var x = 0; x < user.followers_arr.length; x++) {
          print("| @%s\n", user.followers_arr[x]);
        }
      }

      print(@"Public following: $(user.following_count)\n");
      if (following) {
        user.fetch("following");

        for (var x = 0; x < user.following_arr.length; x++) {
          print("| @%s\n", user.following_arr[x]);
        }
      }

      print("\n");
    }
  }

  return 0;
}