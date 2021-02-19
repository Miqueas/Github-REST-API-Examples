require 'net/http'
require 'optparse'
require 'ostruct'
require 'json'

APIUsersURL = 'https://api.github.com/users/'

class GithubUser
  private
  attr_accessor :Url, :Json

  public
  attr_accessor :Name, :Bio, :Link
  attr_accessor :ReposCount, :GistsCount, :FollowersCount, :FollowingCount
  attr_accessor :ReposArr, :GistsArr, :FollowersArr, :FollowingArr

  def initialize(username)
    type_err = TypeError.new "Bad argument for 'new'. String expected, got #{username.class}"
    raise type_err if !username.is_a? String

    @Url = URI APIUsersURL + username

    begin
      res = Net::HTTP.get_response @Url
      @Json = JSON.parse res.body
    rescue => err
      puts "Something's went wrong! Here's some details:"
      puts err.message
    end

    @Name           = @Json['name']         || ''
    @Bio            = @Json['bio']          || ''
    @Link           = @Json['html_url']     || ''
    @ReposCount     = @Json['public_repos'] || 0
    @GistsCount     = @Json['public_gists'] || 0
    @FollowersCount = @Json['followers']    || 0
    @FollowingCount = @Json['following']    || 0
    @ReposArr       = []
    @GistsArr       = []
    @FollowersArr   = []
    @FollowingArr   = []
  end

  def Fetch(kind)
    type_err = TypeError.new "Bad argument for 'Fetch'. String expected, got #{kind.class}"
    raise type_err if !kind.is_a? String

    begin
      url = URI @Url.to_s + '/' + kind
      res = Net::HTTP.get_response url
      arr = JSON.parse res.body
    rescue => err
      puts "Something's went wrong! Here's some details:"
      puts err.message
    end

    case kind
      when 'repos'
        for val in arr do @ReposArr.push({ Name: val['name'], Desc: val['description'] }) end

      when 'gists'
        for val in arr do @GistsArr.push val['description'] end

      when 'followers'
        for val in arr do @FollowersArr.push '@' + val['login'] end

      when 'following'
        for val in arr do @FollowingArr.push '@' + val['login'] end

      else
        puts "Unsupported endpoint: #{kind}"
    end
  end
end

opts = { Followers: false, Following: false, Repos: false, Gists: false }

OptionParser.new do |opt|
  opt.banner = "Usage: Github [options] <usernames...>"

  opt.on('-f', '--followers', 'Shows user followers') { opts[:Followers] = true }
  opt.on('-F', '--following', 'Shows user following') { opts[:Following] = true }
  opt.on('-r', '--repos', 'Shows user repos') { opts[:Repos] = true }
  opt.on('-g', '--gists', 'Shows user gists') { opts[:Gists] = true }
end.parse!

if ARGV.size == 0
  err = OptionParser::ParseError.new 'see -h or --help for details'
  err.reason = 'No arguments'
  raise err

else
  for arg in ARGV
    user = GithubUser.new arg

    puts "Name: #{user.Name}"
    puts "Bio: #{user.Bio}"
    puts "Link: #{user.Link}"

    puts "Public repos: #{user.ReposCount}"
    if opts[:Repos]
      user.Fetch 'repos'

      for i in 0 ... user.ReposArr.size
        puts "| #{i + 1} #{user.ReposArr[i][:Name]}: #{user.ReposArr[i][:Desc]}"
      end
    end

    puts "Public gists: #{user.GistsCount}"
    if opts[:Gists]
      user.Fetch 'gists'

      for i in 0 ... user.GistsArr.size
        puts "| #{i + 1}. #{user.GistsArr[i]}"
      end
    end

    puts "Followers: #{user.FollowersCount}"
    if opts[:Followers]
      user.Fetch 'followers'

      for v in user.FollowersArr
        puts "| #{user.FollowersArr.index(v) + 1}. #{v}"
      end
    end

    puts "Following: #{user.FollowingCount}"
    if opts[:Following]
      user.Fetch 'following'

      for v in user.FollowingArr
        puts "| #{user.FollowingArr.index(v) + 1}. #{v}"
      end
    end

    print "\n"
  end
end