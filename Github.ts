import yargs from "https://deno.land/x/yargs@v17.4.0-deno/deno.ts";

const print = console.log;
const BASE_URL = "https://api.github.com/users/"

class GthUserItem {
  count: number;
  arr: string[];

  constructor(n: number) {
    this.count = n;
    this.arr = [];
  }
}

class GthUser {
  username: string;
  name!: string;
  bio!: string;
  link!: string;
  repos!: GthUserItem;
  gists!: GthUserItem;
  followers!: GthUserItem;
  following!: GthUserItem;

  constructor(username: string) {
    this.username = username;
  }

  static async init(user: string): Promise<GthUser> {
    let self = new GthUser(user);
    let url = BASE_URL + user;

    let res = await fetch(url);
    
    if (!res.ok) {
      throw new Error(`can't fetch url '${url}'`);
    }

    let obj = await res.json();

    self.name = obj.name;
    self.bio  = obj.bio;
    self.link = obj.html_url;

    self.repos = new GthUserItem(obj.public_repos);
    self.gists = new GthUserItem(obj.public_gists);
    self.followers = new GthUserItem(obj.followers);
    self.following = new GthUserItem(obj.following);

    return self;
  }

  async fetch(thing: string) {
    let url = `${BASE_URL + this.username}/${thing}`
    let res = await fetch(url);

    if (!res.ok) {
      throw new Error(`can't fetch url '${url}'`);
    }

    let arr = await res.json();

    switch (thing) {
      case "repos":
        for (const val of arr)
          this.repos.arr.push(val.name);
        break;

      case "gists":
        for (const val of arr)
          this.gists.arr.push(val.description);
        break;

      case "followers":
        for (const val of arr)
          this.followers.arr.push(val.login);
        break;

      case "following":
        for (const val of arr)
          this.following.arr.push(val.login);
        break;

      default:
        throw new Error(`unsupported endpoint: ${thing}`);
    }
  }
}

let opts = yargs(Deno.args)
  .version(false)
  .usage("$0 Github.ts [options...] <usernames...>")
  .option("repos", {
    alias: "r", type: "boolean", describe: "Show user repos"
  })
  .option("gists", {
    alias: "g", type: "boolean", describe: "Show user gists"
  })
  .option("followers", {
    alias: "f", type: "boolean", describe: "Show user followers"
  })
  .option("following", {
    alias: "F", type: "boolean", describe: "Show user following"
  })
  .help("help", "Show this help")
  .parse();

if (opts._.length <= 0) {
  print("Nothing to do.");
  Deno.exit(1);
}

for (const val of opts._) {
  let user = await GthUser.init(val);

  print(`Name: ${user.name}`);
  print(`Bio: ${user.bio}`);
  print(`Link: ${user.link}`);

  print();
}