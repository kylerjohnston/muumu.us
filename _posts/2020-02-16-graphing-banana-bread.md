---
title: "Graphing banana bread"
date: 2020-02-16
layout: post
categories: 
tags: 
- cooking 
- graphviz
---
I hate reading recipes. With most recipes I find myself re-reading the process over and over again as I'm making the thing because the steps aren't presented in a way that represents the actual process of cooking. Sometimes this is due to poor writing, but often it's just due to the nature of cooking. Cooking isn't a series of entirely sequential steps. There's typically a general sequence, but among the steps of that sequence are processes that can be done asynchronously &#x2014; the water has to be boiling and the vegetables chopped before you can start making your stew, but you can be chopping vegetables while the water is heating up.

Here is a recipe I use to make banana bread. I adapted it from the "Ultimate Banana Bread" recipe in [*The Cook's Illustrated Cookbook*](https://www.amazon.com/gp/product/1933615893/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1933615893&linkCode=as2&tag=muumuus-20&linkId=67155a99163cb1b505e8b871641a4570), ed. America's Test Kitchen (2011).


## Banana bread


### Ingredients

Dry:

-   1.75 cups flour
-   1 tsp baking soda
-   0.5 teaspoon salt

Wet:

-   5 frozen bananas
-   8 tablespoons unsalted butter, melted
-   2 large eggs
-   0.75 cups light brown sugar
-   1 tsp vanilla extract


### Procedure

1.  Heat oven to 350° Fahrenheit.
2.  Defrost 5 unpeeled bananas in a bowl using a microwave.
    1.  Once defrosted enough to peel, peel, squeezing the juices out of the peel and into the bowl, and microwave for 5 more minutes.
    2.  Drain bananas through fine-mesh strainer over a medium size pot. Allow to drain for 15 minutes.
        1.  Stir occasionally.
3.  Start melting butter on the stove.
4.  In between steps of the banana process, mix together all dry ingredients in a large bowl.
5.  Cook banana liquid on stove and reduce to about 0.25 cups, with a consistency similar to maple syrup.
6.  While reducing, mix the wet ingredients together &#x2014; bananas, mashed, and melted butter, eggs, brown sugar, and vanilla extract. Add banana liquid once reduced and mash everything together.
7.  Pour banana mixture into the dry ingredients and fold together gently.
8.  Grease loaf pan and pour banana mixture into it.
9.  Bake for 55-75 minutes, until toothpick stuck in the middle comes out clean.

I've edited the recipe to be a little more procedural, but it still doesn't feel like the best way to represent this information. Steps 1 &#x2013; 4, for example, should really all be done at the same time.


## A better way to visualize?

My first thought was to make a network diagram of the baking process where each node links to the things that depend on it. I knew [GraphViz](https://www.graphviz.org/) was a tool for making network diagrams, though I'd never played with it. This is the first graph I threw together:

{% highlight dot %}
digraph {
    "Heat oven" -> "Bake";
    "Defrost bananas" -> "Peel bananas";
    "Peel bananas" -> "Microwave bananas";
    "Microwave bananas" -> "Drain bananas";
    "Drain bananas" -> "Mix wet ingredients";
    "Drain bananas" -> "Reduce banana liquid";
    "Reduce banana liquid" -> "Mix wet ingredients";
    "Melt butter" -> "Mix wet ingredients";
    "Flour" -> "Mix dry ingredients";
    "Baking soda" -> "Mix dry ingredients";
    "Salt" -> "Mix dry ingredients";
    "Mix dry ingredients" -> "Mix batter";
    "Mix batter" -> "Assemble in pan";
    "Assemble in pan" -> "Bake";
    "Eggs" -> "Mix wet ingredients";
    "Brown sugar" -> "Mix wet ingredients";
    "Vanilla" -> "Mix wet ingredients";
    "Mix wet ingredients" -> "Mix batter";
}
{% endhighlight %}

![img](/img/banana-bread-graph.svg "Node-link diagram of the banana bread baking procedure.")

It's an interesting way to think about the recipe, but I don't think it solves the problem &#x2014; if I'm reading as I'm assembling everything, it looks like turning on the oven is one of the last things I need to do. Really, turning on the oven is one of the first things I need to do. 

I tried grouping nodes into subcategories to make things more clear.

{% highlight dot %}
digraph {
    subgraph cluster_bananas {
	label="Banana stuff";
	"Defrost bananas" -> "Peel bananas";
	"Peel bananas" -> "Microwave bananas";
	"Microwave bananas" -> "Drain bananas";
	"Drain bananas" -> "Reduce banana liquid";
    }

    subgraph cluster_wet {
	label="Wet ingredients";
	"Drain bananas" -> "Mix wet ingredients";
	"Reduce banana liquid" -> "Mix wet ingredients";
	"Melt butter" -> "Mix wet ingredients";
	"Eggs" -> "Mix wet ingredients";
	"Brown sugar" -> "Mix wet ingredients";
	"Vanilla" -> "Mix wet ingredients";
    }

    subgraph cluster_dry {
	label="Dry ingredients";
	"Flour" -> "Mix dry ingredients";
	"Baking soda" -> "Mix dry ingredients";
	"Salt" -> "Mix dry ingredients";
    }

    subgraph cluster_assembly {
	label="Assemble and bake";
	"Heat oven" -> "Bake";
	"Mix dry ingredients" -> "Mix batter";
	"Mix batter" -> "Assemble in pan";
	"Assemble in pan" -> "Bake";
	"Mix wet ingredients" -> "Mix batter";
    }
}
{% endhighlight %}

![img](/img/banana-bread-graph-with-subcategories.svg "Banana bread baking procedure node-link diagram, with subcategories.")

It's a little more clear than the first one, but the structure is still basically the same. It still doesn't visually represent the order in which things need to be done.

GraphViz lets you set certain nodes to be the same "rank." Maybe ranking together the tasks that need to be done first will help?

{% highlight dot %}
digraph {
    "Heat oven" -> "Bake";
    "Defrost bananas" -> "Peel bananas";
    "Peel bananas" -> "Microwave bananas";
    "Microwave bananas" -> "Drain bananas";
    "Drain bananas" -> "Mix wet ingredients";
    "Drain bananas" -> "Reduce banana liquid";
    "Reduce banana liquid" -> "Mix wet ingredients";
    "Melt butter" -> "Mix wet ingredients";
    "Flour" -> "Mix dry ingredients";
    "Baking soda" -> "Mix dry ingredients";
    "Salt" -> "Mix dry ingredients";
    "Mix dry ingredients" -> "Mix batter";
    "Mix batter" -> "Assemble in pan";
    "Assemble in pan" -> "Bake";
    "Eggs" -> "Mix wet ingredients";
    "Brown sugar" -> "Mix wet ingredients";
    "Vanilla" -> "Mix wet ingredients";
    "Mix wet ingredients" -> "Mix batter";
    { rank=same; "Heat oven", "Defrost bananas", "Melt butter", "Flour", "Baking soda", "Salt" }
}
{% endhighlight %}

![img](/img/banana-bread-graph-with-rank.svg "Banana bread baking procedure node-link diagram, with ranked nodes.")

This I actually like a lot, and think it would be a really helpful way to understand recipes. I don't think it's a substitute for a written procedural recipe, but I do think it would be a good reference to have while you're in the process of cooking, a map to check in and see "You are here." Not bad for an hour's reading on GraphViz!
