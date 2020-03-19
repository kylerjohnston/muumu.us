---
title: "Scraping HackerNews &ldquo;Who is hiring?&rdquo; threads with Ruby"
date: 2020-03-07
layout: post
categories: 
tags: 
- ruby 
- org-mode
---
On the first weekday of each month, at 11 am, the &ldquo;whoishiring&rdquo; user posts a thread titled &rsquo;Ask HN: Who is hiring?&rsquo; on HackerNews. Companies from across the tech industry respond, posting jobs they&rsquo;re looking to fill.

I like to read these threads to see what companies are hiring for in my area, and also to scope out remote-friendly companies that I might be interested in working for in the future. Reading the thread in a browser, though, introduces a few problems:

1.  There is a lot of stuff in the threads I *don&rsquo;t* care about.
2.  The browser&rsquo;s search functionality isn&rsquo;t able to narrow results enough &#x2014; searching &ldquo;remote&rdquo; in [this month&rsquo;s Who is hiring? thread](https://news.ycombinator.com/item?id=22465476) yields 153 matches; many remote job listings mention the word more than once, and some of these matches are in child comments where people are asking things like &ldquo;is this job remote friendly?&rdquo;. I am only interested in top-level comments &#x2014; these are the job posts &#x2014; and I only want one match per job.
3.  There is no way for me to track state in the browser. I want to know which job listings I&rsquo;ve already read and track which jobs I&rsquo;m interested in, which I&rsquo;ve applied to, etc.

