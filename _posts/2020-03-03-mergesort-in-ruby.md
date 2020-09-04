---
title: "Implementing mergesort in Ruby"
date: 2020-03-06
layout: post
excerpt: "Here is an implementation of mergesort I wrote in Ruby. I'll break it down in the rest of this post."
tags: 
- ruby 
- algorithms
---
*NB* I&rsquo;ve been a mostly self-taught programmer since I was in middle school (about 20 years now). I&rsquo;m in the processing of teaching myself some of the things I missed out on by not having a Computer Science education; I&rsquo;m also new to Ruby. This post is me writing out my thoughts on this subject to better understand it for myself &#x2014; maybe someone else will find it useful, but don&rsquo;t mistake me for an expert.

Mergesort is a classic &ldquo;divide and conquer&rdquo; algorithm for sorting an array. We have a problem like this:

-   **Input:** An unsorted array of numbers, e.g. `[1, 4, 3, 9]`.
-   **Output:** The input array, sorted from least to greatest, e.g. `[1, 3, 4, 9]`.

Mergesort works by splitting the input array into progressively smaller sorted arrays and then merging those sorted arrays together to produce the final sorted array.

Here is an implementation of mergesort I wrote in Ruby. I&rsquo;ll break it down in the rest of this post.

{% highlight ruby %}
def mergesort(array)
  return array if array.size <= 1

  left = mergesort(array[0...array.length / 2])
  right = mergesort(array[array.length / 2..])
  merge(left, right)
end

def merge(left, right)
  sorted = []

  until left.empty? && right.empty? do
    if left[0].nil?
      sorted.push(right.shift) unless right[0].nil?
    elsif right[0].nil?
      sorted.push(left.shift)
    elsif left[0] <= right[0]
      sorted.push(left.shift)
    else
      sorted.push(right.shift)
    end
  end

  sorted
end
{% endhighlight %}

Mergesort is split into two functions: a function `mergesort` which splits the array into smaller pieces and calls the `merge` function on those smaller pieces, and another function, the `merge` function, which combines two already-sorted arrays into a single sorted array.

Let&rsquo;s look at the `merge` function first.

{% highlight ruby %}
def merge(left, right)
  sorted = []

  until left.empty? && right.empty? do
    if left[0].nil?
      sorted.push(right.shift) unless right[0].nil?
    elsif right[0].nil?
      sorted.push(left.shift)
    elsif left[0] <= right[0]
      sorted.push(left.shift)
    else
      sorted.push(right.shift)
    end
  end

  sorted
end
{% endhighlight %}

The merge function takes two arrays, `left` and `right`, as parameters. It goes through each array element by element comparing them &#x2014; if the `left` array&rsquo;s element is smaller, it takes that element from the `left` array and adds it to a new `sorted` array; then it compares the next `left` element with the same `right` element. It does this until both `left` and `right` arrays are empty, then returns the `sorted` array.

If I pass `merge([9], [1])` it returns `[1, 9]`.

Passing `merge([0, 2], [1, 3])` returns `[0, 1, 2, 3]`.

Passing `merge([9, 1], [2, 3])`, though, returns `[2, 3, 9, 1]` because `merge` isn&rsquo;t a sorting algorithm on its own &#x2014; it just merges together two already-sorted arrays. We need to pass `merge` already-sorted arrays in order for it to work.

The function `mergesort` does that by splitting the input array into successively smaller arrays, splitting the input array in half and recursively calling itself on the two halves until it reaches two arrays of size 1<sup><a id="fnr.1" class="footref" href="#fn.1">1</a></sup>. Once it has two arrays of size 1, it calls `merge` on those two arrays and starts building up a single sorted array out of progressively larger sorted array inputs.

Adding some output to the program shows what&rsquo;s going on a little more clearly.

{% highlight ruby %}
def mergesort(array)
  return array if array.size <= 1
  puts "Splitting #{array} in two"
  left = mergesort(array[0...array.length / 2])
  right = mergesort(array[array.length / 2..])
  print "Merging #{left} and #{right} "
  merged = merge(left, right)
  puts "into #{merged}"
  merged
end

def merge(left, right)
  sorted = []
  until left.empty? && right.empty? do
    if left[0].nil?
      sorted.push(right.shift) unless right[0].nil?
    elsif right[0].nil?
      sorted.push(left.shift)
    elsif left[0] <= right[0]
      sorted.push(left.shift)
    else
      sorted.push(right.shift)
    end
  end
  sorted
end

unsorted_array = Array.new(4)
unsorted_array.map! { |x| x = rand(-100..100) }
puts "The unsorted array: #{unsorted_array}"
puts "The sorted array: #{mergesort(unsorted_array)}"
{% endhighlight %}

Running that outputs:

{% highlight nil %}
The unsorted array: [-75, 43, -70, -41]
Splitting [-75, 43, -70, -41] in two
Splitting [-75, 43] in two
Merging [-75] and [43] into [-75, 43]
Splitting [-70, -41] in two
Merging [-70] and [-41] into [-70, -41]
Merging [-75, 43] and [-70, -41] into [-75, -70, -41, 43]
The sorted array: [-75, -70, -41, 43]
{% endhighlight %}

You could visualize it like this:

![img](/img/mergesort-graph.svg "Mergesort algorithm graphed")

I hope that makes things clear! I think I will save analyzing the runtime complexity<sup><a id="fnr.2" class="footref" href="#fn.2">2</a></sup> or discussions of when to use mergesort versus other sorting algorithms as exercises for the reader,  or maybe future blog posts.

# Footnotes

<sup><a id="fn.1" href="#fnr.1">1</a></sup> Assuming an initial input array of size 2 or more &#x2014; otherwise it would just return its input.

<sup><a id="fn.2" href="#fnr.2">2</a></sup> The diagram above would be a good starting point.
