---
title: "Using ldd to find shared dependencies"
date: 2020-02-12
layout: post
categories: 
- sysadmin
tags: 
---

Yesterday I discovered a cool program called `ldd` that ships with the GNU C library. `ldd` prints the shared libraries used by a program.

Running `ldd /usr/bin/which`, for example, returns:

{% highlight nil %}
linux-vdso.so.1 (0x00007ffe007cb000)
libselinux.so.1 => /lib64/libselinux.so.1 (0x00007f58600ed000)
libcap.so.2 => /lib64/libcap.so.2 (0x00007f58600e6000)
libc.so.6 => /lib64/libc.so.6 (0x00007f585ff1d000)
libpcre2-8.so.0 => /lib64/libpcre2-8.so.0 (0x00007f585fe8b000)
libdl.so.2 => /lib64/libdl.so.2 (0x00007f585fe84000)
/lib64/ld-linux-x86-64.so.2 (0x00007f5860162000)
libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f585fe62000)
{% endhighlight %}

I found this helpful when setting up a `chroot` environment &#x2014; it's a quick way to find out which libraries need to be copied over.
