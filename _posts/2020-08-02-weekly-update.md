---
title: "Another Weekend"
date: 2020-08-02
layout: post
excerpt: "I've never been able to get super into Ariel Pink, but he does have a few great tracks. Spotify has been pushing 'Another Weekend' on me heavily the past week. I've also been listening to Daniel Johnston, especially this 'Live in Berlin' record which I found on Spotify and had never listened to before. Been listening to that daily the past week."
tags: 
- tiddlywiki 
- diy 
- records 
- cats
---
I've never been able to get super into Ariel Pink, but he does have a few great tracks. Spotify has been pushing *Another Weekend* on me heavily the past week. I've also been listening to Daniel Johnston, especially this *Live in Berlin* record<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup> which I found on Spotify and had never listened to before. Been listening to that daily the past week.

It has felt like a busy week. Didn't get so much time to work on my personal projects &#x2014; hung out a lot with Jami, and spent a few hours on the phone with my parents for the first time in a while.

I destroyed the infrastructure I'd built for my Django journaling app, documented in [this post]({% post_url 2020-07-04-hosting-a-hobbyist-django-app %}). I've stopped using the app, and really only built it to learn Django, so there's no sense in paying to keep it running.

Last week I [talked about]({% post_url 2020-07-26-weekly-update %}) running a private TiddlyWiki on Node.js that I could export to a static site on a cron schedule. I've decided against that approach. There were two main requirements motivating it: 1. I wanted to be able to mark some notes as private and not have those exported to the public site; and 2. I was worried about how indexable a TiddlyWiki is for Google, and figured a static site would fare better. For the first point, I've decided that a more traditional wiki<sup><a id="fnr.2" class="footref" href="#fn.2">2</a></sup> would work better for the kinds of info I'd want to keep private &#x2014; medical and financial notes, other personal things. And for point 2, I just don't really care &#x2014; my main motivation for this is to cultivate my own knowledge base; that it's public is just a nice bonus, and I really think a TiddlyWiki, not a static site, is a super intuitive and great interface for that kind of application. So I've decided that I want two kinds of things: a public TiddlyWiki (only editable by me, of course) that acts as my public personal knowledge base; and a private wiki (maybe even just hosted on my home network) that I'll use to organize other personal data.

I wanted to get the TiddlyWiki up and running on the internet over the weekend but I only had a little time to start building out the infrastructure.  I have a single t3a.nano instance running nginx as a reverse proxy to TiddlyWiki running on Node.js in Docker. TiddlyWiki's built in basic auth isn't working behind the proxy I set up &#x2014; I need to set up some kind of header forwarding to get that working, but I want to make sure I do it in such a way that both authenticated and unauthenticated users can get to the site.

I spent a lot of the day Saturday grinding the rust off the dishwasher racks with a Dremel, and Jami painted the liquid vinyl stuff over the bare spots to repair them. We also found a cool little set of trails in town<sup><a id="fnr.3" class="footref" href="#fn.3">3</a></sup> that we'd never noticed before, and went for a hike. I also spent some time fixing any solder joints that looked questionable on my keyboard build to try to get it working, but it's still dead. Not really sure what my next steps there are, and I'm honestly not that motivated to continue with it now.

My copy of the reissue of *Green* by Hiroshi Yoshimura, that I pre-ordered in March, finally arrived on Friday. I gave it a couple spins, but I'm not listening to records as much as I had been at the start of the pandemic now that we have Bobby. There's always a cat in the study now, where the record player is, and they both like to jump on the turntable. I obviously don't want them jumping on it while a record is playing.

Bobby seems to be doing a lot better lately, as a follow up to [this post]({% post_url 2020-07-10-breaking-bad-bobby %}). We've been following our plan with only a few modifications for three weeks now. We've gone down to feeding them five times a day, instead of six, because they were getting bored of the food.<sup><a id="fnr.4" class="footref" href="#fn.4">4</a></sup> We also stopped recording metrics daily because we weren't getting much value out of it &#x2014; it's pretty easy to just tell when progress is being made. And progress is being made a little bit &#x2014; we're now feeding them with the door open, with two baby gates stacked on top of each other in the doorway separating them, and a curtain draped over the gates. We start each feeding session with the curtain raised now so they can see each other, but about half the time we need to lower the curtain because Bobby gets distracted by Tiggy. I think once we're comfortable feeding with the curtain open 100% of the time for a couple weeks we'll be able to move on to the next step of opening the gate.

# Footnotes

<sup><a id="fn.1" href="#fnr.1">1</a></sup> Check this out: <https://www.youtube.com/watch?v=Wipou7sCEz4>

<sup><a id="fn.2" href="#fnr.2">2</a></sup> Either BookStack or Mediawiki, I haven't put that much thought into it yet.

<sup><a id="fn.3" href="#fnr.3">3</a></sup> <https://mainebyfoot.com/milliken-mills-trails-old-orchard-beach/>

<sup><a id="fn.4" href="#fnr.4">4</a></sup> Shocking, I know.
