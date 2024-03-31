---
layout: post
title: "A Cool Trick To Deduce Memory Leaks in C#"
date: 2024-02-15
excerpt: A cool trick I found
---

This is a quick technical post that's mostly an addendum to my SokoMaker post about NLua to MoonSharp.

I was dealing with a memory leak. Which in C# generally means that some object somewhere is getting allocated but never garbage collected. An important piece of that puzzle is "what object is it?"

JetBrains Rider has tools to figure this out, but I couldn't seem to get a useful answer out of them. Maybe I just don't understand the tools. Maybe they need to write better documentation for how to use them :shrug:.

## How to count instances of a particular object

My key question I wanted to ask was "How many of `SomeObject` do I have in this moment." I want to be able to ask that questions 100s of times during a session and see if that number is trending up. I had a few classes that I was suspicious of. So I only needed tracking on a few of them.

This brings me to: The Canary.

The Canary is a class I can attach to any class, and I can use it to count how many instances there are of that object with reasonably high confidence.

The Canary class is very simple, it looks like this:

```cs
public class Canary
{
    private readonly string _name;

    public Canary(string name)
    {
        _name = name;
        Canary.InstanceCounts.TryAdd(name, 0);
        Canary.InstanceCounts[name]++;
    }

    private static Dictionary<string, int> InstanceCounts { get; } = new();

    ~Canary()
    {
        Canary.InstanceCounts[_name]--;
    }

    public static void PrintStatus()
    {
        foreach (var pair in Canary.InstanceCounts)
        {
            Console.WriteLine($"{pair.Key}: {pair.Value}");
        }
    }
}
```

I then put the following code at the top of my main `Update` function. Which just runs `Canary.PrintStatus()` every 0.25 seconds.

```cs
var time = DateTime.Now - _lastCheckTime;
if (time.TotalSeconds > 0.25)
{
    // We only run this part every 0.25 seconds to avoid spamming the console
    _lastCheckTime = DateTime.Now;
    Canary.PrintStatus();
}
```

Then, I added canaries to the classes I was interested in tracking.

```cs
public class SomeObject
{
    // This is all you need to do!
    private readonly Canary _canary = new(nameof(SomeObject));

    /* 
    
    the rest of MyObject's code... 
    
    */
}
```

Now, when I run the game, I get logging that looks like:

```
SomeObject: 35
SomeObject: 38
SomeObject: 24
SomeObject: 37
```

Looks stable, guess this isn't our guy. No worries, I can easily put Canaries on more things! Say we have a class `Person` and a class `Worker` that derives from it. In that case, I might name the canaries something helpful.

```cs
public class Person
{
    private readonly Canary _canary = new("Person.Base");

    /*

    ... code ...

    */
}

public class Worker : Person
{
    private readonly Canary _canary = new("Person.Worker");

    /*

    ... code ...

    */
}
```

With the above code, we'll get duplicate counts for `Worker` and `Person`. But knowing that, we can change the `_name` of the Canary to make the output more friendly.

Now we get something like:

```
SomeObject: 35
Person.Base: 102
Person.Worker: 503
SomeObject: 38
Person.Base: 152
Person.Worker: 553
SomeObject: 24
Person.Base: 192
Person.Worker: 593
SomeObject: 37
Person.Base: 212
Person.Worker: 613
```

You'd need a lot more output than this to really see a trend, but I'm truncating for brevity. You can pretty-up this output and maybe even serialize it and load it into some data visualization (kinda overkill, but sure would look cool).

If we just leave this running we should eventually see a pattern. One of these numbers should be trending upwards. If not, we need to add more Canaries. 

In this case we can see a pattern emerging: `Person.Base` is increasing and so is `Person.Worker`. Although `Person.Worker`'s increasing might just be a side effect of `Person.Base` increasing. What's actually happening is that `Person.Worker` is staying relatively static (at 401 instances). But we keep collecting new `Person.Base` instances.

So we've found the source of our problem, somewhere we're calling `new Person()` and that instance isn't getting garbage collected!

Previously all we knew is that we were leaking memory somewhere. Now we know what specific object is leaky (or, at least one of them) and can take steps to diagnose it. This was a very helpful strategy for me so I thought I'd share it!