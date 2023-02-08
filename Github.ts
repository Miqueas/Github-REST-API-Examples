import yargs from "https://deno.land/x/yargs@v17.4.0-deno/deno.ts";

// Yeah I'm lazy af
const print = console.log;
const BASE_URL = "https://api.github.com/users/";

type GthUserItem = {
  count: number;
  arr: string[];
};

class GthUser {
  name: string = "";
  bio: string = "";
  link: string = "";
  repos: GthUserItem = { count: 0, arr: [] };
  gists: GthUserItem = { count: 0, arr: [] };
  followers: GthUserItem = { count: 0, arr: [] };
  following: GthUserItem = { count: 0, arr: [] };

  constructor(public username: string) {}

  static async create(user: string): Promise<GthUser> {
    let self = new GthUser(user);
    let url = BASE_URL + self.username;
    let res = await fetch(url);
    
    if (!res.ok)
      throw new Error(`can't fetch url '${url}'`);

    let obj = await res.json();

    self.name = obj.name;
    self.bio  = obj.bio;
    self.link = obj.html_url;

    self.repos.count = obj.public_repos;
    self.gists.count = obj.public_gists;
    self.followers.count = obj.followers;
    self.following.count = obj.following;

    return self;
  }

  async fetch(thing: string) {
    let url = `${BASE_URL + this.username}/${thing}`
    let res = await fetch(url);

    if (!res.ok)
      throw new Error(`can't fetch url '${url}'`);

    let arr = await res.json();

    switch (thing) {
      case "repos":
        for (const val of arr)
          this.repos?.arr.push(val.name);
        break;

      case "gists":
        for (const val of arr)
          this.gists?.arr.push(val.description);
        break;

      case "followers":
        for (const val of arr)
          this.followers?.arr.push(val.login);
        break;

      case "following":
        for (const val of arr)
          this.following?.arr.push(val.login);
        break;

      default:
        throw new Error(`unsupported endpoint: ${thing}`);
    }
  }
}

let opts = yargs(Deno.args)
  .version(false)
  .usage("Github [options...] <usernames...>")
  .option("repos", {
    alias: "r",
    type: "boolean",
    describe: "Show user repos"
  })
  .option("gists", {
    alias: "g",
    type: "boolean",
    describe: "Show user gists"
  })
  .option("followers", {
    alias: "f",
    type: "boolean",
    describe: "Show user followers"
  })
  .option("following", {
    alias: "F",
    type: "boolean",
    describe: "Show user following"
  })
  .help("help", "Show this help")
  .alias("h", "help")
  .parse();

if (opts._.length <= 0) {
  print("Nothing to do.");
  print("Pass -h or --help to see the help.");
  Deno.exit(1);
}

for (const val of opts._) {
  let user = await GthUser.create(val);

  print(`Name: ${user.name}`);
  print(`Bio: ${user.bio}`);
  print(`Link: ${user.link}`);

  print(`Public repos: ${user.repos?.count}`);
  if (opts.r) {
    await user.fetch("repos");

    if (user.repos)
      for (const idx in user.repos.arr)
        print(` | ${parseInt(idx) + 1} ${user.repos.arr[parseInt(idx)]}`);
  }

  print(`Public gists: ${user.gists?.count}`);
  if (opts.g) {
    await user.fetch("gists");

    if (user.gists)
      for (const idx in user.gists.arr)
        print(` | ${parseInt(idx) + 1} ${user.gists.arr[parseInt(idx)]}`);
  }

  print(`Public followers: ${user.followers?.count}`);
  if (opts.followers) {
    await user.fetch("followers");

    if (user.followers)
      for (const val of user.followers.arr)
        print(` | @${val}`);
  }

  print(`Public following: ${user.following?.count}`);
  if (opts.following) {
    await user.fetch("following");

    if (user.following)
      for (const val of user.following.arr)
        print(` | @${val}`);
  }

  print();
}