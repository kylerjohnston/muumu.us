---
title: "Blog of the Blog: September"
date: 2020-09-08
layout: post
excerpt: "In the spirit of building this website in the open, I thought it would be cool to look back on the past month and the changes I've made to the site and share some metrics and costs and my thoughts on how I'd like to improve the site."
tags: 
- muumuus
---

In the spirit of building this website in the open, I thought it would be cool to look back on the past month and the changes I've made to the site and share some metrics and costs and my thoughts on how I'd like to improve the site.

## Changes in the last month
I've made a few changes to the blog in the past month or so. I started writing weekly updates in July and continued that for five weeks. I've stopped doing it over the past few weeks because I've been occupied during my weekends setting up public-notes[^1] and [writing a blog post about it]({% post_url 2020-09-06-building-a-public-tiddlywiki %} "'Building an internet-facing TiddlyWiki for my public second brain'"), and teaching myself Elixir.

And that's the other big change to this site (well maybe not *this* site, but this domain) --- public-notes.muumu.us is live[^2]! It's a project I've envisioned for years --- a digital commonplace book that I write in public. It's a note-taking system, for sure, but I also see it as a literary project --- I think if someone maintained something like this for years --- for a lifetime --- it would make for a wonderful document, part *Garden of Forking Paths*, part personal Wikipedia. Do read the [post about it]({% post_url 2020-09-06-building-a-public-tiddlywiki %} "'Building an internet-facing TiddlyWiki for my public second brain'") for more info. I did try to use this blog to do similar things at one point --- posts like '[Evaluating source code blocks in org mode with Babel]({% post_url 2020-02-08-evaluating-source-code-blocks-in-org-mode %} "Evaluating source code blocks in org mode with Babel")' or '[Use netmask to mask all but one IP address]({% post_url 2020-02-10-use-netmask-to-mask-all-but-one-ip-address %} "Use netmask to mask all but one IP address")' were meant to be short notes. But Jekyll is not a good tool for this kind of thing --- the time barrier to writing and publishing a new post, re-building the whole site in the process, is too high, and it's not searchable. TiddlyWiki, on the other hand, is the ideal tool for the task, and I've found it effortless to use in that capacity.

I also added an [about page](/about/ "About muumu.us"), and removed my Emacs config. I've switched back to [Doom Emacs](https://github.com/hlissner/doom-emacs "Doom Emacs") because it just has so many things configured how I'd want out of the box. I don't want fiddling with my editor to be an excuse to procrastinate. You can still read my Emacs config [on GitHub](https://github.com/kylerjohnston/emacs.d/blob/master/emacs.org "kylerjohnston/emacs.d - Emacs Configuration") --- that's a better place to view it, anyway, since GitHub renders org files and it will always be up to date. I never found a good solution for keeping my Emacs config in sync with that blog post automatically, so it always required manual updates, which I rarely did.

## August analytics
I don't have CloudFront logging enabled so I can only see some limited statistics for the site. I can't track unique visitors, for example --- I can only see total *requests*.

muumu.us had 3,790 requests in August. Of those, 1,744 came on one day, August 13. What happened? Did I hit the front page of HackerNews? Nope --- it looks like someone was just trying to steal backups from my S3 bucket. 1,640 of the 1,744 requests that day were errors; the "Popular Objects" report for that day, which only shows me the 50 most requested objects, is full of random tar, rar, and gzip files. Sorry boys, no backups here --- it's just flat HTML files for my boring website.

The most popular posts in August were:

| Post                                                                                                                                                                                     | Requests |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [Another Weekend]({% post_url 2020-08-02-weekly-update %} "Another Weekend")                                                                                                             | 17       |
| [Blog updates, ortholinear keyboards, and second brains]({% post_url 2020-07-19-blog-updates-olkb-indieweb %} "Blog updates, ortholinear keyboards, and second brains")                  | 17       |
| [Setting up Mopidy on a Raspberry Pi]({% post_url 2020-05-25-mopidy-raspberry-pi %} "Setting up Mopidy on a Raspberry Pi")                                                               | 17       |
| [Goodbye Numbers]({% post_url 2020-04-29-goodbye-numbers %} "Goodbye Numbers")                                                                                                           | 17       |
| [Discovering new music with Ruby]({% post_url 2020-04-26-discovering-new-music-with-ruby %} "Discovering new music with Ruby")                                                           | 17       |
| [The pleasure of the txt]({% post_url 2016-02-16-the-pleasure-of-the-txt %} "The pleasure of the txt")                                                                                   | 17       |
| [Scraping HackerNews "Who is hiring?" threads with Ruby]({% post_url 2020-03-07-scraping-hackernews-who-is-hiring-with-ruby %} "Scraping HackerNews 'Who is hiring?' threads with Ruby") | 16       |
| [Implementing mergesort in Ruby]({% post_url 2020-03-03-mergesort-in-ruby %} "Implementing mergesort in Ruby")                                                                           | 16       |
| [Evaluating source code blocks in org mode with Babel]({% post_url 2020-02-08-evaluating-source-code-blocks-in-org-mode %} "Evaluating source code blocks in org mode with Babel")       | 16       |
| [Weekly update: Thoughts on TiddlyWiki and GitHub Actions]({% post_url 2020-07-26-weekly-update %} "Weekly update: Thoughts on TiddlyWiki and GitHub Actions")                           | 15       |

Almost all of the posts have a cache hit rate below 15%; most of them are under 10%. I need to adjust my caching settings, because that should be much higher --- there really isn't a reason for it to not be 100%, since the blog is static and only updates when I tell it to (and I invalidate the cache when I deploy).

## Costs
My AWS bill for August was $25.02, which was unusually high because my domain renewed ($15).

The next highest item on the bill was $7.34 for EC2, for public-notes.muumu.us. It's running on a t3a.micro now; I think it could be downsized to a t3a.nano to cut that down a bit.

I paid $2.08 for S3, but that's mostly for a bucket that I store backups in. It's hard to estimate how much of that was for muumu.us, but I'm guessing it's negligible. I'm within CloudFront's free tier so that cost me nothing.

The only other things on my bill are $0.03 for an ECR repository I was testing for a few days, and $0.07 for data transfer out of EC2, for public-notes.muumu.us.

The biggest place I can shave costs here is definitely the EC2 instance.

## Things to come

I've enabled logging in CloudFront so that I can get better insight into the sites' traffic next month.

I think I want to continue writing the "blog" style update posts --- probably not weekly --- but find a way to separate them from the other, more focused content. I enjoy writing them, and they were some of the most requested posts in the past month --- although with the reporting I have now it's hard to tell if those are actual visits or crawlers. But I don't think it makes sense for them to be mixed in with the other posts on the home page.

In that same vein, I want to think about improving the experience of the site. How do I organize content and make it easy for a reader to discover the stuff they're interested in? I am thinking of things like separating the blog-style updates from the "articles", moving the note-style posts to public-notes, and sorting content on the home page into categories instead of a chronological list. Maybe add links to related posts at the bottom of each post. I also think the styling needs to be tweaked to more clearly separate the header of a post --- its title, tag, and pub date -- from its body, and that I need to start following a more consistent style guideline across the site (are titles capitalized or not?).

I also need to improve CloudFront's caching behavior so requests are actually hitting the cache.

[^1]: I've since decided to take down public-notes.

[^2]: Again, nope.
