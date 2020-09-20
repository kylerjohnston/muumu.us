---
title: "Weekly update: Thoughts on TiddlyWiki and GitHub Actions"
date: 2020-07-27
layout: post
excerpt: "It's been a busy weekend. On Saturday Alina and Eli stopped by on their way to a cabin they rented up north. It's the first time we've really interacted with any of our friends in person since social distancing began in March. We walked around Mackworth Island, which was surprisingly less crowded than I thought it would be. It was a pleasant day. I also brought my car to the Toyota dealership in the morning to get a state inspection --- I almost forgot about that since I rarely drive now. My brake pads failed to meet state requirements, but I was expecting that and have been putting money away each month for the better part of the last half year preparing for it. Still, it feels kind of dumb to be dropping a grand into a vehicle I almost never use now. Covid, of course, won't last forever, but I feel it's unlikely I'm ever going to be working in an office much again, or driving anywhere near as much as I used to before the virus. Still, I'm close to owning the car outright at this point and it should last another ten years, maybe more if I continue to keep my driving low."
tags: 
- tiddlywiki 
- covid
---
It's been a busy weekend. On Saturday some friends stopped by on their way to a cabin they rented up north. It's the first time we've really interacted with any of our friends in person since social distancing began in March. We walked around Mackworth Island, which was surprisingly less crowded than I thought it would be. It was a pleasant day. I also brought my car to the Toyota dealership in the morning to get a state inspection --- I almost forgot about that since I rarely drive now. My brake pads failed to meet state requirements, but I was expecting that and have been putting money away each month for the better part of the last half year preparing for it. Still, it feels kind of dumb to be dropping a grand into a vehicle I almost never use now. Covid, of course, won't last forever, but I feel it's unlikely I'm ever going to be working in an office much again, or driving anywhere near as much as I used to before the virus. Still, I'm close to owning the car outright at this point and it should last another ten years, maybe more if I continue to keep my driving low.

Sunday was mostly spent doing budgeting and housework. For a while now I've been noticing a lot of rust on our utensils. I've been cleaning it off with baking soda, but it keeps coming back. I think it may be coming from the dishwasher: there are a few spots on the dishwasher racks where the vinyl has degraded and the exposed metal has turned to rust. One of them in particular, at the intersection of three wires, has a really large rust spot at this point. This gave me an excuse to buy a Dremel, which I've been wanting for a while (I also have a cast iron pan with a lot of carbon build up that I'm trying to re-season, and I've been unable to get all the carbon off with just steel wool). I ordered that on Amazon, along with some liquid vinyl coating to paint on after I grind off the rust.

The switches I needed to finish my keyboard came in on Friday and I finished soldering them and the microcontrollers in place, and&#x2026; it didn't work. It's a split keyboard and the right half works perfectly, but the left does nothing. Even the reset button doesn't work, so I think I must have messed something up soldering the microcontroller on. I did flash the microcontrollers before soldering them, so I know that they are both functional. I didn't have time to take a look at that over the weekend.

I've also been thinking a lot about how to develop a public wiki for my notes. I've been looking for the perfect note-taking solution for a decade now and haven't really found what I'm looking for. Org mode comes the closest, but it ties me to a computer, and a computer with Emacs at that.<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup> I think any solution to the problem I'm actually trying to solve --- how to make my notes, basically, a seamless extension of my mind --- requires a web-based solution that I can access from any device, anywhere. I looked at a few wiki systems over the past week &#x2013; MediaWiki, DokuWiki, TiddlyWiki, BookStack, basically every wiki listed on this [&ldquo;awesome-selfhosted&rdquo;](https://github.com/awesome-selfhosted/awesome-selfhosted) repo. TiddlyWiki is far and away the closest to what I'm looking for because it makes the note the primary organizational unit, and the rest of the system is built around that. Compare this to the approach of MediaWiki where the Category is the primary organizational unit, and pages grow out of those categories.<sup><a id="fnr.2" class="footref" href="#fn.2">2</a></sup> This seems like a really great approach if you're trying to make documentation --- something like Wikipedia, or Confluence. But what I'm trying to emulate is more like a collection of StackOverflow snippets, linked together by *relatedness* somehow (probably tags). I don't want a &ldquo;page&rdquo; on OpenSSL, for example --- OpenSSL already has its own documentation! I want my own snippets of self-contained info that, for example, remind me how to use OpenSSL to validate a certificate, or generate a CSR. Basically, anything I turn to Google for, I want to jot in a note.

I've been testing Tiddlywiki all week on my home network, running on Node on a Raspberry Pi,<sup><a id="fnr.3" class="footref" href="#fn.3">3</a></sup> and have found it really helpful for note taking. Being able to access it from any device on my home network has made me utilize it a lot more than any org-based system I've tried to develop. But there are some issues that make me think that, ultimately, it is still not the right solution for a public &ldquo;wiki&rdquo;/commonplace book:

-   Authentication is limited. TiddlyWiki only supports HTTP basic auth. I'll need to stand up another kind of authentication proxy in front of it so I can have longer sessions.
-   I don't think it will work well with indexers/Google. I'd like people to be able to find my wiki.
-   As I've been using it this week, I've realized that I'll need a way to make *some* notes private. E.g., I put some medical notes in it this week --- I don't really want to share those with the Internet, and I also don't want to maintain separate private and public wikis. TiddlyWiki does not have a way to set permissions at the note level.

But I think it's the best out-of-the-box solution available right now. I'm thinking of setting up  a proof of concept for something like:

-   TiddlyWiki running on Node behind an authentication proxy; I'm the only one who can access it.
-   Export the wiki to a static site on a cron schedule; don't export notes with certain tags (e.g. `private`).
-   Something to make the static site searchable (index in Elasticsearch?)

I'm not sure if I want to spend time (and money) doing that now, or if I want to just set up the private wiki, skip the static site, and work on a clone in Django that would do everything I want. Eventually I can migrate the data I'm building in the private TiddlyWiki over to my app. I'm kind of leaning towards the latter right now.<sup><a id="fnr.4" class="footref" href="#fn.4">4</a></sup>

The other thing I want to think about, regarding this site, is setting up some GitHub Actions to run tests and push to S3 when I push anything to master. I did some reading on GitHub Actions this week and they look pretty slick.

## Footnotes

<sup><a id="fn.1" href="#fnr.1">1</a></sup> And, hopefully, my Emacs configuration.

<sup><a id="fn.2" href="#fnr.2">2</a></sup> Or, even worse, BookStack's confusing metaphors of shelves, books, chapters, and pages.

<sup><a id="fn.3" href="#fnr.3">3</a></sup> Sidenote: Node runs *incredibly* slowly on a Pi 3 B.

<sup><a id="fn.4" href="#fnr.4">4</a></sup> Another alternative could be Roam or Notion which both look appealing. I am really hesitant to use non-free software for something like this, but both Roam and Notion have excellent export functionality right now.
