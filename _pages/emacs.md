---
title: "Emacs Configuration"
date: 2020-02-23
layout: post
categories: 
tags: 
- emacs
permalink: /emacs/
---

# Table of Contents

-   [Preface](#org683878f)
-   [UI and basic configuration](#orga52c0f8)
    -   [Fonts](#org4ff28bc)
    -   [Doom Themes](#orge56c7b5)
-   [Evil](#org84fe551)
-   [Org mode](#org6e3133d)
    -   [Agenda](#org4a4167f)
    -   [UI/UX](#org5a14183)
    -   [Babel](#orgb844467)
    -   [Publishing](#orge466b98)
    -   [Capture templates](#org03821a3)
-   [Dired](#orga0e46d0)
-   [Company](#org7cf23a8)
-   [Languages](#org8f92288)
    -   [GraphViz](#orga262c1d)
    -   [LaTeX](#org6d61f8c)
    -   [Ruby](#orgd43d610)
    -   [SaltStack](#org5aab32e)
    -   [Terraform](#org0762c5e)
-   [Magit](#org50db5a2)
-   [Diminish](#orgb920bc6)
-   [Ivy/Counsel/Swiper](#orgfebc188)
-   [Start Emacs server](#org410d691)
-   [References](#orgf09d18f)


<a id="org683878f"></a>

# Preface

This is my literate Emacs configuration, written in org-mode and exported with [ox-jekyll-md](https://github.com/gonsie/ox-jekyll-md). You can see the raw, un-exported version on my [emacs.d GitHub repo](https://github.com/kylerjohnston/emacs.d). Take a look at [init.el](https://github.com/kylerjohnston/emacs.d/blob/066ef819f41061230da541a5a6c481cd7c647409/init.el) there, which is first read by Emacs and does some basic bootstrapping, setting up package archives and `use-package`, and then calls `org-babel-load-file` on `emacs.org`, the unexported version of this file, which pulls all the Emacs Lisp source blocks from this file, stitches them into an Emacs Lisp file called `emacs.el`, and executes it.

This is my third or fourth Emacs configuration. I was a vim user but started using Emacs in grad school, some time around 2015 I think, when I discovered org-mode. I started out using [Spacemacs](https://www.spacemacs.org/) then, but quickly got overwhelmed by how much *stuff* there was in it and moved to vanilla Emacs. Here is [my last vanilla Emacs config](https://github.com/kylerjohnston/dot-files/blob/ec3061b62d44a221bdb20a336b6da46430c352fd/emacs/.emacs.d/init.el), which probably grew out of that move. In the summer of 2019 I switched to [doom-emacs](https://github.com/hlissner/doom-emacs) and loved it &#x2014; most of the defaults were sane and I felt like it showed the power and extensibility of Emacs without overwhelming me by forcing me to do things its way, like Spacemacs did.

I decided to roll my own config again because I started having to fight Doom Emacs defaults to make things work the way I wanted, and with each update of Doom there'd be more changes I'd have to make to my `config.el` to keep my config working. Doom had introduced me to some new Emacs programs that I loved, like [Magit](https://magit.vc/) and [Ivy](https://github.com/abo-abo/swiper), but had a lot of features I didn't use. Doom, as a project, has to target everyone &#x2014; I just need a config that works for me.

This config is an active work in progress, and this web page is a living document of it. Eventually I'd like to set up a hook to export the web page whenever I push changes to `emacs.org`, but right now it is generated by manually running *C-c C-e P p* to export the project (see [Publishing](#orge466b98)), so it may not always be up to date.


<a id="orga52c0f8"></a>

# UI and basic configuration

Disable blinking cursors and scroll bars and tool bars and menus, show line numbers:

{% highlight emacs-lisp %}
(blink-cursor-mode 0)
(scroll-bar-mode 0)
(tool-bar-mode 0)
(tooltip-mode 0)
(menu-bar-mode 0)
(global-display-line-numbers-mode)
(global-hl-line-mode 1) ;; highlight current line
(add-to-list 'default-frame-alist
	     '(fullscreen . maximized)) ;; open new frames full screen
{% endhighlight %}

Stop cluttering working directories with back up files and save them to `/tmp/`. Everything is under version control anyway, right?

{% highlight emacs-lisp %}
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))
{% endhighlight %}


<a id="org4ff28bc"></a>

## Fonts

{% highlight emacs-lisp %}
(add-to-list 'default-frame-alist
	     '(font . "Source Code Pro Medium:pixelsize=15:foundry=ADBO:weight=normal:slant=normal:width=normal:spacing=100:scalable=true"))
{% endhighlight %}


<a id="orge56c7b5"></a>

## Doom Themes

{% highlight emacs-lisp %}
(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
	doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-tomorrow-night t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))
{% endhighlight %}


<a id="org84fe551"></a>

# Evil

{% highlight emacs-lisp %}
(use-package evil
  :config
  (evil-mode 1)
  (define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
  (define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line))
{% endhighlight %}


<a id="org6e3133d"></a>

# Org mode


<a id="org4a4167f"></a>

## Agenda

Org agenda files are saved `$HOME/org`.

{% highlight emacs-lisp %}
(setq-default org-agenda-files (quote ("~/org")))
(setq org-directory "~/org")
(global-set-key (kbd "C-c a") 'org-agenda)
{% endhighlight %}

Configure TODO keywords:

{% highlight emacs-lisp %}
(setq-default org-todo-keywords
	      '((sequence "TODO(t)" "IN PROGRESS(p)" "WAITING(w)" "|" "DONE(d)" "CLOSED(c)")))
(setq org-todo-keyword-faces
      '(("IN PROGRESS" warning bold)
	("WAITING" error bold)
	("CLOSED" org-done)))
{% endhighlight %}

Add a timestamp when you close a task:

{% highlight emacs-lisp %}
(setq-default org-log-done 'time)
{% endhighlight %}


<a id="org5a14183"></a>

## UI/UX

Soft-wrap lines, and don't do it mid-word.

{% highlight emacs-lisp %}
(setq-default org-startup-truncated nil)
(add-hook 'org-mode-hook #'visual-line-mode)
{% endhighlight %}

Use indentation, not extra \\\*s for headings.

{% highlight emacs-lisp %}
(setq-default org-startup-indented t)
{% endhighlight %}

Don't let org edit things under collapsed headings.

{% highlight emacs-lisp %}
(setq-default org-catch-invisible-edits 'smart)
{% endhighlight %}

Keybindings:

{% highlight emacs-lisp %}
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c C-l") 'org-insert-link)
{% endhighlight %}


<a id="orgb844467"></a>

## Babel

By default Babel will only allow you to execute `emacs-lisp` source code blocks. You can enable Babel to allow execution of code blocks in a bunch of different languages though &#x2014; a full list is here: <https://orgmode.org/manual/Languages.html#Languages>

{% highlight emacs-lisp %}
(setq org-src-tab-acts-natively t)
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   (ruby . t)
   (dot . t)))
{% endhighlight %}


<a id="orge466b98"></a>

## Publishing

This sets up Jekyll markdown export for my blog. See [this post on orgmode.org](https://orgmode.org/worg/org-tutorials/org-jekyll.html).

{% highlight emacs-lisp %}
(use-package ox-jekyll-md
  :ensure t
  :config
  (setq org-jekyll-md-use-todays-date nil)
  (setq org-jekyll-md-include-yaml-front-matter t))
(require 'ox)
(require 'ox-publish)
(setq org-publish-project-alist
      '(("muumuus"
	 :base-directory "~/muumuus/org/"
	 :publishing-directory "~/muumuus/_posts"
	 :base-extension "org"
	 :recursive t
	 :publishing-function org-jekyll-md-publish-to-md
	 :headline-levels 4
	 :with-toc nil ; don't export a table of contents
	 :section-numbers nil)
	("emacs"
	 :base-directory "~/.emacs.d/"
	 :publishing-directory "~/muumuus/_pages/"
	 :base-extension "org"
	 :recursive nil
	 :publishing-function org-jekyll-md-publish-to-md
	 :headline-levels 4
	 :with-toc t
	 :section-numbers nil)))
{% endhighlight %}


<a id="org03821a3"></a>

## Capture templates

{% highlight emacs-lisp %}
(global-set-key (kbd "C-c c") 'org-capture)
(setq org-capture-templates
      '(("b" "Blog" entry (file+headline "~/org/inbox.org" "Blog ideas")
	 "* TITLE\n#+TITLE:\n#+DATE: %t\n#+JEKYLL_TAGS:\n#+JEKYLL_LAYOUT: post\n\n%?")
	("d" "Divide and Conquer: Algorithms on Coursera"
	 entry (file+headline "~/org/inbox.org" "Divide and Conquer: Algorithms on Coursera")
	 "* %^{Title}\n#+DATE: %t\n\n%?")))
{% endhighlight %}


<a id="orga0e46d0"></a>

# Dired

Make it so if you have split windows, both with dired buffers, and you perform a rename or copy action on an item in one dired buffer, its default target is the other dired buffer.

{% highlight emacs-lisp %}
(setq dired-dwim-target t)
{% endhighlight %}

Evil keybindings:

{% highlight emacs-lisp %}
(evil-set-initial-state 'dired-mode 'normal)
{% endhighlight %}


<a id="org7cf23a8"></a>

# Company

{% highlight emacs-lisp %}
(use-package company
  :ensure t
  :init (add-hook 'after-init-hook 'global-company-mode)
  :bind
  (:map company-active-map
	("<return>" . nil)
	("C-<return>" . company-complete-selection))
  :config
  (setq company-idle-delay 0)
  (setq company-minimum-prefix-length 2)
  (setq company-auto-complete 'company-explicit-action-p))
{% endhighlight %}


<a id="org8f92288"></a>

# Languages


<a id="orga262c1d"></a>

## GraphViz

{% highlight emacs-lisp %}
(use-package graphviz-dot-mode
  :ensure t
  :config
  (setq graphviz-dot-indent-width 4))

(use-package company-graphviz-dot
  :ensure t)
{% endhighlight %}


<a id="org6d61f8c"></a>

## LaTeX

Recognize `.latex` files as&#x2026; LaTeX.

{% highlight emacs-lisp %}
(setq auto-mode-alist (cons '("\\.latex$" . latex-mode) auto-mode-alist))
{% endhighlight %}


<a id="orgd43d610"></a>

## Ruby

I had issues with syntax highlighting and identation breaking using `enh-ruby-mode`, so I'm back to just plain `ruby-mode`.

flymake-ruby for syntax checking.

{% highlight emacs-lisp %}
(use-package flymake-ruby
  :ensure t
  :hook (ruby-mode . flymake-ruby-load))
{% endhighlight %}

`inf-ruby` opens `irb` in a buffer.

{% highlight emacs-lisp %}
(use-package inf-ruby
  :ensure t)
{% endhighlight %}

`rubocop` is a linter.

{% highlight emacs-lisp %}
(use-package rubocop
  :ensure t
  :hook (ruby-mode . rubocop-mode))
{% endhighlight %}


<a id="org5aab32e"></a>

## SaltStack

{% highlight emacs-lisp %}
(use-package salt-mode
  :ensure t
  :config
  (add-hook 'salt-mode-hook
	    (lambda ()
	      (flyspell-mode 1))))
{% endhighlight %}


<a id="org0762c5e"></a>

## Terraform

{% highlight emacs-lisp %}
(use-package terraform-mode
  :ensure t)
{% endhighlight %}


<a id="org50db5a2"></a>

# Magit

{% highlight emacs-lisp %}
(use-package magit
  :bind ("C-x g" . magit-status)
  :ensure t)
(use-package evil-magit
  :ensure t)
(require 'evil-magit)
{% endhighlight %}


<a id="orgb920bc6"></a>

# Diminish

{% highlight emacs-lisp %}
(use-package diminish
  :ensure t)
{% endhighlight %}


<a id="orgfebc188"></a>

# Ivy/Counsel/Swiper

{% highlight emacs-lisp %}
(use-package counsel
  :ensure t
  :diminish ivy-mode
  :bind (("C-s" . swiper-isearch)
	 ("M-x" . counsel-M-x)
	 ("C-c k" . counsel-rg))
  :init
  (ivy-mode 1)
  (counsel-mode 1)
  :config
  (setq ivy-use-virtual-buffers t))
{% endhighlight %}


<a id="org410d691"></a>

# Start Emacs server

{% highlight emacs-lisp %}
(server-start)
{% endhighlight %}


<a id="orgf09d18f"></a>

# References

These are sources I've used to build my emacs configuration:

-   My old emacs config: <https://github.com/kylerjohnston/dot-files/blob/971496d42a1b7c65f28114442a5742a561b1e4f2/emacs/.emacs.d/init.el>
-   My doom config: <https://github.com/kylerjohnston/ansible/blob/186986a6aa58bfc14f55a69c34554605c3a7178d/roles/graphical/files/config.el>
-   <https://github.com/angrybacon/dotemacs/>
-   <https://github.com/hlissner/doom-emacs>