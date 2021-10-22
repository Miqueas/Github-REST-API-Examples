# TODO: write the example

type
  GthUserItem = ref object
    count: int
    arr: seq[string]

  GthUser = ref object
    name: string
    bio: string
    link: string
    repos: GthUserItem
    gists: GthUserItem
    followers: GthUserItem
    following: GthUserItem