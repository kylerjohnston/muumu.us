---
title: "Setting up Mopidy on a Raspberry Pi"
date: 2020-05-25
layout: post
excerpt: "A couple weekends ago I set up a Mopidy server on my Raspberry Pi."
tags: 
- mopidy 
- raspberry-pi 
- ansible
---
A couple weekends ago I set up a [Mopidy](https://mopidy.com/) server on my Raspberry Pi. Mopidy describes itself as a &ldquo;music server&rdquo;:

> Mopidy plays music from local disk, Spotify, SoundCloud, Google Play Music, and more. You can edit the playlist from any phone, tablet, or computer using a variety of MPD and web clients. 

I have a stereo receiver in my office that I use for my turntable, but because of the layout of the room the receiver is on the wall opposite my desk, where my computer is. If I want to listen to music via Spotify or local files I need to connect to the receiver with Bluetooth &#x2014; it works okay, but I&rsquo;ve been using it eight hours a day while working from home the past couple months and the dropped connections and radio interference are becoming frequent and annoying enough that I want a hard wired solution. I ended up settling on Mopidy on a Raspberry Pi 3 Model B running Raspbian Buster, connected to Spotify, YouTube, and Last.fm, and local storage. I chose the 3 B because I already had one that was only being used as a Borg backup server.

Trying to hold myself to more of a regular schedule of writing here &#x2014; hopefully every weekend &#x2014; so I figured I would just type up my notes on its installation and configuration, and the small Ansible playbook I wrote to automate it.

First, add the public key for the Mopidy PPA to apt&rsquo;s trusted keys, and install the repo.

{% highlight yaml %}
- name: Add Mopidy PPA key
  apt_key:
    url: https://apt.mopidy.com/mopidy.gpg
    state: present
  become: yes
  become_user: root

- name: Install Mopidy Debian Buster PPA
  get_url:
    url: https://apt.mopidy.com/buster.list
    dest: /etc/apt/sources.list.d/mopidy.list
    force: no
    mode: 0644
    owner: root
    group: root
  become: yes
  become_user: root
{% endhighlight %}

Then you can install all the packages you need. Mopidy is a modular system. The Mopidy application itself is just the server &#x2014; you have to install other extensions to get more features, like a web UI, Spotify connectivity, etc. Altogether I&rsquo;m installing five applications: Mopidy, the Mopidy server itself; [Iris](https://github.com/jaedb/Iris), a web UI for the server; [Mopidy-Spotify](https://github.com/mopidy/mopidy-spotify), an extension for playing Spotify; [Mopidy-YouTube](https://github.com/natumbri/mopidy-youtube) for playing music from YouTube (today&rsquo;s crate digging); [Mopidy-Scrobbler](https://github.com/mopidy/mopidy-scrobbler) to connect to Last.fm. Some are available in Raspbian&rsquo;s repos, and some I need to install via pip.

{% highlight yaml %}
- name: Install Mopidy Debian packages
  package:
    name:
      - mopidy
      - python3-pip
      - mopidy-spotify
      - gstreamer1.0-plugins-bad
    state: latest
  become: yes
  become_user: root

- name: Install Mopidy Python3 packages
  pip:
    executable: /usr/bin/pip3
    name:
      - Mopidy-Iris
      - Mopidy-Youtube
      - Mopidy-Scrobbler
    state: present
{% endhighlight %}

Everything is configured via a single config file that lives in `/etc/mopidy/mopidy.conf`. The configuration contains secrets &#x2014; passwords and API keys. Since my Ansible config lives in a [public GitHub repo](https://github.com/kylerjohnston/ansible/) I put the config file into a Jinja template and pull the secrets from environment variables.

My template looks like this:

{% highlight jinja %}
{% raw %}
[http]
enabled = true
hostname = 0.0.0.0
port = 6680
zeroconf = Mopidy HTTP server on $hostname
allowed_origins = 
csrf_protection = true
default_app = iris

[iris]
country = us
locale = en_US

[spotify]
username = becomingyolo
password = {{ lookup('env', 'SPOTIFY_PASSWORD') }}
client_id = {{ lookup('env', 'MOPIDY_SPOTIFY_CLIENT_ID') }}
client_secret = {{ lookup('env', 'MOPIDY_SPOTIFY_CLIENT_SECRET') }}
bitrate = 320

[youtube]
enabled = true

[scrobbler]
username = becoming-yolo
password = {{ lookup('env', 'LASTFM_PASSWORD') }}
{% endraw %}
{% endhighlight %}

This Ansible block installs it in the right place and sets permissions:

{% highlight yaml %}
- name: Install /etc/mopidy/mopidy.conf
  template:
    src: mopidy.conf.j2
    dest: /etc/mopidy/mopidy.conf
    owner: mopidy
    group: root
    mode: 0640
  become: yes
  become_user: root
{% endhighlight %}

Iris needs to run its install script with elevated privileges.

{% highlight yaml %}
- name: Ensure Iris has access to install itself
  lineinfile:
    path: /etc/sudoers
    regexp: '^mopidy'
    line: "mopidy ALL=NOPASSWD: /usr/local/lib/python3.7/dist-packages/mopidy_iris/system.sh"
  become: yes
  become_user: root
{% endhighlight %}

With all of that in place, the only thing left to do is start and enable the `mopidy` service.

{% highlight yaml %}
- name: Start and enable mopidy service
  systemd:
    name: mopidy
    state: started
    enabled: yes
  become: yes
  become_user: root
{% endhighlight %}

Overall I&rsquo;ve been happy with Mopidy. Iris has a mature interface that should be familiar to anyone who&rsquo;s used Spotify. It was simple to set up, and a definite step up from the Bluetooth setup was using before.
