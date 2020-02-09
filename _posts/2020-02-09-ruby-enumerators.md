---
title: "Ruby enumerators"
date: 2020-02-09
layout: post
categories: 
- ruby
tags: 
---
Enumerators are objects that yield things to a code block.

{% highlight ruby %}
  e = Enumerator.new do |y|
    [1, 2, 3].each do |x|
      y << x
    end
  end

  e.map { |x| x**2 }

#+RESULTS:
# | 1 | 4 | 9 |
{% endhighlight %}

The `y` is a "yielder," an instance of `Enumerator::Yielder`. The yielder is populated in the code block passed to the enumerator, and the enumerator looks to the yielder to determine what to return at any particular iteration of an `each` call.

{% highlight ruby %}
a = [1, 2, 3]
e = a.each
e.class

#+RESULTS:
# : Enumerator
{% endhighlight %}

You can create an enumerator from most iterator methods by withholding a code block.

{% highlight ruby %}
a = (1..10)
e = a.each
e.select { |x| x > 6 }

#+RESULTS:
# | 7 | 8 | 9 | 10 |
{% endhighlight %}

{% highlight ruby %}
a = (1..10)
e = a.map
return e, e.each { |x| x**2 }

#+RESULTS:
# : '(#<Enumerator: 1..10:map>  (1  4  9  16  25  36  49  64  81  100))
{% endhighlight %}

The enumerator retains whatever method it's created from &#x2014; here `e.each` is created from `a.map` and functions like `a.map`.

{% highlight ruby %}
def is_prime?(n)
  return 1 if n == 1
  (2..n/2).each do |x|
    return n if n % x == 0
  end
  return 'Prime'
end

def primes(n)
  (1..Float::INFINITY).lazy.map { |x| is_prime?(x) }.first(n)
end

primes(5)

#+RESULTS:
# | 1 | Prime | Prime | 4 | Prime |
{% endhighlight %}

You can even use an enumerator to do work on infinite sets by making it a "lazy" enumerator. Here I wrote a function to find primes in the first `n` positive natural numbers.
