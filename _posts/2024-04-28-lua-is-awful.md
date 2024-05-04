---
layout: post
title: "Lua Is an Awful Garbage Language (and why I use it anyway)"
date: 2024-04-28
excerpt: Why Lua is the worst and why I don't care
---

I have a weird relationship with the Lua scripting language.

The first game I ever finished was in High School in a game engine called [CraftStudio](https://sparklinlabs.itch.io/craftstudio), a defunct Unity-like game engine that used Lua. In a way, Lua was the first language I really learned.

After college, I made games in [löve2d](https://love2d.org) for 3 years. I moved away from writing Lua in löve in favor of writing C# in MonoGame. Now with my game engine project, [SokoMaker][sokomaker], I'm using Lua again for gameplay scripting and GUI templates.

During my löve2d era, I made [14 games](https://itch.io/c/3037667/made-with-love2d), many of them are game jam games made in a few days (or a few hours!).

Löve is a game **framework**, as opposed to a game **engine**, which means you have to build basically everything yourself. You get a window, a draw/update loop, and an easy API for drawing to the screen. That's it! The actual "engine" and "game" parts of the game are on you to make yourself, and you have to do it all in this goofy moon language called Lua.

I came across a reddit comment that summarizes my experience with löve2d. I've lost the original comment so I can't credit the original author, but it went something like this:

```
"I love löve! Löve makes Lua tolerable."
- author unknown
```

Since SokoMaker uses Lua for gameplay scripts, I've been nervous about onboarding people who have never written Lua before. When [Ursagames][ursagames] and I made [Summoners Incorporeal](http://notexplosive.net/summoners-incorporeal) for Ludum Dare a few weeks ago I warned him "Just so you know, Lua is a awful garbage language."

I feel like I made it to the other side as a Lua Understander :tm:, but I'm not sure I want other people to have to go through what I did.

I thought it would be helpful to articulate my thoughts on why Lua is an awful garbage language. My hope is that in reading this blog post you'll find this to be a Lua crash course by way of manic rant. If you want a _real_ Lua Crash Course to get a basic feel for the language, [I highly recommend this one](https://tylerneylon.com/a/learn-lua/).

## Why Lua is an Awful Garbage Language

### One-Indexed

Let's start with a soft-ball. Lua is one-indexed, meaning arrays start at 1 instead of 0.

I don't _hate_ this. I don't love it either.

This is often the first thing people mention when they talk about disliking Lua. But 1-indexing is not an inherently bad thing. It only feels strange because every other language made the opposite design choice. It made sense in C when an array index described an offset in memory. But at the high level that Lua is at, we think of arrays as a list of things, and the first thing on that list should be the *first* thing.

One-indexing makes it easier to talk about code verbally. In a one-indexed language, the "first" element of the array is the element at index `[1]`. The second is at index `[2]`. 

In a zero-indexed language, the _zeroth_ element is at `[0]` and the first-- sorry, _oneth_ (pronounced _wunth_) element is at `[1]`. 

If someone says "the fifth element of the array" in a zero-indexed array, which of the following are they referring to?
- `[5]` - the element at index 5, or
- `[4]` - the fifth element if you counted them.

As much as I will defend one-indexing, it does have some draw backs:

- Using modulo to wrap back around to the first index introduces an awkward `+ 1` that I always get wrong.
- For loops start at 1 if their iterating an array, but might start at 0 for non-array-related contexts.

One indexing is weird. But it's far from the most egregious thing about Lua.

### Anything can be a Key

Remember how I just said "arrays are one-indexed in Lua." Well, that's actually not true because there's no such thing as an array in Lua.

Lua only has 1 data structure. The almighty `table`! It's a Dictionary, List, Object, and Prototype all packed into one!

You can initialize a table like this:


```lua
local stats = {
    mana = 50,
    life = 200
}

print(stats["mana"]) -- output: 50
```

Which is the same as:

```lua
local stats = {}

stats["mana"] = 50
stats["life"] = 200

print(stats["mana"]) -- output: 50
```

If you want something that's more like an array, you can key into the table with integers, like so:

```lua
local fruit = {}

fruit[1] = "durian"
fruit[2] = "orange"
fruit[3] = "banana"

print(fruit[3]) -- output: "banana"
```

Or you can use the "array initialization" syntax, which gives you a one-indexed result.

```lua
local seasons = {
    "winter",
    "spring",
    "summer",
    "autumn"
}

print(seasons[2]) -- output: "spring"
```

If you really hate one-indexing, there's nothing stopping you from assigning to the `[0]` key like so:

```lua
local vegetables = {}

vegetables[0] = "carrot"
vegetables[1] = "potato"
vegetables[2] = "celery"
```

However other language features will ignore the zeroth element. The `#` operator gives you the "length" of your table. I have more to say about the length operator down below.

```lua
print(#seasons)    -- output: 4
print(#fruit)      -- output: 3
print(#vegetables) -- output: 2, because the 0th element was ignored.
```

The fact that you can assign to `[0]` is incidental because _anything_ can be a key.

```lua
local puzzle = {}

-- strings can be keys
puzzle["hello"] = "it's"

-- negative numbers can be keys
puzzle[-1] = "a"

-- non-integer numbers can be keys
puzzle[3.14] = "secret"

-- booleans can be keys
puzzle[false] = "to"

-- tables can be keys, even the table you're indexing into!
puzzle[puzzle] = "everybody"
```

When working with strings in particular there's an alternate syntax you can use:

```lua
local town = {}

town["west"] = "Clock Tower"
town.east = "Old Barn"

-- you can use the 2 syntaxes interchangeably
print(town.west) -- output: "Clock Tower"
print(town["east"]) -- output: "Old Barn"
```

Since you can index into a table using a string literal, you can do weird stuff like this:

```lua
local town = {}
town.east = "Old Barn"

local key = "ea"
key = key .."st" -- concatenate to strings together into "east"

print(town[key]) -- output: "Old Barn"
```

This means if I want to find all usages of `town.east`, it's not enough to CTRL+F for the pattern `town.east` or even `east`. There could be any number of places where we stitch the string "east" together at runtime. Instead you just need to sort of "know" all the places where you might use that key.

Suffice it to say, it's hard to refactor safely in Lua. You need to keep consistent mental models in your head about how the whole system works. If you want to do a big refactor, you need to do it all at once with extreme focus, otherwise you might forget something. This is the kind of mental burden you can entirely offload to the IDE in a language like C#.


### Sequences the Length Operator, and Undefined Behavior

I mentioned earlier that Lua only has one data structure, and therefore doesn't have a concept of "lists" or "arrays." This was another half-truth.

The Lua language spec says that if a table satisfies certain criteria, it is considered a "sequence" and therefore you can do certain things to it.

For a table to be a sequence it must have no gaps between 1 and any other non-nil positive integer index. Here's an example.

```lua
local animals = {}

-- an empty table is technically a sequence!

animals[3] = "Wolf"

-- animals is no longer a sequence, [1] and [2] are considered "gaps"

animals[1] = "Pony"
animals[2] = "Bear"

-- animals is a sequence again!

print(#animals) -- output: 3, the length operator does expected things to sequences

animals[4] = "Boar"

-- animals is still a sequence!

animals[2] = nil

-- we've introduced a gap, animals is no longer a sequence!
```

Technically, populating a key that is not a positive index (for example: a string, zero, or a negative number) does not disqualify a table from being a sequence.

```lua
local animals = {}

animals[0] = "Goat"
animals["a"] = "Newt"
animals[1.22] = "Hawk"

animals[1] = "Pony"
animals[2] = "Bear"
animals[3] = "Wolf"
animals[4] = "Boar"

-- animals is a sequence, but [0], [1.22] ["a"] are ignored.

print(#animals) -- output: 4, only [1] [2] [3] and [4] were counted
```

So to recap, if you define positive integer keys in the table, you cannot have gaps and expect the `#` operator to work. So what if you have gaps?

According to the Lua language standard, the `#` operator is _undefined_ when operating on a table that does not meet the sequence criteria.

```lua
-- WARNING: UNDEFINED BEHAVIOR
local animals = {}
animals[1] = "Pony"
animals[2] = "Bear"
animals[3] = "Wolf"
animals[4] = "Boar"
-- missing [5]
animals[6] = "Goat"

print(#animals) -- output: 6 ... sometimes
```

In my first draft of this blog post, I had a whole section about how "the length operator only works if there's a gap that is only 1 element long, if it's 2 elements long the length operator stops counting at the gap." But I was wrong, what I was describing was my observed experience in löve2d. [This stackoverflow answer](https://stackoverflow.com/a/23591039) gives a much clearer explanation about what makes a valid sequence.

Undefined behavior sucks. A language should do everything in its power to not let you run code that has undefined behavior, or give you an explicit keyword (eg: `unsafe`) so the programmer can opt-in for the potential of undefined behavior. This is the only undefined behavior I'm aware of in Lua, but it's so easy to stumble into this scenario.


### Nil by Default

What should happen if you reference a variable that hasn't been declared? 

In a compiled language the answer is obvious, the compiler catches this with static analysis and won't compile. Scripting languages have to be more creative.

Some variables might be global. Global variables in Lua can be defined at any time and place, so we don't know if something is a defined variable or not until we reach it at runtime. What should we do if we reach that variable and find that it's not defined?

A language like Python would throw an error. This is a reasonable way to handle this problem. It's annoying that your program comes to a screeching halt just because you made a typo. But at least it encourages you to define all your globals up front, preferably in one place.

Lua does not do this. In Lua, everything is `nil` by default! A `nil` (much like `null` or `None` in other languages) represents an empty value.

```lua
print(x) -- output: nil
```

If you index into a (non-nil) table, you'll get back a `nil` on anything that wasn't defined.

```lua
local animals = {}
animals[1] = "cat"
animals[2] = "dog"

print(animals[3]) -- output: nil
print(animals["snake?"]) -- output: nil
```

Made a typo? Here's a nil as a consolation prize!

```lua
print(aminals) -- output: nil
```

Forgot the `return` keyword? That's OK, all functions return nil by default.

```lua
local function add(x,y)
    x + y
end

print(add(2, 3)) -- output: nil
```

Forgot to add an argument to a function? We'll just assume any unfulfilled parameters are nil.

```lua
local function log(context, message)
    print(message)
end

log("Example") -- output: nil
```

On the surface, this might sound similar to throwing an error. After all, assigning something to nil unexpectedly often leads to a crash. The problem is the crash doesn't occur where the mistake was made, it generally occurs somewhere downstream when you try to do something with a nil.

```lua
local frog = {}

function frog.chomp(eater, food)
    eater.hunger = eater.hunger - food.size
end

local bug = buggyFunction() -- returns nil unexpectedly, this is the error!

frog.chomp(frog, bug) -- this crashes in `frog.chomp` when we try to do `food.size`
```

This is more of an indictment on the concept of `null` (or as Lua calls it `nil`). `null` is terrible, and doesn't really need to exist (something something monads). Lua leans _hard_ on `nil`.


### Global by Default


You may have noticed in my above examples that I've been using the `local` keyword a lot. This isn't strictly necessary, especially for toy examples on an internet blog. But I have the habit of using `local` in any context I can.

If you're declaring a variable, you have to prefix it with the `local` keyword. If you don't prefix the variable, it will assign to the nearest scoped variable with the same name. Usually, this means the global scope.

```lua
-- declare x as a global
x = 22

if something then
    -- declare a "different" x as a local, only visible in this scope
    local x = 5
    local z = false

    -- assigns to the local x
    x = 3

    -- declares a new global y
    y = "cat"

    print(x) -- output: 3
    print(z) -- output: false
end

print(x)     -- output: 22
print(y)     -- output: "cat"
print(z)     -- output: nil

```

It's easy to forget to use `local` and not notice. Say you have a large project and you find out that you have a global `i` floating around. Since there's no `global` keyword to search against, your only recourse is to search for every single usage of `i` until you find the one that's missing a `local` keyword.

Actually, there are other strategies you can use to find where that global came from but they're quite arcane and require using language features we haven't talked about yet (`_G`, metatables, etc.). So let's continue.


### Colon Syntax


Tables can hold functions and data, but if you call a function on a table, that function doesn't "know" what table it's being called from. So if the member functions purpose is to manipulate data on the table, you need to get creative.

A common pattern to solve this problem is to add the table as the first parameter to the function.

```lua
-- example 1A
person.saySomething(person, "Hello")
```

Where the definition might look like this:

```lua
-- example 1B
function person.saySomething(p, message)
    -- we assume "p" is the person that this function came from.
    if p.canSpeak then
        print(p.name .. ": " .. message)
    end
end
```

Lua sees this pattern and thinks "we can add some syntax sugar to clean that up!

```lua
-- example 2A
person:saySomething("Hello")
```

```lua
-- example 2B
function person:saySomething(message)
    -- we now have access to an invisible variable called "self"
    if self.canSpeak then
        print(self.name .. ": " .. message)
    end
end
```

Example `1A` and `2A` are identical, likewise, `1B` and `2B` are identical!

When calling a function with a colon, that means: "take the table to the left of the colon, and pass it into the function on the right of the colon as the first parameter."

```lua
player:play(video) 

-- gets converted to:
player["play"](player, video)
```

When declaring a function with a colon, that means: "insert an invisible parameter called `self` into this function declaration as the first parameter."

```lua
function player:play(video)
    -- ... do stuff with `self` and `video`
end

-- gets converted to:
function player.play(self, video)
    -- ... do stuff with `self` and `video`
end
```

In theory, this is great! It saves you a ton of typing if you use this pattern a lot. But there are a few problems.

In practice, you just have to sorta know "this function needs a colon" and "this function doesn't need a colon." You can develop a spidey sense for it: functions that behave like static functions use `.` and member functions use `:` but that's not necessarily true. You could have a dot function that uses some other mechanism (like closures) to capture the table data it wants to manipulate. Likewise, you could have a colon-defined function that doesn't actually use `self`.

You can use the two syntaxes interchangeably, you can declare a function with the `:` syntax and then call it with the `.` syntax and vise versa. 

Putting it all together, we can do some pretty wretched things:

```lua
local mathLib = {}

-- instead of typing `x` I just used a colon
function mathLib:add(y)
    return self + y
end

-- I'm calling it with the . syntax, the way it's intended to be called
print(mathLib.add(5, 2))    -- output: 7
```

Or the opposite:

```lua
local logger = {}

function logger.log(message)
    print(message)
end

-- an easy way to get the logger to print itself! That's clearly the desired behavior right?
logger:log()
```


This gives a whole new dimension to the term "off-by-one error." You might call a function with "2" parameters and get an error message about missing the _third_ argument, because you forgot to call it with a colon, adding the secret 3rd argument (sorry, _first_ argument). 

Actually, this often isn't an error. Instead it crashes because all the parameters are shifted over by 1, so whatever the function expected as parameter 2 is now parameter 1, and the last parameter is nil (thanks to nil-by-default). If the function definition accounts for these scenarios you might trip an `assert` that can give you a more helpful error message. But most likely you'll just get some cryptic message because _something_ went wrong in the function. Or worse: the function _doesn't crash_ and manages to run anyway, moving the bug downstream from the scene of the crime.


### Everything is Mutable

Literally everything in Lua is mutable. Even built in functions like `print` are one `=` away from being completely overwritten.

This makes Lua easy to sandbox because the host language can prefix any lua code with:

```lua
-- disable all the modules we don't want client languages to have access to
io = nil
loadfile = nil 
dofile = nil
-- and several more...
```

Here's a fun prank you can play on whoever you share your Lua codebase with.

```lua
local require_old = require

require = function(modName)
    -- 1/1000 chance that when you require a module, it'll just give you nil instead
    -- good luck debugging this ;)
    if math.random(1, 1000) == 1 then
        return nil
    end

    -- fallback to require's normal behavior
    return require_old(modName)
end
```

Because of Lua's aforementioned global rules, you can inject this terrible payload at any point in the codebase, even in the middle of a function! Your colleagues will have a hard time discovering the source of the problem because the nil reference exception only happens downstream.

This is one small cute example of why Lua script injection could be catastrophic. Can you believe people write server infrastructure in this language?!


### Metatables


Lua is not Object Oriented. But you can use metatables (pronounced _meta-tables_) to hack your own OOP into the language.

Metatables are probably the most confusing part of Lua. I didn't really fully understand metatables before writing this blog post. I'd use them sparingly, usually just copying code off of stackoverflow. Here's the simplest explanation I can give:

- A **metatable** is a table that describes the **configuration** of its constituent table. When a particular "event" happens to the constituent table, we will do something else specified by the metatable instead.
- You define this configuration by defining magic keys in the metatable called **metamethods**, which are always prefixed with two underscores (eg: `__index`, `__add`, `__call`)
- **Metamethods** are invoked when you do specific things to the table, usually involving an operator (eg: `+`, `/`, `[]`).
- Most metamethods don't have a default implementation.
- Some metamethods _do_ have a default implementation, defining the metamethod overwrites that behavior.
- Multiple tables can share a metatable. Or put another way, there can be multiple constituent tables for a given metatable.

```lua
-- this will be our constituent table
local real = {}

-- this will be an ordinary table
local fake = {}

-- this will be our metatable
local meta = {}

meta.__add = function(left, right)
    print("Tried to add " .. right)
    return "HELLO"
end

-- `real` now uses `meta` as its metatable.
setmetatable(real, meta)

local x = real + 1  -- output: "Tried to add 1"
print(x)            -- output "HELLO"

local y = fake + 1  -- crash! can't add a number to a table.
```

We can also override the `__index` operator, which changes what happens when you say `thing["index"]` (or the equivalent `thing.index`).

This is a common pattern involving the `__index` metamethod: "If I index into table with `a[key]`, and `a[key]` is `nil`, then check this backup table `b[key]` instead." 

Lua decided this is a common enough pattern that there should be a cryptic shorthand for it. If you set the `__index` metamethod to a **table** instead of a function, you get this fallback behavior.

```lua
local main = {}
local back = {}
local meta = {}

-- if the constituent table of this metatable doesn't have an index, check `back`
meta.__index = back

-- main is now using meta, this means it will fallback to `back`
setmetatable(main, meta)

back.x = 5
back.y = 23

main.y = 7

print(main.x) -- output: 5, `main` doesn't define `x`, but `back` does
print(main.y) -- output: 7, `main` defines `y`, so we use that, ignoring `back`
```

Metatables enable, to put it lightly, a ton of crazy shit.

You can daisy-chain this `__index` trick an get something that, if you squint hard enough, looks like inheritance!

This has a weird (but useful) interaction with colon syntax.

```lua
local PlayerClass = {}

function PlayerClass:play(video)
    -- does something involving `self` and `video`
end

local player = {}

-- `player` will fallback to `PlayerClass`.
setmetatable(player, { __index = PlayerClass })

player:play(video) 

-- gets converted to:
player["play"](player, video)

-- since `player["play"]` is nil, we instead do:
PlayerClass["play"](player, video)
```

Notice how we fallback on `PlayerClass` to find the `play` function, but we still pass in the `player` instance as the `self` parameter. This makes perfect sense if you have a clear understanding of _exactly_ what the colon syntax is doing. It's oddly elegant.

You can use this to cobble together your own special flavor of OOP. Complete with inheritance, constructors (thanks to the `__call` metamethod), and type deduction. All with your own custom syntax (barring Lua's handful of static syntax rules and operator precedence).

There's nothing stopping you from writing code like this:

```lua
if animal < Cat then -- type deduction... maybe?
    local weapon = Weapon() -- a constructor?
    local attacks = ATTACKS["claw"]["bite"] -- what
    return animal * equip(weapon) -- ????
end
```

We have achieved OOP with metatables! All we had to give up in exchange is any meaning in this language whatsoever. Even the most innocuous line of code could do anything, and could be defined anywhere.

Fortunately, Lua has some tools to help us make sense of a world mangled by metatables. For example we can use `getmetatable` to find something's underlying metatable.

```lua
local metatable = getmetatable(animal)
print(metatable) -- output: table: 001EE4C8
```

Printing the metatable doesn't give us much, but you can see what keys it has defined and slowly deduce what the metatable is and how it works.

Except, no. You can't rely on that. Because there's a metamethod to override the behavior of `getmetatable` for some reason.

```lua
local meta = {
    __metatable = "Haha, pranked!"

    -- these are now impossible to discover without finding the code they came from
    __index = secret1
    __mul = secret2
    __lt = secret3
}

setmetatable(animal, meta)
local meta2 = getmetatable(animal)

print(meta2)            -- output: "Haha, pranked!!"
print(meta == meta2)    -- output: false
```

In the above example, I have the metatable return a string that demeans the user for attempting to make sense of a senseless world. Instead I could have set the `__metatable` metamethod to another table, giving you a false sense of security in understanding what this table's underlying behavior is. Or I could have it return `nil`, implying "there's no metatable here" causing the user to rip their hair out.

This isn't just a foot-gun, this is actively malicious and hostile to people trying to make sense of your code.

By the way, if you want to learn more about metatables, there's this really great post from [the Roblox forums](https://devforum.roblox.com/t/all-you-need-to-know-about-metatables-and-metamethods/503259).

## Why I Use Lua Anyway


Would you be surprised to learn that Lua is my favorite scripting language?

I know I just spent the better part of this blog post completely eviscerating Lua. But there are some things that are genuinely great about it.

### Clean Syntax

Lua looks a lot like C, but it replaces curly brackets with english words and gets rid of all the semicolons.

```lua
if condition then
    statement()
    statement()
end
```

This expresses the exact same idea as the C-like language, just with fewer symbols floating around. I could see the case that this feels more cluttered in the long term because `then` is 4 times as wide as `{`. However I would argue that if you're reading code out loud you'd pronounce `{` as `then` anyway. The only thing I'm really not a fan of here is the word `end`. It feels awkward to have to type 3 keys just to end a block.

`for` loops in lua are also nice and simple. In C, a for loop has 3 sections and you although you can write whatever statement you want there, 99% of the for loops you'll ever write will look like one of these:

```c
// count from 0 to 10
for (int i = 0; i < 10; i++)
{
}

// or, twist! count down from 10!
for (int i = 10; i > 0; i--)
{
}

// or this thing because while(true) wasn't fancy enough
for (;;)
{
}
```

In Lua, we can express the exact same concept, but with way tighter syntax.

```lua
-- count from 0 to 10, doesn't get much simpler than this
for i = 0, 10 do

end

-- count down from 10
for i = 10, 0, -1 do

end

-- no ugly for loop syntax that I'm aware if :)
while true do

end
```

Lua also has iterator-based for loops.

```lua
for key, value in pairs(someTable) do
    -- does something for every key:value pair in the table
end
```

That's not terribly exciting, although it is a good way to traverse over an entire table. What is exciting is that `pairs` is just a function and we can slot in anything there (another powerful feature Lua just puts in our hands and assumes we won't abuse). Lua provides us another function we can call instead of `pairs` called `ipairs`, which only affects the sequence part of the table.

```lua
for index, value in ipairs(someTable) do
    -- does something for every index:value pair of the sequence part of the table.
end
```

### Metatables are Good Actually?

You might have gotten the impression from earlier that I hate metatables. But they're kind of awesome. A powerful foot-gun can be a jetpack if you angle it just right. With good conventions you can add some nice, ergonomic extensions to the language.

I gave a heinous example earlier, but let's look at what implementing OOP in Lua might look like if you're not actively trying to be terrible.

You could have class definitions that look like this:

```lua
-- Animal is a class
local Animal = Class()

function Animal:makeSound(sound)
    print(sound)
end

-- Dog is a "class" that extends `Animal`
local Dog = Class(Animal)

function Dog:bark()
    -- The dog's "bark" method 
    if not self.hasBarkedRecently then
        self.hasBarkedRecently = true;
        self:makeSound("Bark!")
    end
end
```

And constructors that look like this:

```lua
-- Create a new instance of `Dog` called `dog`
local dog = Dog()
dog:bark()
```

And even type deduction:

```lua
-- `type` is a thing I made up for this example
if someAnimal.type == Dog then
    print("this is a Dog")
end

if someAnimal.type < Dog then
    -- side note: I can't think of any language's type system that does this
    print("this inherits from Dog but is not itself a Dog")
end

if someAnimal.type <= Dog then
    print("this is a Dog or inherits from Dog")
end
```

The exact syntax may very. But that's the whole point. You can design the syntax to your taste. You have so much control over the language that you can essentially write your own custom language within it.


### Hackability


I mentioned earlier how you can use the hyper-mutability of Lua to get yourself into all sorts of trouble, but it can also be a useful tool.

I came across a löve2d project that had about 8 seconds of blank, unresponsive, white screen before the game started. Taking a peek at the code (which is easy to do in löve2d) I could see that the game was loading all of its graphics and sound resources into memory on startup before the first frame. Loading an image looks like this:

```lua
local image = love.graphics.newImage("guy.png")
```

My first step was to locate all of the places that we were loading images, and if we were loading any images multiple times. If you called `love.graphics.newImage("guy.png")` twice, you'd just have the same image again, and have wasted a ton of disk IO time.

So, I hacked over löve's API, overwriting what the `newImage` function does.

```lua
local loadedImages = {}
local realNewImage = love.graphics.newImage

love.graphics.newImage = function(imageName)
    print("Loaded " .. imageName)

    -- if we already have the image in cache, return it and print
    if loadedImages[imageName] then
        print(imageName .. " was already loaded!")
        return loadedImages[imageName]
    end

    -- load the image, cache it, and return it
    local image = realNewImage(imageName)
    loadedImages[imageName] = image
    return image
end
```

This had the immediate benefit of providing caching if we loaded the same image twice, it also gave me visibility on exactly when we were loading images. Playing through the game I could see that we were loading a ton of images upfront, but still had the occasional one-off where we loaded images on the fly. There was also one instance where we were loading the same image every frame. I migrated these cases into the front-loaded system the rest of the images were using.

Now that all the image loads were in the same place, I converted the front loaded for loop into something that built up a queue and then chewed through it a little bit at a time each frame. At this point I got rid of the `love.graphics.newImage` hack that I added. I didn't need (or want) to use it long term, but it was a great intermediate tool to fix the larger issue.

This was a really fun way to explore someone else's code. I felt like I just popped the game open and started tracing wires, moved some stuff around, and then stitched it back together. It's the closest I've ever felt to being a hacker in a movie.


### Simplicity

When I started learning Lua, I was reading about what the `or` keyword does. The official docs say:

> The operator `or` returns its first argument if it is not false [or nil]; otherwise, it returns its second argument.

At first this description feels cryptic. But the specifics of the behavior enable something powerful. In C#, the `||` operator is the "logical or" operator, it expects booleans in and booleans out.

```cs
// barring implicit casting or operator overloading, x will definitely be a boolean
// a and b must be booleans, or at least be able to implicitly cast to them
var x = a || b;
```

Whereas in Lua, we can express the same idea with much more freedom

```lua
-- x = a if a is not nil, otherwise x is b
local x = a or b
```

More usefully, I can express  "set `x` to this default value if it's unset, otherwise leave its value alone," in just one line!

```lua
x = x or 10
```

This is not unlike how logical operators work in other scripting languages, but it's easier in Lua because of its dead simple falseness rules. JavaScript, for instance, has you memorize the [falsy values](https://developer.mozilla.org/en-US/docs/Glossary/Falsy). Here's what that list looks like in Lua:

1. `false`
1. `nil`

That's it. All other values are truthy. Put another way, if a value is undefined (`nil`), explicitly deleted (assigned to `nil`), or explicitly set to `false`, it's falsy, in _any other context_ it is truthy.

Lua is full of simple, obvious rules like this. Even colon syntax always does the same thing in every context. Once you've learned a concept, you've learned the whole concept.


### It's Fun


Once you "get" Lua, it feels really good to write Lua.

Writing in Lua feels like moulding clay. You can squash it and stretch it to exactly the shape you want it to be with very little effort. If you want two things to be connected you can just pinch them together.

Meanwhile, writing C# feels like building with prefabricated pieces. If you want to connect two things you need to build a stable structure that connects the two. You'll sometimes have to spend time designing and building the exact part you need that's the exact right shape. You'll probably make something more structurally sound in C# in the long term, but it's way more fun to play with clay.

Since everything is global, nil and mutable, everything is within reach. If I need to declare a field on a class I can just start using it and... it exists now! If a class has some variable I need, I can just grab it!

Making games is an art, other art forms have a concept of quick freeform art. Like a visual artist doodling on a piece of paper or a musician playing around on a piano. Making video games is such a slow process that we don't really have an equivalent of a "quick doodle." However, wFriting Lua is the closest I've ever felt to doodling a video game.

### UserData


Everything we've talked about thus far has been about Lua as a language in isolation. If all you wrote was Lua, you'd be dealing with all of the problems I described above. But that's not how Lua is used. You don't write scripts in _just_ Lua like you would for Python or JavaScript. Lua is almost always embedded in another system, and that system passes in objects that allow you to interact with it.

When I said tables were the only data structure, that was yet another half truth. There's a whole other data structure specifically for things that come from the host language called UserData. UserData behaves much like a table (in fact, you can give a UserData a metatable!). But unlike a table you can't will fields into existence. You can't create UserData in Lua, it has to be created by the host language and then passed in.

This creates a clear dividing line between something that Lua "owns" and something that it's "borrowing" from the host language. If you're familiar with Unity, you've lived with an embedded language that doesn't have a concept of UserData.

Unity is a C++ program that embeds a C# runtime. Some of the objects you interact with in Unity C# are "regular C# objects," but many of them are actually facsimiles. There's an underlying C++ object somewhere in memory and this C# object is what your code is given to interact with that thing. Since C# and C++ have different rules about object allocation, Unity has to do a lot of weird stuff to ensure you don't interact with an Object after it's been deleted.

In Unity, it's not obvious where the "weird" Unity objects end and the "normal" C# objects begin. In Lua there is no ambiguity: Tables always belong to Lua, and will behave normally (as normal as Lua knows how to be). UserData always belongs to the host language and will be weird, and it's up to the platform that is embedding Lua (löve2d, Roblox, Garry's Mod, and one day, SokoMaker) to document that weirdness.


## Conclusion


Lua is a very comfortable language for me. I can keep the whole language in my head all at once, weird edge cases and all. There are lots of complex things that you can accomplish in Lua with very little code, and that feels very satisfying. 

That being said. It can be mentally exhausting to write Lua. The more code there is in a project, the more information you need to keep in your head at once. That's why I ultimately switched away from löve2d in favor of MonoGame. It takes longer to write something in C# than it does in Lua. However, C# has a type system that offloads the burden of remembering how the whole system fits together.

SokoMaker needed a GUI rework. Every single GUI screen was implemented in a different way and I hated all of them. Since I was already embedding Lua for gameplay scripts, I decided it would be fun to try using Lua for the GUI. It took about a day's work to write the new Lua GUI API (which I named Luigi). It then took another day's worth of work to redo 3 of SokoMaker's UI screens, and add 2 new ones.

Since the Lua GUI code is only run in the context of generating UI, I write code I wouldn't normally write. I even use global variables! This is totally safe because nothing is downstream of the Lua code. It spins up, it runs, hands what it generated back to C#, and then spins down.

This is the happy medium with Lua. Write the core "engine" code in a type safe language like C#, and then the "content" code in Lua. If Lua is sandboxed to a narrow domain, you can do all sorts of cursed things _safely_ and not worry about how it affects downstream systems. 

I think this is the intended way to use Lua, it's not meant to be a language that you build your whole world in. It's meant to be a satellite, a moon, that orbits around the core system and gently pulls on the surface.

[sokomaker]: {{ '/2024/02/14/introducing-sokomaker' | relative_url }}
[ursagames]: https://ursagames.itch.io/