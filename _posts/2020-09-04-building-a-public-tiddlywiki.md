---
title: "Building an internet-facing TiddlyWiki for my public second brain"
date: 2020-09-04
layout: post
excerpt: "In this post I describe the process I took to build a digital public knowledge repository with TiddlyWiki, AWS, Node.js, and GitHub Actions."
tags: 
- tiddlywiki 
- public-notes
- github-actions
- aws
---


## Introduction

For the past few weeks, in my free time, I've been working on [public-notes.muumu.us](https://public-notes.muumu.us).

The goal of this project is to have a public digital repository for all of my knowledge --- project notes, one-off thoughts, bookmarks, lists of books I've read or want to read, etc. Something like a digital [commonplace book](https://en.wikipedia.org/wiki/Commonplace_book). I see it as both a productivity hack (a great way to take and find notes) and a literary project.<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup>

I evaluated many software options for the project and ultimately ended up choosing [TiddlyWiki](https://tiddlywiki.com/) because:

-   It's open source, and I can host it myself;
-   Its interface and organizational model privilege the individual *note*, compared to the category-first model of basically all other wiki software;
-   David Gifford's [Stroll](https://giffmex.org/stroll/stroll.html) plugin gives it backlinks and transclusions to make an experience which closely resembles [Roam](https://roamresearch.com/), which would probably have been my choice for a platform if it was open source and could be self-hosted.<sup><a id="fnr.2" class="footref" href="#fn.2">2</a></sup>

In the rest of this post I'll describe the several approaches I took to implement this public TiddlyWiki, the final solution I ended up implementing, and my thoughts on where the site will go from here.


## Figuring out the right implementation

TiddlyWiki is a weird piece of software. A JavaScript application written by [Jeremy Ruston](https://jermolene.com/ "Jeremy Ruston"), older iterations of it shipped as a single HTML file with inline scripts and data. It was intended to be used as a personal notebook; you saved the HTML file to your computer (or a USB drive or DropBox, if you wanted to use it across multiple devices), updated the notebook by interacting with the file in your web browser, and then saved any changes by downloading a new copy, overwriting the outdated HTML file.

TiddlyWiki5 is a ["reboot of TiddlyWiki for the next 25 years"](https://tiddlywiki.com/#TiddlyWiki5 "TiddlyWiki5 - a reboot of TiddlyWiki") which can also run as a Node.js application in a client-server model. Running in this mode, TiddlyWiki stores each note (or "tiddler", in TW-speak) in a separate text file, using a custom markup DSL that's close to, but not, markdown, and the node process renders those tiddlers into the page you see in your browser. Any changes you make on the client side are pushed to the server. It has some basic user management and access control features.

My initial plan was to host a single TiddlyWiki5 Node.js app that would allow read-write access to authenticated users (me), and read-only access to everyone else. Ultimately this approach didn't work, for reasons I'll get into in the sections below, and I ended up with a Node.js app that I write to and a separate, single-HTML-file static TiddlyWiki rendered from the Node.js app that I serve at [public-notes.muumu.us](https://public-notes.muumu.us "public-notes.muumu.us").

### Docker was a bad choice
I first tried running TiddlyWiki in a Docker container. I had Docker on the mind. I use it and ECS heavily at work, and have found them together to be a good and relatively simple solution for deploying and scaling applications. Just a couple weeks earlier I had worked out [a good system for deploying a Dockerized Django app to EC2]({% post_url 2020-07-04-hosting-a-hobbyist-django-app %}) for my own projects. My thinking was that Docker would:

- Simplify maintenance. I could run Ubuntu updates on a cron without worrying about npm package updates breaking the application. When there's a new version of TiddlyWiki, I'd just rotate in a new image after testing it offline first.
- Make scaling easier. I planned to eventually move it to ECS or EKS and configure autoscaling that way.

But the Docker approach had some downsides. First, I had to roll my own image because I couldn't find an existing one that allowed me to modify the [listen command](https://tiddlywiki.com/static/ListenCommand.html "TiddlyWiki listen command") to allow authenticated writers and anonymous readers --- something like:

`--listen username=${TIDDLY_USER} password=${TIDDLY_PASSWORD} readers=(anon) writers=(authenticated)`

So I wrote my own Dockerfile, built the image, and pushed it to ECR. If I wanted to update to a new version of TiddlyWiki, I'd need to build a new container. This would *not* simplify maintenance.

On top of that, it was just plain slow. I wasn't sure if that was because of Docker or if it was just because TiddlyWiki is slow, so I ran some load tests with [Siege](https://www.joedog.org/siege-home/ "Siege") to compare it running in Docker versus just running on Node on the bare server.

I ran Siege with its default settings, 25 concurrent connections over 1 minute, just to get a baseline idea of the app's performance. All tests were run against the same t3a.micro EC2 instance with an Nginx reverse proxy to the TiddlyWiki process, with a cool-down period of about an hour between each test. I tested TiddlyWiki running in a Docker container, TiddlyWiki running on Node.js without any kind of process management (just running in a tmux session), and TiddlyWiki running on Node.js managed by PM2. These were the results:

<table>
    <caption>Siege load test results</caption>
    <thead>
        <tr class="header">
            <th>Metric</th>
            <th>Docker</th>
            <th>Node.js</th>
            <th>w/ PM2</th>
        </tr>
    </thead>
    <tr>
        <td markdown="span">Transactions</td>
        <td markdown="span">500</td>
        <td markdown="span">552</td>
        <td markdown="span">568</td>
    </tr>
    <tr>
        <td markdown="span">Data transferred</td>
        <td markdown="span">160.29</td>
        <td markdown="span">177.05</td>
        <td markdown="span">182.22</td>
    </tr>
    <tr>
        <td markdown="span">Response time</td>
        <td markdown="span">2.72</td>
        <td markdown="span">2.57</td>
        <td markdown="span">2.55</td>
    </tr>
    <tr>
        <td markdown="span">Transaction rate</td>
        <td markdown="span">8.45</td>
        <td markdown="span">9.25</td>
        <td markdown="span">9.56</td>
    </tr>
    <tr>
        <td markdown="span">Throughput</td>
        <td markdown="span">2.71</td>
        <td markdown="span">2.97</td>
        <td markdown="span">3.07</td>
    </tr>
    <tr>
        <td markdown="span">Concurrency</td>
        <td markdown="span">22.99</td>
        <td markdown="span">23.74</td>
        <td markdown="span">24.33</td>
    </tr>
    <tr>
        <td markdown="span">Longest transaction</td>
        <td markdown="span">6.49</td>
        <td markdown="span">5.53</td>
        <td markdown="span">5.63</td>
    </tr>
    <tr>
        <td markdown="span">Shortest transaction</td>
        <td markdown="span">0.09</td>
        <td markdown="span">0.09</td>
        <td markdown="span">0.09</td>
    </tr>
</table>

It was clear that Docker was slowing things down a bit --- I was getting almost 14% more transactions and 13% higher throughput running with PM2.

I also ran load tests on PM2 in cluster mode, but I won't put those results here since I discovered while testing that it wouldn't work, at least not for a TiddlyWiki that allows writing. TiddlyWiki running under Node can only see changes its made --- if the tiddlers change on the filesystem outside of TiddlyWiki, the process has to be restarted for it to pick them up. Because of this you can't have more than one TiddlyWiki process running if you're writing to it. Given that, the other draw of Docker was moot --- I wouldn't be able to scale with more Docker containers because I can only ever have a single process.

So I learned that, for this problem, Docker was more difficult to maintain, slower, and wouldn't help me scale. I decided to abandon Docker and use PM2.

### Problems with TiddlyWiki on Node.js
I abandoned Docker, installed Node.js on my server, and started managing the TiddlyWiki process with PM2. I left it running that way for about a week, and things seemed to be working well --- I was using the wiki daily, as my own authenticated user, to take notes. That weekened when I sat down to write a blog post about it, though, I noticed unauthenticated access was not working the way I wanted.

I was running a single TiddlyWiki process under PM2 that was started with a command like this:

```bash
tiddlywiki wiki --listen host=localhost \
  port=8080 \
  username="${TIDDLY_USER}" \
  password="${TIDDLY_PASSWORD}" \
  readers='(anon)' \
  writers='(authenticated)'
```

This should allow users who are authenticated (me) to edit the TiddlyWiki, and unauthenticated users to read it.

I discovered that the writer's active tiddlers --- the notes I had open on my screen as an authenticated user --- would also show up as the active tiddlers for the anonymous readers. If I was drafting a note, that note would show up as the active tiddler for all the anonymous readers. TiddlyWiki seemed to be sharing the writer's state with all other users.<sup><a id="fnr.3" class="footref" href="#fn.3">3</a></sup>

So I pivoted to a new idea: I'd run two TiddlyWiki processes, one for private editing access and one for public read-only access.

Even though the public TiddlyWiki was read-only, it still tried to modify the `$__StoryList.tid` tiddler, so I cloned the repo for my tiddlers into two locations on my filesystem to avoid conflicts, `/srv/private` for the private TiddlyWiki and `/srv/public` for the public one. I set a cron job to run once a day to commit and push all changes from `/srv/private`, and another cron to do a pull and hard reset into `/srv/public`. Since a TiddlyWiki process can't see changes made to tiddlers on the filesystem, I set another cron to restart the public TiddlyWiki process after pulling the changes.

I quickly encountered a frustrating bug with this approach. As an anonymous user, every so often the TiddlyWiki would "reset" --- all of the active tiddlers I had open would just disappear. After playing around with it a bit, I discovered it was happening a couple seconds after I clicked one of the buttons to hide or show transclusions at the bottom of a tiddler. This is a feature implemented by the Stroll plugin. I also noticed that the "Sync" icon on the sidebar would flash red when it happened. It seemed that hiding or showing the transclusions wasn't just some client-side JavaScript, but was actually changing the state of the tiddler, and since the user didn't have write privileges it would just revert the changes (and reset the whole state back to a fresh TiddlyWiki with no open tiddlers). I did some further testing with the writeable TiddlyWiki and confirmed that toggling whether a transclusion is shown or hidden does indeed make a persistent change to the tiddler's state.

### Why do read-only users need Node?
This was not an acceptable user experience. I couldn't have it so that users could click a button --- a button that looks like it should be clicked! --- and reset all their open tiddlers.

I took a step back and re-evaluated. I had:

- Two TiddlyWiki processes, one public, read-only, and the other private and editable;
- The same repository cloned to two locations on the filesystem;
- Three cron jobs to push and pull to and from git, and to restart the public TiddlyWiki process.

Things were getting complicated --- and what for?

Node.js solves the problem of editing a single TiddlyWiki from multiple devices. But what value does it bring to a read-only TiddlyWiki? The only benefit I could think of is that maybe Node would serve tiddlers on demand, reducing bandwidth. But tiddlers aren't served on demand --- Node sends the entire TiddlyWiki, with all tiddlers, in a single request. It doesn't save any bandwidth over just sending the TiddlyWiki as an HTML file.

So that's what I did. I stopped the public TiddlyWiki node process, got rid of the duplicate `/srv/public` repo, and set up a GitHub Action to render the TiddlyWiki into a single HTML file and copy it to S3 with every push to master:

``` yaml
name: Build static site and deploy to S3

on:
  push:
    branches:
      - master

jobs:
  build_site:
    name: Build static site and deploy to S3
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Setup node
        uses: actions/setup-node@v1

      - name: Install Tiddlywiki
        run: npm install -g tiddlywiki

      - name: Render static file
        run: cd ../ && tiddlywiki wiki --rendertiddler $:/plugins/tiddlywiki/tiddlyweb/save/offline index.html text/plain

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Sync to S3
        run: aws s3 cp ./output/index.html s3://public-notes.muumu.us
```

So I ended up with two sites. The private site uses Node.js running on a t3a.micro EC2 instance. The pubic site, [public-notes.muumu.us](https://public-notes.muumu.us "public-notes.muumu.us"), is a single HTML file served from S3, fronted by CloudFront.


### Estimated costs
The only resource used by the private TiddlyWiki is a t3a.micro, at standard on-demand pricing for now which is $0.0094 per hour, or **about $6.77 per month**. I think that I might be able to scale down to a t3a.nano at this point, and once I'm confident in the size that I need I can buy reserved pricing and probably cut that cost in half.

The public site's cost is a little more complicated. CloudFront's pricing model charges by data transferred and number of requests: $0.085 per GB of data transferred (for the first 10 TB), and $0.0075 per 10,000 requests (from the US and Canada, but that's the only region I've enabled).

At the time I wrote this, the `index.html` file containing the whole TiddlyWiki was 2.8 MB uncompressed. With CloudFront's gzip compression enabled, a request to the page transfer 533.25 KB.

muumu.us gets about 100 requests per day; let's assume public-notes.muumu.us wil get the same. 100 requests * 0.53325 MB * 30 days = 1.59975 GB of data transferred per month. $0.085 * 1.59975 GB = $0.135 for data transfer costs. Plus $0.0075 for the requests (less than 10,000), comes to **about $0.14 per month**.

But, what would happen if I hit the front page of HackerNews? Instead of 100 requests a day, let's imagine I average 10,000 requests a day for a month. 10,000 requests * 0.53325 MB * 30 days = 159.975 GB of data transferred. 159.975 GB * $0.085 = $13.597. Plus 30 * $0.0075 (300,000 requests) = $0.225. Altogether it would be **$13.82**. So even if the site were to blow up, somehow, I'm not going to be backrupted by a massive AWS bill.

So, for the average month both sites together will probably cost me around **$7**, and could be optimized even further to probably cut that cost in half by using a reserved instance or a cheaper VPS provider. For comparison, a subscription to Roam is $15 per month.

## Conclusion
I think TiddlyWiki is a great piece of software, and the user interface is exactly what I want from a note taking/writing application. TiddlyWiki feels like an extension of my mind --- each thought gets its own tiddler, I don't have to worry about organizing it or categorizing it, and the relationships between them grow organically over time as more and more tiddlers are created and interconnected.

But there are also a lot of things I dislike about TiddlyWiki:

- Authentication is limited to HTTP basic auth.
- Page size. All data for the TiddlyWiki is sent to the browser on the first request. I just started this wiki and it's already big! Imagine the size after a few years. Sure, my browser can handle opening a 250 MB TiddlyWiki --- but do I want to be sending those requests over the internet to the public? That's a lot of bandwidth!
- User management/access controls are rudimentary, and, as I discovered here, don't really work well. I wasn't able to have a single TiddlyWiki process allowing write access for me and read-only access for everyone else.
- A custom markup language. Just use markdown!
- It's not indexable; no one is going to find anything in my notes via Google.

I think the root of all of these issues is that TiddlyWiki wasn't really made to be a web app --- it's a personal knowledge management system that's made to be used on your desktop, and you can sort of hack it to work on the web like I did.

For now, TiddlyWiki does the job and allows me to push out an MVP of the public-notes project. But I think there is a lot of room for improvement, and at some point I'm going to be forced to build my own app as a replacement, if only because the wiki is going to grow too large. Despite the abundance of note taking applications these days, I still think there's a big niche here waiting to be filled by something that can offer a TiddlyWiki-like experience, but is web-first.

## Footnotes

<sup><a id="fn.1" href="#fnr.1">1</a></sup> Maybe even a metaphysical project, if I train GPT-*n* on it.

<sup><a id="fn.2" href="#fnr.2">2</a></sup> After using TiddlyWiki for the past month, though, I've come to love it and don't see any reason to switch to Roam.

<sup><a id="fn.3" href="#fnr.3">3</a></sup> At the time I didn't have any default tiddlers set --- I don't know if doing that would fix this issue or not.
