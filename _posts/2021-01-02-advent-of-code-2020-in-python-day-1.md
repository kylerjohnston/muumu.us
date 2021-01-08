---
title: Advent of Code 2020 in Python, Day 1 
date: 2021-01-02
layout: post
excerpt: "I'm late to Advent of Code this year, but I thought I'd post my solution anyway. I can't say if I'll continue doing more of these (and posting them here) or not --- I'm well-rested and have the energy after a week of vacation tonight, but I return to work on Monday and may get busy with other things in life."
tags:
- python
---

I'm late to Advent of Code this year, but I thought I'd post my solution anyway.
I can't say if I'll continue doing more of these (and posting them here) or not
--- I'm well-rested and have the energy after a week of vacation tonight, but I
return to work on Monday and may get busy with other things in life.

The [prompt for day 1](https://adventofcode.com/2020/day/1 "Advent of Code
2020 - Day 1") asks you, in the first part, to find the two integers in the
input data that add to 2020, and multiply them together and return the product.

In my first solution, I wrote two functions. The first takes an integer `term`,
a list of integer `terms`, and a desired `total` and returns the first integer
from the list of terms that satisfies `term + x = total`.

```python
def find_addend_to_sum_to_num(term1, terms, total=2020):
    """
    Given a term (integer) and a list of terms, find the other term in the list
    of terms to satisfy:
    term + ____ = total
    Returns an integer
    """
    matches = [x for x in terms if total - x == term1]
    if len(matches) < 1:
        return None
    return matches[0]
```

A second function takes the list of all `terms` and a desired `total` as
arguments. It splits the `terms` into three lists: `lower` has all terms less
than half of `total`; `upper` has all terms greater than half of `total`; and
`half` has all terms that are half of `total`. I split it because any solution
for two terms will either involve one number less than half of the total and one
number greater than half of the total, or two numbers that are both exactly half
of the total. If there are two items in `half`, that's the solution. Otherwise,
loop through the terms that are less than half of the `total` and use
`find_addend_to_sum_to_num` to find a matching term from the `upper` terms.

```python
def find_terms_adding_to_num(terms, total=2020):
    """
    Given a list of `terms`, find the two that add to `total`
    Returns a tuple of integers
    """
    lower = [x for x in terms if x <= total / 2]
    upper = [x for x in terms if x > total / 2]
    half = [x for x in lower if x == total / 2]

    if len(half) >= 2:
        return (half[0], half[1])

    for term in lower:
        match = find_addend_to_sum_to_num(term, upper, total=2020)
        if match:
            return (term, match)

    return (None, None)
```

Part 2 is a variation on the theme, asking for three terms summing to 2020
instead of two.

At first I wrote another function to solve part 2 that works on a
similar principle to `finding_terms_adding_to_num`, except instead of looping
through all the lower terms it recursively loops through every term, since that
trick doesn't work if you're dividing it in more than two pieces, and then loops
through every other term in a `while` loop, checking for a matching third
term with `find_addend_to_sum_to_num`.

```python
def solve_part_2(terms, total=2020):
    term1 = terms.pop()
    working_terms = list(terms)
    while len(working_terms) > 0:
        term2 = working_terms.pop()
        if term1 + term2 < total:
            match = find_addend_to_sum_to_num(term1 + term2, working_terms,
                                              total=total)
            if match:
                return (term1, term2, match)

    return solve_part_2(terms, total=total)
```

These solutions worked, but I realized I could refactor the recursive solution
to part 2 to work for any number of terms and solve both parts with one
function.

```python
def find_terms_adding_to_x(terms, n=2, total=2020):
    """ Given a list of integer `terms`, find the `n` terms that add
    to `total`
    Return those `n` terms as a tuple of integers.
    """
    if len(terms) == 0:
        return []

    if n == 1:
        if total in terms:
            return [total]
        return []

    working_terms = list(terms)
    term1 = working_terms.pop()
    remaining_terms = list(working_terms)
    matches = find_terms_adding_to_x(remaining_terms,
                                     n=n - 1,
                                     total=total - term1)
    if matches:
        return [term1] + matches

    return find_terms_adding_to_x(working_terms, n=n, total=total)
```

This simplifies things significantly --- it can find any number of terms that
sum to some total, and it no longer needs the separate
`find_addends_to_sum_to_num` function. It works in basically the same way as the
`solve_part_2` function, except it replaces the `while` loop with pure
recursion.

This wrapper function calls it and returns the solution:

```python
def solve(terms, n=2, total=2020):
    """ Given a list of integer `terms`, find the `n` terms that add
    to `total` and return the product of those terms multiplied together """
    return reduce(mul, find_terms_adding_to_x(terms, n=n, total=total))
```
