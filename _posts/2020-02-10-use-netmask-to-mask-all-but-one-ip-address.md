---
title: "Use netmask to mask all but one IP address"
date: 2020-02-10
layout: post
categories: 
- sysadmin 
- networking
tags: 
---
I learned this trick from a coworker today. You can use the `netmask` utility to generate subnet masks for everything but a single IP address. Let's say I want to whitelist 143.204.147.102 but whatever tool I'm using only lets me blacklist IPs. 

{% highlight shell %}
netmask 0.0.0.0:143.204.147.101
{% endhighlight %}

Returns:

{% highlight shell %}
	0.0.0.0/1
      128.0.0.0/5
      136.0.0.0/6
      140.0.0.0/7
      142.0.0.0/8
      143.0.0.0/9
    143.128.0.0/10
    143.192.0.0/13
    143.200.0.0/14
    143.204.0.0/17
  143.204.128.0/20
  143.204.144.0/23
  143.204.146.0/24
  143.204.147.0/26
 143.204.147.64/27
 143.204.147.96/30
143.204.147.100/31
{% endhighlight %}

And:

{% highlight shell %}
netmask 143.204.147.103:255.255.255.255
{% endhighlight %}

Returns:

{% highlight shell %}
143.204.147.103/32
143.204.147.104/29
143.204.147.112/28
143.204.147.128/25
  143.204.148.0/22
  143.204.152.0/21
  143.204.160.0/19
  143.204.192.0/18
    143.205.0.0/16
    143.206.0.0/15
    143.208.0.0/12
    143.224.0.0/11
      144.0.0.0/4
      160.0.0.0/3
      192.0.0.0/2
{% endhighlight %}

Rather than whitelisting my one IP, I can blacklist everyone else!