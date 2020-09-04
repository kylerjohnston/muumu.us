---
title: "On call, fiddling with the wiki"
date: 2020-08-09
layout: post
excerpt: "I'm on call this weekend, and one of our sites has been under attack from a bot net for the past 24 hours. I'm getting paged pretty frequently, which has put me off of doing anything technical in my free time. So I just laid around and baked some banana bread today, when I wasn't working."
tags: 
- tiddlywiki
---

I'm on call this weekend, and one of our sites has been under attack from a bot net for the past 24 hours. I'm getting paged pretty frequently, which has put me off of doing anything technical in my free time. So I just laid around and baked some banana bread today, when I wasn't working.

Before my on call shift started, I did manage to get basic auth working on TiddlyWiki through the reverse proxy. Not sure what the issue was last week when I couldn't get it working --- I didn't really do anything to fix it. Guess I just needed a fresh set of eyes. It's working well, but it's a little slow. I want to do some load testing on it to compare things like enabling gzip compression on nginx vs. on TiddlyWiki, or running in Docker vs. running "bare metal" on EC2. There may be other Node parameters I can tweak for optimization --- I've never really worked with Node apps before so I'm not sure what the options are there. Before I can do that, though, I need to get some better monitoring in place. I did spend a little time this morning, before the alarms from work started going off, getting some CloudWatch metrics for memory utilization set up. I do want to write a blog post on setting up the TiddlyWiki once my load testing is done, and add it to the nav bar on the blog.

This project also has me thinking I want to do a deep dive into nginx. My job is, partly, to be an nginx admin, but I am far from an expert. Not really sure what the best approach is for that --- I looked for a book but don't really see anything that looks great. I'll probably just dig into the documentation, but I'd like a way to read it on my Kindle.
