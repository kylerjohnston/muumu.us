---
title: "Discovering new music with Ruby"
date: 2020-04-26
layout: post
categories: 
tags: 
- ruby 
- nmfbot
---
*tl;dr This post describes the process of writing a Ruby program to make Spotify playlists with the most popular tracks from lists of new album releases scraped from Reddit. You can see the program I ended up making here, if you don&rsquo;t want to read through it all: <https://github.com/kylerjohnston/nmfbot>*


# The problem: I need more music

I&rsquo;ve been listening to a lot more music since I&rsquo;ve started working exclusively from home the past couple months. I find music helps me work most of the time, but I dislike wearing headphones all day so I end up not listening to much when I&rsquo;m in the office.

Now that I&rsquo;m home all day, and listening to music on my stereo for most of it, I find myself wanting to listen to new things. I&rsquo;m also getting back into record collecting, a hobby I gave up due to lack of space after I moved across the country for grad school a few years back, and want to find some new artists to support.

Let me tell you, kids, the music scene isn&rsquo;t what it used to be. Or I&rsquo;m old, I guess. It&rsquo;s hard for me to discover new music now. Pitchfork has been bad for the last ten years (and, tbh, it was probably always bad); Tiny Mix Tapes is &ldquo;on hiatus&rdquo; (R.I.P.). The new releases Spotify recommends me are mostly from 90s and early 00s indie dudes who are in their 50s now &#x2014; not to rag on them, but I&rsquo;m really looking for something *new*.

