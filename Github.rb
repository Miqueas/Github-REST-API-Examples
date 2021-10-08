require 'net/http'
require 'optparse'
require 'ostruct'
require 'json'

err = OptionParser::ParseError.new('see -h or --help for details')
err.reason = 'No arguments'
raise err if ARGV.empty?

BASE_URL = 'https://api.github.com/users/'

opts = { followers: false, following: false, repos: false, gists: false }

OptionParser.new do |opt|
  opt.banner = "Usage: Github [options] <usernames...>"
  opt.on('-f', '--followers', 'Shows user followers') { opts[:followers] = true }
  opt.on('-F', '--following', 'Shows user following') { opts[:following] = true }
  opt.on('-r', '--repos', 'Shows user repos') { opts[:repos] = true }
  opt.on('-g', '--gists', 'Shows user gists') { opts[:gists] = true }
end.parse!

class GithubUser
  private
  attr_accessor :url, :json

  public
  attr_accessor :name, :bio, :link
  attr_accessor :repos, :gists, :followers, :following

  def initialize(username)
    type_err = TypeError.new("Bad argument for 'new'. String expected, got #{username.class}")
    raise type_err unless username.is_a? String

    @url = URI(BASE_URL + username)

    begin
      res = Net::HTTP.get(@url)
      @json = JSON.parse(res)
    rescue => err
      puts("Something went wrong! Here's some details:")
      puts(err.message)
    end

    @name = @json['name']     || ''
    @bio  = @json['bio']      || ''
    @link = @json['html_url'] || ''

    @repos     = { count: @json['public_repos'] || 0, arr: [] }
    @gists     = { count: @json['public_gists'] || 0, arr: [] }
    @followers = { count: @json['followers']    || 0, arr: [] }
    @following = { count: @json['following']    || 0, arr: [] }
  end

  def fetch(thing)
    type_err = TypeError.new("Bad argument for 'Fetch'. String expected, got #{thing.class}")
    raise type_err unless thing.is_a? String

    begin
      url = URI(@url.to_s() + '/' + thing)
      res = Net::HTTP.get(url)
      arr = JSON.parse(res)
    rescue => err
      puts("Something's went wrong! Here's some details:")
      puts(err.message)
    end

    case thing
      when 'repos'
        for val in arr do
          @repos[:arr].push(val[:name])
        end
      when 'gists'
        for val in arr do
          @gists[:arr].push(val[:description])
        end
      when 'followers'
        for val in arr do
          @followers[:arr].push('@' + val[:login])
        end
      when 'following'
        for val in arr do
          @following[:arr].push('@' + val[:login])
        end
      else
        puts("Unsupported endpoint: #{thing}")
    end
  end
end

for arg in ARGV
  user = GithubUser.new(arg)

  puts("Name: #{user.name}")
  puts("Bio: #{user.bio}")
  puts("Link: #{user.link}")

  puts("Public repos: #{user.repos[:count]}")
  if opts[:repos]
    user.fetch('repos')

    for i in 0 ... user.repos[:arr].size
      puts("| #{i + 1} #{user.repos[:arr][i]}")
    end
  end

  puts("Public gists: #{user.gists[:count]}")
  if opts[:gists]
    user.fetch('gists')

    for i in 0 ... user.gists[:arr].size
      puts("| #{i + 1}. #{user.gists[:arr][i]}")
    end
  end

  puts("Followers: #{user.followers[:count]}")
  if opts[:followers]
    user.fetch('followers')

    for v in user.followers[:arr]
      puts("| #{user.followers[:arr].index(v) + 1}. #{v}")
    end
  end

  puts("Following: #{user.following[:count]}")
  if opts[:following]
    user.fetch('following')

    for v in user.following[:arr]
      puts("| #{user.following[:arr].index(v) + 1}. #{v}")
    end
  end

  print("\n")
end