I want to be able to pull the data for only the jobs I care about down to my computer and store them in a format that is both human and machine readable and easy to edit. HackerNews offers an [API](https://github.com/HackerNews/API) which should make grabbing the data easy; I want to save it as an org-mode file because they are plain text &#x2014; easy to script &#x2014; but offer powerful editing and task management capabilities that will allow me to track state by marking jobs I&rsquo;m interested in as org tasks.

In the rest of this post, I&rsquo;m going to walk through my process of writing the script. I&rsquo;m going to use Ruby because I&rsquo;m still learning it, and I&rsquo;d like an opportunity to play with its [Net::HTTP](https://ruby-doc.org/stdlib-2.6.5/libdoc/net/http/rdoc/Net/HTTP.html) and [JSON](https://ruby-doc.org/stdlib-2.6.5/libdoc/json/rdoc/JSON.html) libraries. I&rsquo;m developing the script using [Babel](https://orgmode.org/worg/org-contrib/babel/) which lets you run blocks of code directly from an org document, sort of like a Jupyter notebook. This blog post itself is the actual org document I&rsquo;m using to write the script &#x2014; when I&rsquo;m done, I&rsquo;ll export it to Jekyll-compatible markdown for my blog. I&rsquo;m hoping that this captures some of the thought process behind writing the script &#x2014; I&rsquo;m going to develop it iteratively, circling back and refactoring things as I&rsquo;m going.


# Scraping the thread

The first thing we need to do is get the thread using the API. I create a class for the scraper here, and initialize it with an instance variable `@threads` that I&rsquo;ll eventually use to store the threads I&rsquo;m downloading. For now I just have the method return the response body, rather than store it in `@threads` so I can test it&rsquo;s working. I also test to make sure I receive a `200` response from the API &#x2014; if not, the method returns the response code instead of the response body.

{% highlight ruby %}
require 'net/http'

class HNJobScraper
  attr_reader :threads

  def initialize
    @threads = {}
  end

  def get_jobs_thread(id)
    uri = URI("https://hacker-news.firebaseio.com/v0/item/#{id}.json")
    response = Net::HTTP.get_response(uri)
    response.code == '200' ? response.body : response.code
  end
end

scraper = HNJobScraper.new
puts scraper.get_jobs_thread('22465476').to_s
{% endhighlight %}


# Parsing the JSON

Running that returns a really big string of unprocessed JSON data that starts off like this: `{"by":"whoishiring","descendants":743,"id":22465476,"kids":[22513275,22466243...`. A string isn&rsquo;t a useful way to structure this data; let&rsquo;s parse it into something more usable with the JSON module from Ruby&rsquo;s standard library, which will convert the JSON into a hash. I also store the response body in the `@threads` instance variable now, and have `get_jobs_threads` always return the response code. I make `@threads` a hash of threads in the event that I want to use the script to scrape more than one thread at a time.

{% highlight ruby %}
require 'net/http'
# We need to require the json library to use the JSON module
require 'json'

class HNJobScraper
  attr_reader :threads

  def initialize
    @threads = {}
  end

  def get_jobs_thread(id)
    uri = URI("https://hacker-news.firebaseio.com/v0/item/#{id}.json")
    response = Net::HTTP.get_response(uri)
    # Parse the response body's JSON if the response was successful
    # Store the response in the @threads variable
    @threads[id] = JSON.parse(response.body) if response.code == '200'
    # Always return the response code
    response.code
  end
end

scraper = HNJobScraper.new
response = scraper.get_jobs_thread('22465476')
puts "Response code: #{response}"
puts "Response keys: #{scraper.threads['22465476'].keys}"
puts "Thread title: #{scraper.threads['22465476']['title']}"
puts "Thread children: #{scraper.threads['22465476']['kids']}"
{% endhighlight %}

This returns:

{% highlight nil %}
: Response code: 200
: Response keys: ["by", "descendants", "id", "kids", "score", "text", "time", "title", "type"]
: Thread title: Ask HN: Who is hiring? (March 2020)
: Thread children (the jobs): [22466243, 22466136, 22465478, 22468018, 22466392, ...] # truncated
{% endhighlight %}

This matches up with the fields in the API&rsquo;s [documentation](https://github.com/HackerNews/API) &#x2014; that&rsquo;s good! The fields I care most about are `title`, which contains the title of the thread, and `kids`, which contains the item ids of the thread&rsquo;s children &#x2014; these are the top-level comments on the thread, i.e. the job postings.


# Scraping the comments (the jobs)

The next step is to download each job listing. I add a `@jobs` array to the class to store them, and I pull the code to make requests to the API out of `get_jobs_thread` and into its own method, `get_by_id`, since it will also need to be used in the new `get_jobs` method. Then, I loop through each item in the `thread['kids']` array and download them by item ID using the HackerNews API, pushing each response onto the `@jobs` array.

{% highlight ruby %}
require 'net/http'
require 'json'

class HNJobScraper
  # Adding a @jobs variable to store the downloaded job data
  attr_reader :threads, :jobs

  def initialize
    # @jobs is going to be an array
    @jobs = []
    @threads = {}
  end

  # This code was in the `get_jobs_thread` method, but the new
  # `get_jobs` method will also need it, so I'm pulling it into
  # its own function
  def get_by_id(id)
    uri = URI("https://hacker-news.firebaseio.com/v0/item/#{id}.json")
    Net::HTTP.get_response(uri)
  end

  def get_jobs_thread(id)
    response = get_by_id(id)
    if response.code == '200'
      # Make sure this is actually a Who is hiring? thread; if it's not
      # the rest of the code won't work, so throw an error
      parsed = JSON.parse(response.body)
      unless /Ask HN: Who is hiring\?/.match?(parsed['title'])
	raise ArgumentError "#{id} is not a Who is hiring? thread"
      end

      @threads[id] = parsed
      # After we download the Who is hiring? thread, we need to
      # download the jobs attached to it
      get_jobs(@threads[id])
    end
    response.code
  end

  # This method downloads the jobs
  def get_jobs(thread)
    puts 'Downloading job data.'
    # `thread['kids']` is an array of item ids for the top-level
    # comments on the Who is hiring? thread --- the jobs.
    # Loop through all of them, and download each one.
    thread['kids'].each.with_index do |id, i|
      # This takes a while to run --- this will show what percentage of
      # the loop we're through so I know the program is still running
      percentage = ((i.to_f / thread['kids'].size) * 100).to_i
      printf("\r#{percentage}%%", percentage)
      # Download the jobs
      response = get_by_id(id)
      # If the response is successful, push the job data on the `jobs`
      # array
      @jobs.push(JSON.parse(response.body)) if response.code == '200'
    end
    printf("\r100%%\n\n")
  end
end

scraper = HNJobScraper.new
response = scraper.get_jobs_thread('22465476')
puts "Found #{scraper.jobs.size} jobs."
puts "They look like this:"
puts "#{scraper.jobs.take(1)}"
{% endhighlight %}

This outputs:

{% highlight nil %}
: Found 642 jobs.
: They look like this:
: [{"by"=>"jamespollack", "id"=>22466243, "kids"=>[22480479, 22471763], "parent"=>22465476, "text"=>"Can everyone posting please post about their interview process:<p>How many:<p>- technical phone screens<p>- video interviews<p>- projects (esp. length and duration, paid&#x2F;unpaid, etc)<p>- portfolio &#x2F; code reviews on past projects<p>- onsite interviews and if there&#x27;s any \nwhiteboarding&#x2F;pairing&#x2F;etc<p>And the total amount of time you expect interviewing to take?<p>Candidates need the ability to compare positions, processes, etc.", "time"=>1583168643, "type"=>"comment"}]
{% endhighlight %}


# Filtering the jobs

Now that we have all the jobs, I want to pull out only the ones I&rsquo;m interested in. I add the following method to the `HNJobScraper` class. Given a regular expression, it loops through each job and pushes the ones with matching `text` fields to a `matches` array. Then it returns the `matches` array.

{% highlight ruby %}
def filter(pattern)
  # Pattern should be a regular expression;
  # raise an error if it's not
  raise TypeError unless pattern.class == Regexp

  matches = []
  @jobs.each do |job|
    # Without the nil check a job without a `text` response
    # will (and does) cause an exception
    unless job['text'].nil?
      # The `text` field contains the text of the comment.
      # If anything in the text matches our search pattern,
      # push it to the `matches` array.
      matches.push(job) if pattern.match(job['text'])
    end
  end
  # Return the matches
  matches
end
{% endhighlight %}


# Writing it to an org file

Now we have an array of all the jobs matching our search criteria, but we need a way to write that data to a file in a structured way. This class opens a file and writes the data to an org-mode file.

I prepend a `*` to the first line of every job post &#x2014; this turns that line into a top-level org heading. Since most of the jobs follow a pattern like `Company Name | Job Role | Location` on the first line, this is going to make a list of collapsible org-headings of brief descriptions of the jobs which I can expand to view the whole listing.

The rest of the substitutions are hacked together from reading some of the jobs&rsquo; `text` fields and trying to make them more human-readable.

{% highlight ruby %}
class OrgPrinter
  def initialize(filename)
    @file = File.open(filename, 'w')
    # Org-mode is just a markup format for plain text files.
    # This block adds metadata for a title to the file.
    @file.puts '#+TITLE: HackerNews Jobs'
  end

  def write(text)
    # The * makes this an org-mode heading; the convention that most
    # job postings follow looks something like
    #   Company Name | Job Position | Location<p>The body of the post...
    # Subbing `<p>` for `\n` makes an org file that mostly looks like
    #   * Company Name | Job Position | Location
    #     The body of the post...
    # The rest of the `gsub`s are quick and dirty clean up on the data
    # to make it more human readable.
    @file.puts '* ' + text.gsub('<p>', "\n\n")
			  .gsub('<a href="', '[[')
			  .gsub('" rel="nofollow">', '][')
			  .gsub('</a>', ']]')
			  .gsub('*', '-')
			  .gsub('&#x2F;', '/')
			  .gsub('&#x27;', "'")
			  .gsub('&amp;', '&')
			  .gsub('&lt;', '<')
			  .gsub('&gt;', '>')
  end
end
{% endhighlight %}


# Making it a reusable tool

To make this a useful, reusable tool, the final thing I&rsquo;m going to do is add some command line options and glue everything together.

{% highlight ruby %}
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: hn_jobs.rb [options]'

  opts.on('-i', '--id ID', "HackerNews 'Who is hiring?' item id") do |id|
    options[:id] = id
  end

  opts.on('-f', '--filter FILTER', 'Regular expression to filter jobs') do |f|
    options[:filter] = Regexp.new(f, 'i')
  end

  opts.on('-o', '--output FILENAME', 'File to write') do |outfile|
    options[:outfile] = outfile
  end
end.parse!

# If the user doesn't specify an outfile, default to `jobs.org`
outfile = options[:outfile].nil? ? 'jobs.org' : options[:outfile]

scraper = HNJobScraper.new

# If the user doesn't give us a Who is hiring? thread id...
# we can't do much of anything.
unless options[:id].nil?
  response = scraper.get_jobs_thread(options[:id])
  unless response == '200'
    # If the API didn't give us a successful response, we should
    # just quit
    raise IOError, "Received response #{response} from HN API"
  end

  # Collect the matches --- use the filter if one is provided, otherwise
  # just return all the jobs
  matches = if options[:filter].nil?
	      scraper.jobs
	    else
	      scraper.filter(options[:filter])
	    end

  printer = OrgPrinter.new(outfile)

  matches.each do |job|
    # Print each job
    printer.write(job['text'])
  end

  puts "Wrote #{outfile}."
end
{% endhighlight %}


# The end result

[Here&rsquo;s the final script](https://github.com/kylerjohnston/spooky-scripts/blob/ca5a6419190b2c238463076fc80278efa944deed/one-off/hn_scraper/hn_scraper.rb).

Running `./hn_scraper.rb -i 22465476 -f '(boston|remote)' -o jobs.org` returns an org file that looks like this in emacs:

![img](/img/jobs-org.png "The Who is Hiring? thread as an org-mode file")

It&rsquo;s more readable, I can quickly delete anything I don&rsquo;t want, and I can turn any heading into an org-mode task to track its state. I&rsquo;d consider this a success.
