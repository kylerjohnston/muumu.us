---
title: "Hosting a small, hobbyist Django app cheaply in AWS"
date: 2020-07-04
layout: post
excerpt: "A couple weekends ago I made a small Django app that basically functions as a journal. I wrote it to replace storing journal entries in Google Docs. Since then I've been trying to figure out the best and cheapest way I could host it on the Internet --- although we're self-isolating now, I will want to eventually leave my house some day and I'll probably want to make journal entries on the go. I don't care about scalability, although I do care about doing things right --- I don't want to take shortcuts that make it so it would be difficult to maintain or expand in the future."
tags: 
- python 
- docker 
- aws 
- django
---
A couple weekends ago I made a small Django app that basically functions as a journal. I wrote it to replace storing journal entries in Google Docs. Since then I've been trying to figure out the best and cheapest way I could host it on the Internet --- although we're self-isolating now, I will want to eventually leave my house some day and I'll probably want to make journal entries on the go. I don't care about scalability, although I do care about doing things *right* --- I don't want to take shortcuts that make it so it would be difficult to maintain or expand in the future.

I considered Heroku but ruled it out because it seemed expensive ($7/month for a 512 MB Dyno --- a t2.nano is ~$4.18/month) and I didn't see much value in learning it. So I went with AWS (I didn't look at Google Cloud or Azure because I already know the AWS ecosystem well).

I initially wanted to deploy the app to ECS or EKS fronted by an ALB and PostgreSQL either in RDS or on an EC2 instance. But the base price of an ALB is $0.0225/hour, plus an additional $0.008 per &ldquo;LCU-hour&rdquo;.<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup> At a *minimum*, just having an ALB running 24/7 for 30 days with no traffic will cost you $16.20.

So I came up with this basic network design instead:

![img](/img/journal_app_network_diagram.svg "Network diagram.")

A single t2.nano runs the Django app in a Docker container and nginx as a reverse proxy. Another t2.nano runs PostgreSQL (~$4.18/month compared to ~$13/month for the lowest tier RDS PostgreSQL). Static assets are served out of S3. The nginx/docker box pulls container images from ECR, which is free for up to 500MB of storage. Both t2.nanos are on demand for now, while I figure out how well they handle the load.

| Service | $ / month<sup><a id="fnr.2" class="footref" href="#fn.2">2</a></sup> |
|---|---|
| EC2 - 2 x t2.nano on demand | $8.35<sup><a id="fnr.3" class="footref" href="#fn.3">3</a></sup> |
| EBS - 3 x 8 GB<sup><a id="fnr.4" class="footref" href="#fn.4">4</a></sup> | $2.40<sup><a id="fnr.5" class="footref" href="#fn.5">5</a></sup> |
| S3 - 1.5 MB, < 1000 requests | $0.02<sup><a id="fnr.6" class="footref" href="#fn.6">6</a></sup> |
| ECR - 377 MB | $0.00<sup><a id="fnr.7" class="footref" href="#fn.7">7</a></sup> |
| Route53 - Private zone | $0.50<sup><a id="fnr.8" class="footref" href="#fn.8">8</a></sup> |
| **Total** | **$11.27** |

My initial testing looks like a t2.nano should be able to handle the load of just me using the app, although just barely. I may need to upsize the nginx/docker box to a t2.micro to get a gigabyte of RAM. At that point it may make sense to split nginx and docker host into separate boxes, and put the docker box in an auto-scaling group using spot instances.

I'd also ideally like to set up a private subnet, but at $0.045/hour a NAT gateway is $32.40/month. Even an EC2 instance with PFSense as a NAT would be about ~$11/month at a minimum, assuming it'll run on a t2.nano, doubling my costs. So for now the DB is just isolated by security groups. If I start building this out into a bigger lab that will come.

I may be able to save some money by putting Cloudfront in front of the S3 bucket, but for now I can't see how I'd have more than 1000 requests a month from just me using the app, and at that rate the S3 cost is negligible. But it's something to keep an eye on if I ever decide to open it up to the public.

Now that I'm writing this up I wonder if I should just install the ECS agent on the nginx/docker box and see if I can use ECS to start tasks. Easier than manually pulling and deploying from ECR. I think I'm gonna try that.

# Footnotes

<sup><a id="fn.1" href="#fnr.1">1</a></sup> <https://aws.amazon.com/elasticloadbalancing/pricing/>

<sup><a id="fn.2" href="#fnr.2">2</a></sup> Everything is in us-east-1.

<sup><a id="fn.3" href="#fnr.3">3</a></sup> <https://aws.amazon.com/ec2/pricing/on-demand/>

<sup><a id="fn.4" href="#fnr.4">4</a></sup> I attached a second volume to the database to hold the data. It's LVM so I can grow it if needed in the future.

<sup><a id="fn.5" href="#fnr.5">5</a></sup> <https://aws.amazon.com/ebs/pricing/>

<sup><a id="fn.6" href="#fnr.6">6</a></sup> <https://aws.amazon.com/s3/pricing/>

<sup><a id="fn.7" href="#fnr.7">7</a></sup> <https://aws.amazon.com/ecr/pricing/>

<sup><a id="fn.8" href="#fnr.8">8</a></sup> <https://aws.amazon.com/route53/pricing/>
