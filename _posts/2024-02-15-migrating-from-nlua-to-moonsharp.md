---
layout: post
title: "SokoMaker Development Log: Why I switched from NLua to MoonSharp"
date: 2024-02-15
excerpt: My journey converting SokoMaker's Lua backend from NLua to MoonSharp
---

I've been working on an exciting problem in the last few weeks and wanted to talk about it.

A core part of SokoMaker's customizability is Lua scripting. As such, The SokoWestern Game has a lot of gameplay behavior implemented in lua. I decided that the more stuff I push over to the Lua side of the fence the better because it means the engine code can be leaner, and the mods can be more sophisticated.

However, pushing more behavior over to Lua has one big consequence: performance.

Generally, I only do real "work" in the lua runtime when the user presses a button. This fires an `onInput` event. This (usually) moves the player character which triggers an `onMove` event and that's likely to trigger a `worldUpdate`. That accounts for basically all of the game logic.

In watching the game's framerate I found that whenever I pressed a button the framerate would dip on that frame. My eyes couldn't see it unless I was watching the framerate counter. But it didn't feel good to know it was there.

I contemplated having the `worldUpdate` fire every frame instead of at arbitrary moments in gameplay, but that tanked the framerate to the low 40s. No good! Especially not for a 2D pixel art game! I knew Lua was slow, but I came from [LÖVE](https://love2d.org/), it's not supposed to be _that_ slow! Granted, LÖVE uses the much faster Lua JIT, so maybe this is how fast "real" lua is.

## The Leak
With this performance issue sitting in the back of my mind, I noticed another problem. If I leave SokoMaker running for long sessions (which I do a lot these days thanks to .NET 6 Hot Reload), the app slowly balloons in memory usage at a pretty alarming rate. On the order of 3MB per second. My 16GB machine running JetBrains Rider at least 3 Chromium-based products can't handle that for any reasonable amount of time.

After doing some experimenting I found that I only leaked memory some of the time. In fact, I could pan the camera around and find that some viewport positions would leak memory and others would not. Here's an example of a place that would leak memory.

![Alt](/assets/images/sokomaker.voidlab.png "A screenshot of a SokoMaker level from the editor view, featuring hooks, water, a bottle, and a blue circle.")

I don't expect you to understand what you're looking at so let me help you out. In this picture there are:
- 4 "hook" entities
- 1 "bottle" entity
- 2 "blank" entities
    - 1 with properties that turn it into a spawner, (that's the white square with the question mark)
    - 1 with properties that turn it into the "objective" that teleports you into the next room. It uses a special renderer to show up as a blue circle.
- 1 "blank" entity 
- Some "water" tiles, a "pit" tile, and a lot of "void" tiles.

## Digression, a bit about Renderers
There are 2 main ways to render an object in SokoMaker.
1. Setting the `renderer` key to one of the pre-build renderer types. That renderer will then use other variables in the object's `state` table to determine how to draw.

    For example if `renderer` is set to `"SingleFrame"`, the renderer will read the `sheet` key to figure out what sprite sheet to use, and then the `frame` key to figure out what frame on that sprite sheet to draw, and then it will draw that frame. If the `frame` or `sheet` change at any time, we'll draw the new thing instead.

    These are implemented in C# and are kind of opaque to the end user. But I implemented a few basic versatile renderers that (providing they're well documented) should be all you need 80% of the time. But sometimes you want a bit more customization. Which brings us to...
2. If you set the `renderer` to `lua:` followed by the name of a lua script implemented in the `renderers` folder, we'll render the object using that script. For example if I set the `renderer` to `lua:circle`, we will run the code in `renderers/circle.lua` to decide what to draw (assuming it exists).

    These scripts follow the same general set of rules as regular renderers. They can read state and figure out what to draw based on that. In principle these are great! It means you can draw highly flexible graphics such as Ernesto's whip (shown below)

![Alt](/assets/images/sokomaker.ernesto-whip.png "A screenshot of a SokoMaker level in play mode, the player character,is using his Lasso to hook onto a glass bottle. There is a brown line connecting his hand to the lasso, with a black outline around it.")

Lua Renderers also allows us to draw things that the custom renderers didn't think of. Like maybe I just want to draw a dynamically rendered circle with a radius that that can be set through the `state` table. Sure I _could_ have written that as a C# renderer, but what if you want a triangle? or a square? or a polygon? This is why I think it's better to have a very extensible system rather than a closed system that tries to anticipate every need.

## The Leak (part 2)

I found that whenever a lua-backed renderer was on screen, we'd start to leak memory at an alarming rate. This was because I cull out renderers that are off screen, skipping their code entirely. This is a great lead! Something in the lua renderer code is leaking memory!

After [some investigating]({% link _posts/2024-02-15-cool-trick-for-memory-leaks-in-csharp.md %}), I found that the leak was coming from an object that was being passed to the LuaRenderer. In the interest of not getting too in the weeds about it, I'll just leave it at that.

After about a day and half of investigation I found that the lue backend I was using, [NLua](https://github.com/NLua/NLua) was the culprit. Essentially, I passed the object to the lua runtime and then (with code commented out) did _nothing with it_ and yet NLua would hold onto a reference to the object and refuse to let it get garbage collected. I later found out that I could run `collectgarbage()` from Lua and it would let go of the objects. But this was already the last straw.

NLua had to go.

## Shopping for Alternatives

Frankly. I didn't spend very long looking for alternatives. You see, I recently moved to a new area and I've been trying to connect with the local gamedev community. In doing so, I've found a few discord communities of local gamedevs. One of which has a weekly voice chat hangout that I had just started attending.

Whilst stewing on the problem of NLua and this discovered memory leak, I peeked over at discord and saw some folks coworking in the voice channel and my timing could not have been better. Within seconds of entering I overheard the words "Lua" and "C#" so I asked if they were talking about Lua integration with C#, they said they were. I asked them what they were using and they suggested MoonSharp.

The two of them were working on a project in Godot, using C# with lua integration. However they were much more diligent in tackling the problem. Instead of just grabbing the first tool they saw and running with it. They shopped around and profiled the various options and found that MoonSharp was the fastest, especially over NLua.

I was instantly sold. During this call I started the process of deleting NLua from my NuGet packages and importing MoonSharp. Fixing the hundreds of errors (both compiler and runtime) this caused.

## Customizability over Anticipating Every Need

Much like my philosophy with SokoMaker, the MoonSharp developers would rather give you an OK out-of-the-box experience that you can customize in detail rather than give you a 80% perfect out-of-the-box experience and 20% that you spend the rest of your career fighting.

That said, MoonSharp's out of the box experience is pretty great. There's some really smart design choices baked in. One thing I really like is the concept of a `DynValue`, which is a wrapper that represents anything that came from Lua. You can ask it questions like "are you a number?" or "are a tuple of things?" This is an incredibly useful tool for a typed language wrapping around an untyped language. NLua's answer to the same problem is to give you back an `object` or an `object[]` and then you have to cast it to the thing you want.

One thing that rubbed me the wrong way. Say I have a class that has some functionality I want to expose to Lua. Here's how you'd do that in NLua.

```cs
public class MyClass
{
    [LuaMember(Name = "myMethod")] // <-- Provided by NLua
    public void MyMethod()
    {
        // do thing
    }
}
```

Easy! If we pass `MyClass` to a Lua function, we can call `:myMethod()` on it. This has the added benefit that if I happen to rename `MyMethod` in C#, the Lua name doesn't move. This is very similar to `[Newtonsoft.Json.JsonProperty]`, if you're familiar with that.

Here's the same thing in MoonSharp

```cs
[MoonSharpUserData] // <-- Provided by MoonSharp
public class MyClass
{
    public void MyMethod()
    {
        // do thing
    }
}

// you then need to do an extra step where you import the assembly
// to actually pick up this attribute.
```

This is... a tradeoff. And one I'm not particularly fond of. On the one hand
- :green_circle: I just put one attribute at the top of the class and I'm done!
- :large_orange_diamond: No duplication of `MyMethod()` -> `myMethod()` conversion happens for me.
- :large_orange_diamond: You can call the method from lua as `:myMethod()` or `.myMethod()` or `:myMethod()` or `.myMethod()` ... whether you like it or not.
- :red_square: If I rename MyMethod in C#, that change also must be reflected in Lua.

Mixed bag, but not a total deal breaker. I could just imagine myself writing documentation for SokoMaker saying "you can call these API functions in any of these 4 ways because of this special behavior I can't turn off."

It just felt so strange to me that MoonSharp didn't have a feature that allowed you to alias a member under a specific name. This felt like such an obvious feature it was weird that it wasn't built-in.

It turns out, there is a way to do this. You can write your own type importer and make very specific and deliberate decisions about how each member is imported. The docs didn't really go into detail, but one of the perks of open source is you can just copy how the built-in implementation works and then change it to fit your requirements.

After writing my custom importer, it looks more like this:

```cs
// no [MoonSharpUserData] required!
public class MyClass
{
    [LuaMember("myMethod")] // <-- i made this :)
    public void MyMethod()
    {
        // do thing
    }
}

// You still need an extra step to import the assembly, I wrote that step too!
```

It looks a lot like NLua, except for you don't need to specify `Name = ` which I always found really annoying.

At some point I might open source my MoonSharp wrapper so you can see what I did in detail. But it's tied in with the rest of SokoMaker at the moment and I don't want to open source that.

## Dust Settled

I want SokoMaker to be easily extensible. I want to see people making crazy shit in SokoMaker that I wouldn't have thought possible. For that to work, it needs a strong scripting backbone. NLua was just not cutting it.


![Alt](/assets/images/sokomaker.circles.png "A screenshot of a SokoMaker level in play mode, Ernesto stands in a screen filled with blue circles arranged in a tiling formation. A few of the circles are different colors")

This screen was my worst nightmare with NLua. This would tank the framerate into the low 30s, just from these circles like... existing. That's even after fixing the memory leak. I was questioning if I should even support lua-based renderers when I found this out.

I'm pleased to report that with MoonSharp, this screen runs at 60 frames per second. It _also_ doesn't leak any memory!