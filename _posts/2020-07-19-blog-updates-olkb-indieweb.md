---
title: "Blog updates, ortholinear keyboards, and second brains"
date: 2020-07-19
layout: post
categories: 
tags: 
- muumuus 
- keyboards 
- tiddlywiki 
- indieweb
---
I&rsquo;d like to start getting in the habit of posting more frequently, which means doing a better job of writing quickly and spending less time editing. It&rsquo;s okay for these to come across as works in progress (because what isn&rsquo;t?). So this is just a short update on what I&rsquo;ve been up to the last week.

First, the blog&rsquo;s look has changed. I started working on the new design last weekend; I guess I&rsquo;ll be pushing it live when I publish this because I&rsquo;ve merged it into master. I found the [Marx](https://mblode.github.io/marx/) classless CSS stylesheet a couple weekends ago when looking for a way to quickly style a prototype UI for a Django app I&rsquo;ve been working on. I hate writing CSS, and I liked the simplicity of Marx, so I replaced the Jekyll theme I was using here with Marx, only customizing it a tiny bit.

I also did some reading on [the IndieWeb](https://indieweb.org/) and it&rsquo;s given me some new ideas for the direction of this site. I think instead of just a blog where I post things once or twice a month, I&rsquo;d like to turn this site into my personal web presence. In that same vein, I want to start some sort of more freeform knowledge base/commonplace book/&ldquo;second brain&rdquo; as another part of this site. This is something I&rsquo;ve been wanting to do for years &#x2014; I think its been the driving desire behind every site I&rsquo;ve ever built. Memory is fleeting, and the Internet and hypertext is the perfect medium to capture it and make it re-discoverable. And it seems like a project like that would have real, literary potential &#x2014; after forty, fifty, sixty years of incremental building you&rsquo;d have a text that would be vastly complex. But I&rsquo;ve never found a good way to implement it, or a process that encourages me to keep implementing it. I found [TiddlyWiki](https://tiddlywiki.com/) today and I think it might be a good solution &#x2014; at least worth testing it out. It can be hosted with Node, and it could be publicly readable but only writable via authentication. I could link it to a subdomain here.

Last weekend I started assembling an [Ortho48](https://cannonkeys.com/collections/frontpage/products/ortho48) ortholinear keyboard from Cannon Keys. I messed it up by soldering the Blue Pill before the switches, which prevented me from soldering a few switches that the Blue Pill covered up. I tried to remove the Blue Pill but I couldn&rsquo;t &#x2014; I don&rsquo;t have the best soldering skills. So I gave up on that board and I bought a [Levinson](https://keeb.io/collections/keyboard-pcbs/products/levinson-lets-split-w-led-backlight) split ortholinear board from Keeb.io to replace it. I got that about 90% done, but I don&rsquo;t have enough switches to finish it &#x2014; I had soldered a little over a dozen switches to the Ortho48 before I realized the Blue Pill was going to block soldering the rest of them, and I broke a few of those trying to remove them. So I&rsquo;m four switches short of finishing the Levinson. I was stumped for a few minutes trying to flash the Pro Micro controller with QMK because `avrdude` would just hang on `Waiting for /dev/ttyACM0 to become writable.......` after I reset the controller. Then I realized that was because my user didn&rsquo;t have permission to write to the device. I flashed as root without issue.

In other news, our baby gates finally arrived so we fed the cats with the door open (with two baby gates stacked one on top of the other, and a curtain draped behind them) for the first time tonight.

That&rsquo;s all for now.
