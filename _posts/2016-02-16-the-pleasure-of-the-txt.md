---
layout: post
title: "The pleasure of the txt"
date: 2016-02-16
categories: humanities writing
---

Microsoft Word is the de facto standard application for writing in the humanities. We write, collaborate, and disseminate our works in `.docx` format. There are lots of things to dislike about Word: its lack of portability, for one, or how it forces you to be tied into the Microsoft ecosystem, or how easily the formatting of an entire document can get messed up by dropping in a single figure or table. The biggest problem with Word, though, is that it just doesn’t match up with the way we write. Writing and typesetting are different, distinct parts of the writing process, but in Word they are combined into one task. As we write we must also always be formatting, thinking not just about our words but about how they will appear on the paper. We fiddle with fonts and line spacing and ligatures when we should be getting down words.

This is a really *weird* writing ecosystem. For years our colleagues on the opposite side of campus&mdash;the scientists and the engineers and the mathematicians&mdash;have been typesetting their papers using a free program called [LaTeX](https://en.wikipedia.org/wiki/LaTeX). LaTeX is a markup language---like HTML---that lets you write your papers in plain text files that you can edit with any text editor. Then, when you’re done writing, you can typeset document using any number of nice-looking templates that you can proofread and send off to review in any number of formats. This makes it really easy to quickly produce differently formatted versions of your paper: a version to turn into your seminar professor, a version to submit to journals, a version to post on your blog, whatever.

LaTeX is overkill for most of what we write in the humanities. LaTeX is great if you want to typset complex-looking mathematical equations---that’s why  STEM people love it---but its syntax is overly complex for the kinds of things we typically write in the humanities. Instead, we can draw on LaTeX's write first, format later model but write in the simpler [Markdown](https://daringfireball.net/projects/markdown/syntax) markup language. Even if you’ve never heard the term “Markdown,” you probably recognize its syntax from emails or internet message board posts: a word or phrase wrapped in `*single asterisks*` is *italicized*; `**double asterisks**` make text **bold**. You can find a more detailed guide to the syntax elsewhere, but realistically you probably won’t be using too much beyond what I just demonstrated in your humanities papers.

## How I write

For the rest of this post, I’m going to describe my particular set up for writing in the humanities. I write *everything* in Markdown---from seminar papers and syllabi to lesson plans, notes, and this blog post---and rely on the powerful [Pandoc](http://pandoc.org) utility to convert my Markdown files into formatted documents---mostly PDFs and HTML files.

### Prerequisites

I write on a mid-2012 Macbook Pro. My instructions below are specific to OS X, but all of the tools I mention are cross-platform and a similar set up could be configured on any system. You'll need the following things:

* **A plain text editor**. This can be something as simple as TextEdit on a Mac or Notepad on Windows. There are also, at least for OS X, several editors made specifically for editing markdown and targeted at writers, such as ByWord, iA Writer, and WriteRoom. If you don’t write code, these might be your best bets---I’ve had good results with ByWord in the past. More advanced options like Atom, Sublime Text, Emacs, and Vim will be more customizable and support advanced features like syntax highlighting and autocompletion.  I use Vim and MacVim because I've invested time learning to use them but you should feel free to try out several editors---Vim has a steep (but rewarding!) learning curve, and you should use whatever editor works best for you.

* **Pandoc**. [Pandoc](http://pandoc.org) is a utility that can convert Markdown documents to basically any other format you want. 

* **A LaTeX installation**. Pandoc needs a LaTeX installation to convert your files to PDFs. If you’re on OS X, [MacTeX](http://tug.org/mactex/) is what you want. The BasicTex package will suffice, but I’d recommend installing the [TeX Live Utility](http://amaxwell.github.io/tlutility/) too if you go that route (it’s included with the full MacTeX package). After installing your TeX package, open the TeX Live Utility and update all packages.

* **My MLA Pandoc templates**. Pandoc still isn’t that popular of a tool in the humanities. I couldn’t find any MLA templates for Pandoc, so I made my own. They rely on the [mla-paper](https://www.ctan.org/pkg/mla-paper) LaTeX package which comes with MacTeX. You can [download them from Github](https://github.com/kylerjohnston/pandoc-templates).

* **An MLA Citation Style Language file**. Pandoc uses this file to generate your citations. [Here's a link to the MLA 7th Edition CSL file from the Zotero Style Repository](https://www.zotero.org/styles/modern-language-association). Save this file to `~/.csl/modern-language-association.csl`. That's where Pandoc will look for it.

* **A citation manager**. Zotero, Mendeley, and EndNote seem to be the most popular. I use BibDesk---it comes with a full MacTeX install and it’s lightweight and easy to use.

### Putting it all together

Let’s imagine I’m writing a paper for an English graduate seminar. I start out by making a new directory for the project. 

    miltons-mistake/

I compile a bibliography for the project in BibTex and export it to the root of the project directory as a `.bib` file. You could also do this in Mendeley or Zotero.

    miltons-mistake/
        miltons-mistake.bib

I make a `drafts/` directory and put my master Markdown file in it.

    miltons-mistake/
        drafts/
            miltons-mistake.md
        miltons-mistake.bib

`miltons-mistake.md` looks like this:

{% highlight markdown %}
---
auth:
first: Kyle
last: Johnston
professor: Professor Smith
course: English 598
date: February 16, 2016
title: "Milton's Mistake"
bibliography: miltons-mistake.bib
csl: modern-language-association.csl
---

This is the body of your paper. You can cite stuff by referencing
the citation ID in your bib file, like so [@milton-Paradise 1.102].

New paragraphs are separated by a blank line.

At the end of your paper, type the following to generate a Works
Cited page from your bibliography using only sources you've cited in
the paper.

\workscited
{% endhighlight %}

The metadata at the beginning of the file gives the template the necessary info to set up your document and tells Pandoc where to find your bibliography and what citation style to use.

I compile my formatted documents to another subdirectory, `out/`. Open a terminal, change to the project's root directory, and run:

{:.bash}
    $ pandoc drafts/miltons-mistakes.md \
      -o out/miltons-mistakes-seminar-02-16-16.pdf \
      --latex-engine=xelatex \
      --template=mla \
      --filter pandoc-citeproc

The `-o out/miltons-mistake-seminar-02-16-16.pdf` flag tells Pandoc where to write the compiled document. `--latex-engine=xelatex` tells Pandoc to use XeLaTeX to compile the document. XeLaTeX ships with MacTeX---it has the advantage of being able to use your system fonts, something other LaTeX engines tend not to play nicely with. `--template=mla` tells Pandoc to use your MLA template. And finally `--filter pandoc-citeproc` will let Pandoc process your citations by passing them to its `pandoc-citeproc` tool.

Since this command is so long I usually save it to a build script that I can quickly run whenever I want to compile the document.

{% highlight bash %}
#!/bin/bash

pandoc drafts/miltons-mistakes.md \
    -o out/miltons-mistakes-seminar-02-16-16.pdf \
    --latex-engine=xelatex \
    --template=mla \
    --filter pandoc-citeproc
{% endhighlight %}

Save this in the project's root directory as `build.sh` and then you just run `$ ./build.sh` to compile your document.

That's it! The advantage of this approach is two-fold: you don't have to worry about formatting while you're writing, and once you have your document written it's simple to format it in any number of ways. I could export an MLA-style PDF for my professor, another PDF with a different citation style to submit to a journal, and an HTML file for my blog all from the same source document.
