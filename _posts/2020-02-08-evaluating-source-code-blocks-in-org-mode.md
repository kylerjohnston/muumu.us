---
layout: post
title: Evaluating source code blocks in org mode with Babel
date: 2020-02-08
categories: emacs org-mode
tags: emacs org-mode
---

By default babel will only allow you to execute emacs-lisp source code blocks. You can enable babel to allow execution of code blocks in a bunch of different languages though --- you can find a full list in the [Org Mode Manual](https://orgmode.org/manual/Languages.html#Languages).

~~~ emacs-lisp
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)
     (ruby . t)))
~~~

To evaluate a block, type *C-c C-c*.