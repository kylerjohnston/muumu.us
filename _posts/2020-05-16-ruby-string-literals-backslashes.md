---
title: "Ruby string literals and backslashes"
date: 2020-05-16
layout: post
excerpt: "The past couple weeks I've been working my way through the 2015 Advent of Code problems to get more familiar with Ruby and practice applying, on a small scale, some of the OOP design patterns I've been reading in Sandi Metz's Practical Object-Oriented Design. I ran across an interesting issue on Day 8. Day 8 gives you a list of strings and a list of 'escape sequences'. Basically you need to count how many characters in each string are escape sequences."
tags: 
- ruby
---
The past couple weeks I've been working my way through the 2015 Advent of Code problems to get more familiar with Ruby and practice applying, on a small scale, some of the OOP design patterns I've been reading in Sandi Metz's *Practical Object-Oriented Design*. I ran across an interesting issue on [Day 8](https://adventofcode.com/2015/day/8). Day 8 gives you a list of strings and a list of &ldquo;escape sequences&rdquo; &#x2014; `\"`, `\\`, and `\x[0-9a-f]{2}`. Basically you need to count how many characters in each string are escape sequences.

The problem I ran into is that Ruby string literals &#x2014; even single-quoted strings &#x2014; interpret `\\` as an escaped `\`. This means Ruby sees the strings assigned the values `test\test` and `test\\test` as equivalent.

{% highlight ruby %}
irb(main):003:0> string1 = 'test\test'
=> "test\\test"
irb(main):004:0> string2 = 'test\\test'
=> "test\\test"
irb(main):005:0> string1 == string2
=> true
irb(main):006:0> string1.size
=> 9
irb(main):007:0> string2.size
=> 9
irb(main):008:0> string1.bytes
=> [116, 101, 115, 116, 92, 116, 101, 115, 116]
irb(main):009:0> string2.bytes
=> [116, 101, 115, 116, 92, 116, 101, 115, 116]
{% endhighlight %}

This also means you can't even search strings for `\\` because it's already escaped &#x2014; the string, to Ruby, only has one `\`.

{% highlight ruby %}
irb(main):032:0> string = 'test\\test'
=> "test\\test"
irb(main):033:0> '\\\\'.match?(string)
=> false
irb(main):034:0> /\\\\/.match?(string)
=> false
{% endhighlight %}

I [solved the AoC problem](https://github.com/kylerjohnston/advent-of-code-2015/tree/master/8) by reading in the strings from the puzzle input character by character into arrays, rather than into strings.

That worked for the AoC problem, but this got me thinking about problems this could cause in other situations &#x2014; what if I had a form getting user input that might contain backslashes, where it would be important to know exactly what input was given?

It looks like this might not actually be an issue though &#x2014; it turns out that Ruby only escapes `\\` in a string literal if you create it. If you are reading the string in from a file or STDIN it preserves the **literal** string (by escaping it for you!).

{% highlight ruby %}
irb(main):001:0> string1 = gets.chomp
test\test
=> "test\\test"
irb(main):002:0> string2 = gets.chomp
test\\test
=> "test\\\\test"
irb(main):003:0> string1 == string2
=> false
irb(main):004:0> File.open('backslash-test.txt', 'r') do |f|
irb(main):005:1* f.each do |line|
irb(main):006:2* puts line
irb(main):007:2> end
irb(main):008:1> end
test\test
test\\test
=> #<File:backslash-test.txt (closed)>
{% endhighlight %}