The [/r/indieheads](https://reddit.com/r/indieheads/) subreddit has a weekly thread called &ldquo;New Music Friday&rdquo; where they&#x2026; list a bunch of new releases from that week. It&rsquo;s a real gold mine, but with like 50+ albums a week it&rsquo;s hard to dig through. I definitely don&rsquo;t have the time to go through and listen to every one of these albums, or even look up every one of them on Spotify by hand.

I wanted a way to sample all of these quickly and pick out the ones that sound most interesting so I can listen to them more closely. As a bona fide DevOps professional, I felt I had to automate this. 

I planned to write a program that would do the following things:

1.  Find the most recent New Music Friday thread by pulling the link from the /r/indieheads sidebar;
2.  Scrape artist name and album title for each new release in that submission;
3.  Create a Spotify playlist of the most popular tracks from each album.

I also wanted to use the opportunity to create my first Ruby gem, because that&rsquo;s a thing I&rsquo;ve been wanting to learn to do for a while now, and deploy it as a containerized job that can run on a schedule, also for learning purposes more than anything (a cron on my laptop would work just as well). Those will probably be topics for future blog posts &#x2014; this post covering the Ruby program to scrape Reddit and create the playlist is long enough.


# Scraping Reddit


## Working with the Reddit API

I started by writing the Reddit scraper. Figuring out the Reddit API was the most confusing part of this to me. I didn&rsquo;t find the documentation very useful, found lots of undocumented things, and the /r/redditdev community&rsquo;s focus on Python made finding solutions to some Ruby-specific issues difficult.

Reddit uses OAuth2 for authentication. I&rsquo;ve worked with OAuth2 with other APIs using Python&rsquo;s `requests` library before, but I&rsquo;d never used Ruby&rsquo;s `Net::HTTP` class. I had trouble figuring out how to make the POST requests I needed with it, so I ended up using [Redd](https://github.com/avinashbot/redd), a Ruby gem for working with the Reddit API, to handle authenticating to the API and maintaining a session. I did eventually figure out how to use `Net::HTTP` to do OAuth2, which I&rsquo;ll talk about in the Spotify sections below. Redd did make authentication super simple, but I still needed to fight it to actually get the data I wanted from Reddit &#x2014; at some point I&rsquo;m going to remove Redd as dependency and just use `Net::HTTP` in the same way I do for Spotify.


## Finding the latest &ldquo;New Music Friday&rdquo; thread

The /r/indieheads sidebar contains a link to the most recent New Music Friday thread. From the Reddit API docs, I gathered I needed to GET [/r/indieheads/about](https://www.reddit.com/dev/api/#GET_r_{subreddit}_about) or [/r/indieheads/sidebar](https://www.reddit.com/dev/api/#GET_sidebar) to get that data, but Redd doesn&rsquo;t have methods for either of those endpoints.

![img](/img/r-indieheads-sidebar.png "Weekly threads listed on the /r/indieheads sidebar.")

I looked at some of the API methods Redd does have that make GET requests to other subreddit endpoints, like this one for `Redd::Models::Subreddit#wiki_pages`, from `lib/redd/models/subreddit.rb` in the Redd codebase:

{% highlight ruby %}
def wiki_pages
  client.get("/r/#{read_attribute(:display_name)}/wiki/pages").body[:data]
end
{% endhighlight %}

This method just wraps a call to [Redd::Client#get](https://rubydoc.info/github/avinashbot/redd/master/Redd/Client#get-instance_method) in order to GET [/r/${subreddit}/wiki/pages](https://www.reddit.com/dev/api/#GET_wiki_pages), an endpoint that returns a list of wiki pages associated with a subreddit.

Following the Redd README, you create a new session like this:

{% highlight ruby %}
session = Redd.it(
  user_agent: 'Your user agent by /u/youruser',
  client_id:  'YourClientID',
  secret:     'YourClientSecret',
  username:   'your_username',
  password:   'your_pas$word'
)
{% endhighlight %}

`Redd#it` returns a `Redd::Models::Session` object.

{% highlight nil %}
irb(main):011:0> session.class
=> Redd::Models::Session
{% endhighlight %}

`Redd::Models::Session#client` returns the `Redd::APIClient` object that it was initialized with. This object inherits the `get` method from `Redd::Client`.

Since Redd doesn&rsquo;t have any methods to interact with the `/r/${subreddit}/about` API endpoint, I wrote my own class to just extract the `Redd::APIClient` object from the Redd session and wrap its `get` method and return raw body of the response from Reddit, parsed by the `JSON` module.

{% highlight ruby %}
class RedditScraper
  def initialize(session)
    @session = session
    @client = session.client
  end

  def get_endpoint(endpoint)
    JSON.parse(@client.get("#{endpoint}").raw_body)
  end
end
{% endhighlight %}

Running something like this:

{% highlight ruby %}
# `session` is a Redd::Models::Session object
reddit = RedditScraper.new(session)
reddit.get_endpoint('/r/indieheads/about')
{% endhighlight %}

Returns a bunch of JSON data about the subreddit. One of the fields contains the link to this week&rsquo;s New Music Friday thread. Rather than try to sort through them all in Ruby, I used Reddit&rsquo;s (undocumented?) JSON endpoints to just look at it in Firefox. You can get to these by appending &rsquo;.json&rsquo; to (some? all?) API GET endpoints, e.g. [https://www.reddit.com/r/indieheads/about.json](https://www.reddit.com/r/indieheads/about.json). I didn&rsquo;t want to use this in my script because it is heavily rate limited &#x2014; clicking that link will make it so you can&rsquo;t download another one for several minutes. But Firefox makes reading JSON really simple, so I used that endpoint to find that the link I want, in raw Reddit markdown, is in the `['data']['description']` field of the response. Then I wrote a regular expression to extract the URL for the New Music Friday thread from that field.

I made this into a method attached to a new `NMFbot` class I&rsquo;d built to do the main logic of the program.

{% highlight ruby %}
def nmf_thread
  indieheads_subreddit_about = @reddit_scraper
				 .get_endpoint('/r/indieheads/about')
  pattern = %r{
	https:\/\/www.reddit.com
	(\/r\/indieheads\/
	comments\/[a-z0-9]+\/
	new_music_friday_[a-z]+_[0-9]{1,2}[a-z]{1,2}_[0-9]{4}\)/
	}x
  match = pattern.match(indieheads_subreddit_about['data']['description'])[1]
  @reddit_scraper.get_endpoint(match)
end
{% endhighlight %}


## Scraping the new releases from the &ldquo;New Music Friday&rdquo; thread

I used the same approach to look at what the Reddit API gives for [the actual New Music Friday thread](https://www.reddit.com/r/indieheads/comments/fyry48/new_music_friday_april_10th_2020/.json), and found the main body of the post, with the list of new releases, in `[0]['data']['children'][0]['data']['selftext']`.

![img](/img/new-music-friday-json.png "Firefox&rsquo;s rendering of the JSON returned from a New Music Friday thread.")

/u/VietRooster writes the post in a consistent way that makes extracting the album titles and artist names easy with a regular expression &#x2014; the albums are listed like this, in raw markdown:

{% highlight markdown %}
**Artist Name - [Album Name](https://link.to/cover_art.jpg)**\n\n
{% endhighlight %}

I wrote this method to pull out all the artists and album names and return an array of hashes:

{% highlight ruby %}
def new_releases(nmf_thread)
  post_body = nmf_thread[0]['data']['children'][0]['data']['selftext']
  pattern = /\*\*.+? - \[.+?\]/
  matches = post_body.scan(pattern)
  split = matches.map { |x| x.gsub(/(\*|\[|\])/, '').split(' - ') }
  split.map do |x|
    {
      # The New Music Friday thread often adds parenthetical descriptions
      # to album or artist names. E.g. "Mothertime (EP)" or
      # "Oscar Cash (of Metronomy)"
      artist: x[0].gsub(/\(.+\)/, ''),
      album: x[1].gsub(/\(.+\)/, '')
    }
  end
end
{% endhighlight %}

The regular expression `/\*\*.+? - \[.+?\]/` pulls out the `**Artist Name - [Album Name]` part. Then I remove the `*` and `[]` characters, and split the string on `-` to isolate the artist and album name. I used [regexr.com](https://regexr.com/) to help me write the expression. It could probably be refined to pull out the artist and album name with just a regular expression and pattern matching, to eliminate the need for the splitting and substitution steps, but this works for now. I also added a pair of `gsub` calls to remove anything inside parentheses from the artist or album name &#x2014; I found that the author of the post often adds extra info in parentheses, and passing that info to the Spotify search API prevents it from finding a match.


# Making a Spotify playlist

With my Reddit code done, I had an array containing all the albums from the thread. The next step was to find these albums on Spotify, find the two most popular tracks from each album, and make a playlist of those tracks.

Like the Reddit API, the Spotify API uses OAuth2. I looked at a few Ruby libraries for working with the Spotify API, but didn&rsquo;t find one that met my needs out of the box &#x2014; the most popular library, [RSpotify](https://github.com/guilhermesad/rspotify), requires a Rails library to use OAuth. Spotify&rsquo;s API documentation is very friendly and well-written, and includes a follow-the-bouncing-ball style [authorization guide](https://developer.spotify.com/documentation/general/guides/authorization-guide/), so I decided to take another stab at using `Net:HTTP` to handle OAuth myself.

It wasn&rsquo;t that bad!


## Authenticating to the Spotify API with OAuth2 and Net::HTTP


### Getting an authorization code

There are two main steps to authenticating to the Spotify API.

First, you need to direct the user to a Spotify endpoint &#x2014; <https://accounts.spotify.com/authorize> &#x2014; along with some query parameters that tell Spotify what application is requesting the access and how much access it&rsquo;s requesting. You can find all the parameters on the documentation I linked above, but for my purposes I built a query that sent the following:

-   **client\_id:** The unique client ID for my application. You generate this on the [Spotify developer dashboard](https://developer.spotify.com/dashboard/login).
-   **response\_type:** This must be set to `code`; it&rsquo;s in the docs.
-   **redirect\_uri:** This is the URI that Spotify will redirect the user&rsquo;s browser to after they&rsquo;ve authenticated and accepted the permissions requested for your application. Since my script is single user and will only run locally, I set this to <https://localhost/>. Spotify will append the authorization code that is required to request an access token to this URI when it redirects the user. This must match the URI you defined for your application on the Spotify developer dashboard.
-   **scope:** This is the [authorization scope](https://developer.spotify.com/documentation/general/guides/scopes/) requested for your application. For my purposes I requested `playlist-modify-public`.

I created a `SpotifyScraper` class to handle wrapping the Spotify API and added this method to it:

{% highlight ruby %}
def request_authorization_code
  url = "https://accounts.spotify.com/authorize?client_id=#{@client_id}&" \
	"response_type=code&redirect_uri=#{webify(@redirect_uri)}&" \
	"scope=#{@scope}"

  puts 'To authenticate to the Spotify API, open this URL, ' \
       'accept the terms, and then paste the URL you were redirected to:'
  puts url
  print 'URL you were redirected to: '
  gets.chomp.gsub("#{@redirect_uri}?code=", '')
end
{% endhighlight %}

It constructs the authorization URL<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup>, prints it to the console and asks the user to click it, and then asks the user to paste back the URI they were redirected to. Then it extracts and returns the authorization code from the redirected URI.


### Getting an access token

Once you have the authorization code, you can make a POST request to <https://accounts.spotify.com/api/token> to request an access token. You will need to include the access token in the authorization HTTP header of all requests you make the API.

Your post request needs to include the following parameters in its body:

-   **grant\_type:** This must be `authorization_code`.
-   **code:** This is the authorization code retrieved in the previous step.
-   **redirect\_uri:** Your application&rsquo;s redirect URI.

You also need to base64 encode the string `"#{client_id}:#{client_secret}"` and add it to an `Authorization` header like so: `Authorization: Basic #{base64 encoded string}`.

The basic process looks like this:

{% highlight ruby %}
uri = URI.parse('https://accounts.spotify.com/api/token')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

grant = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
header = { 'Authorization' => "Basic #{grant}" }
request = Net::HTTP::Post.new(uri.request_uri, header)
form_data = {
  'grant_type' => 'authorization_code',
  'code' => @authorization_code,
  'redirect_uri' => @redirect_uri
}

request.set_form_data(form_data)

response = http.request(request)
unless response.code == '200'
  raise InvalidResponse,
	"#{response.code} #{response.body}"
end

JSON.parse(response.body)
{% endhighlight %}

The token Spotify returns looks like this:

{% highlight json %}
{
   "access_token": "The access token",
   "token_type": "Bearer",
   "scope": "playlist-modify-public",
   "expires_in": 3600,
   "refresh_token": "The refresh token"
}
{% endhighlight %}

Ultimately I want this script to run as a scheduled job, so I don&rsquo;t want it to require the user to get an authorization code every time it runs. I pulled the process above into a method called `request_access_token` and added some additional logic to handle saving the access token to disc and refreshing the token once it&rsquo;s expired.

{% highlight ruby %}
def request_access_token(refresh: false)
  if refresh && @access_token['refresh_token'].nil?
    @authorization_code = request_authorization_code
    return request_access_token(refresh: false)
  end

  uri = URI.parse('https://accounts.spotify.com/api/token')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  grant = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
  header = { 'Authorization' => "Basic #{grant}" }
  request = Net::HTTP::Post.new(uri.request_uri, header)
  form_data = if refresh
		{
		  'grant_type' => 'refresh_token',
		  'refresh_token' => @access_token['refresh_token']
		}
	      else
		{
		  'grant_type' => 'authorization_code',
		  'code' => @authorization_code,
		  'redirect_uri' => @redirect_uri
		}
	      end

  request.set_form_data(form_data)

  response = http.request(request)
  unless response.code == '200'
    raise InvalidResponse,
	  "#{response.code} #{response.body}"
  end

  token = JSON.parse(response.body)

  # Adding a `created` UNIX timestamp to determine when the token needs to
  # be refreshed.
  token['created'] = Time.now.to_i

  # The token returned from a `refresh_token` request does not include
  # a new refresh token. Don't save this token, we won't be able to
  # use it to get a new one.
  if refresh
    token['refresh_token'] = @access_token['refresh_token']
  else
    File.open(TOKEN_FILE, 'w') do |f|
      f.write(token.to_json)
    end
  end

  token
end
{% endhighlight %}

First, I added a keyword argument, `refresh`, to the method, to signify if this is to refresh an access token or request a new one. This is necessary because the different types of request require POSTing different data, and the token you get in response from Spotify is also different.

Second, I added a `created` key to the token with the current time as a UNIX timestamp. Remember that the token returned by Spotify includes an `expires_in` key &#x2014; that&rsquo;s the number of seconds until the token expires. I wrote another method, `access_token`, that returns either returns the current access token, or requests a refresh if it&rsquo;s expired.

{% highlight ruby %}
def access_token
  created = @access_token['created'].to_i
  now = Time.now.to_i
  expires = @access_token['expires_in'].to_i
  if now - created > expires
    @access_token = request_access_token(refresh: true)
  end
  @access_token['access_token']
end
{% endhighlight %}

It subtracts the `created` time from the current time to see if the token needs to be refreshed.

Finally, there is a conditional to add the original refresh token to the new token if the request was a refresh request because Spotify doesn&rsquo;t include a new refresh token its response. If it is not a refresh request, the token gets written in plain text to disc<sup><a id="fnr.2" class="footref" href="#fn.2">2</a></sup> for later use. When the `SpotifyScraper` class is initialized, it first looks to see if this token file exists and loads it, only asking the user to go through the authorization flow if the file doesn&rsquo;t exist.

{% highlight ruby %}
class SpotifyScraper
  def initialize(client_id:, client_secret:,
		 redirect_uri: 'http://localhost/',
		 scope: 'playlist-modify-public', debug: false)
    @debug = debug
    @client_id = client_id
    @client_secret = client_secret
    @redirect_uri = redirect_uri
    @scope = scope

    # Load token from file, if it exists, so we can skip the auth flow
    if File.exist?(TOKEN_FILE)
      f = File.open(TOKEN_FILE, 'r')
      @access_token = JSON.parse(f.read)
      f.close
    else
      # We need to have the user get an authorization code, and then request
      # an access token using that code.
      # Step 1 in authorization guide
      @authorization_code = request_authorization_code
      # Step 2 in authorization guide
      @access_token = request_access_token
    end
  end
end
{% endhighlight %}


## Making requests to the Spotify API

I&rsquo;ll need to make two kinds of requests to the Spotify API &#x2014; GET requests on endpoints like <https://api.spotify.com/v1/search> to search for albums and <https://api.spotify.com/v1/albums> to get the album objects, and POST requests to <https://api.spotify.com/v1/users/{user_id}/playlists> to create my playlist. I created two methods on my `SpotifyScraper` class to make these requests and handle responses.

{% highlight ruby %}
def get(endpoint, retries: 0)
  raise InvalidResponse, 'Too many retries' if retries > 3

  uri = URI(endpoint)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request['authorization'] = "Bearer #{access_token}"

  response = http.request(request)

  case response.code
  when '200', '201', '202', '204'
    JSON.parse(response.body)
  # Unauthorized; most likely access token is expired
  when '401'
    puts '401 Unauthorized. Refreshing access token...'
    @access_token = request_access_token(refresh: true)
    get(endpoint, retries: retries + 1)
  # Too many requests
  when '429'
    puts '429 Too Many Requests. Sleeping...'
    sleep response['Retry-After'].to_i
    get(endpoint, retries: retries + 1)
  else
    raise InvalidResponse,
	  "GET #{endpoint} returned #{response.code} #{response.body}"
  end
end
{% endhighlight %}

Most of this is pretty similar to the HTTP request I made in the `request_access_token` method. The biggest difference is that the `Authorization` header needs to be set to `Bearer` and included the access token. I also add a switch statement to handle response codes, and return the JSON-parsed body.

The `post` method is mostly the same &#x2014; I could probably refactor the methods to pull out the shared code.

{% highlight ruby %}
def post(endpoint, body, retries: 0)
  uri = URI(endpoint)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  header = {
    'Authorization' => "Bearer #{access_token}",
    'Content-Type' => 'application/json'
  }

  request = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = body

  response = http.request(request)

  case response.code
  when '200', '201', '202', '204'
    JSON.parse(response.body)
  # Unauthorized; most likely access token is expired
  when '401'
    puts '401 Unauthorized. Refreshing access token...'
    @access_token = request_access_token(refresh: true)
    post(endpoint, body, retries: retries + 1)
  # Too many requests
  when '429'
    puts '429 Too Many Requests. Sleeping...'
    sleep response['Retry-After'].to_i
    post(endpoint, body, retries: retries + 1)
  else
    raise InvalidResponse,
	  "POST #{endpoint} #{body} returned " \
	  "#{response.code} #{response.body}"
  end
end
{% endhighlight %}

The `body` argument is a JSON-encoded hash.


## Writing semantic methods in the NMFbot class

With the `SpotifyScraper` class handling authenticating and making requests to the Spotify API, I just had to write some wrapper methods to make the specific requests I needed for my program in the `NMFbot` class.

Some of these methods are pretty simple: request an endpoint, return the result. Like this one (the `sanitize` method just removes non-ASCII characters that aren&rsquo;t expected by the Spotify search API):

{% highlight ruby %}
def search_for_album(album:, artist:)
  query = "q=album:#{@spotify.sanitize(album)} " \
	  "artist:#{@spotify.sanitize(artist)}&type=album".gsub(' ', '+')
  url = "https://api.spotify.com/v1/search?#{query}"
  response = @spotify.get(url)
  response['albums']['items'][0]
end
{% endhighlight %}

Many of the Spotify API endpoints allow you to request multiple *things* (tracks, albums, etc.) with a single API request. I tried to leverage this where I could to make as few API calls as possible. For example, the threads I&rsquo;m scraping have around 50 albums that I have to search for. Spotify&rsquo;s <https://api.spotify.com/v1/albums> endpoint allows you to request up to 20 albums at a time. The `NMFbot::NMFbot#albums` method takes an array of albums as its argument and makes requests to the API in batches of 20 albums at a time until the array has fewer than 20 items.

{% highlight ruby %}
def albums(albums)
  album_objects = []
  url = 'https://api.spotify.com/v1/albums'

  # Maximum 20 albums per request
  while albums.size > 20
    album_ids = albums.pop(20)
		  .map { |x| x['id'] }
		  .join(',')
    result = @spotify.get(url + "/?ids=#{album_ids}")['albums']
    album_objects += result
  end

  album_ids = albums.map { |x| x['id'] }.join(',')
  album_objects += @spotify.get(url + "/?ids=#{album_ids}")['albums']
  album_objects
end
{% endhighlight %}

Ultimately, these are all the methods I created for the `NMFbot` class:

-   `add_tracks_to_playlist`
-   `albums`
-   `create_playlist`
-   `find_most_popular_tracks`
-   `new_releases`
-   `nmf_thread`
-   `search_for_album`
-   `spotify_user_id`
-   `title`


# Tying it all together

With my classes written, I wrote a small script to tie everything together. It pulls my secrets (client IDs and client secrets, usernames and passwords where necessary) from environment variables and then:

-   Finds the link to the latest New Music Friday thread from the /r/indieheads sidebar, if a link was not provided as a command-line option;
-   Pulls the new releases from that thread into an array;
-   Searches Spotify for each new release, ignoring releases where Spotify didn&rsquo;t find a match;
-   Pulls the full album objects from Spotify for all of the albums that were matched;
-   Finds the two most popular tracks from each album;
-   Creates a new playlist with using the title of the New Music Friday thread as its name;
-   Adds all of the found tracks to the new playlist.

You can check out the full source code for the project on GitHub: [https://github.com/kylerjohnston/nmfbot](https://github.com/kylerjohnston/nmfbot).


# Next time

This post is getting long, so I&rsquo;m going to wrap it up. I&rsquo;ll probably make a second post about how I turned this into a gem, and maybe another about the infrastructure I&rsquo;m using to run it (I&rsquo;m still working on what that&rsquo;s going to look like).

# Footnotes

<sup><a id="fn.1" href="#fnr.1">1</a></sup> The `webify` method substitutes `:` and `/` for their [percent-encoded](https://en.wikipedia.org/wiki/Percent-encoding) forms.

<sup><a id="fn.2" href="#fnr.2">2</a></sup> If this was a multi-user machine or the program was going to be used by a multi-user web app or something (handling *other* people&rsquo;s access tokens, not just your own) you would probably want to devise a more secure solution.
