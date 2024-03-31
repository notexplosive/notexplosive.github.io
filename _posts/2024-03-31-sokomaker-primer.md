---
layout: post
title: "SokoMaker Core Concepts"
date: 2024-03-31
excerpt: Basic concepts about how SokoMaker works.
---

I wanted to take some time to explain some basic concepts about how SokoMaker works, and my design philosophy around it.

:warning: This is out of date! SokoMaker's APIs change frequently (especially at time of writing, pre-early access). Take away the conceptual ideas and concepts instead of the exact keywords and syntax.

## Traits and `onMove`

At it's core, SokoMaker is a tool for making Sokoban games. Basically everything else is "fluff" around that very simple core.

As such, in your `mod.json` at the root of your game, you can define an enumeration of `Traits`. You, the content creator can decide what the traits are and what they mean. You might have a `Phase` trait with values like `Solid` `Liquid` and `Gas`. And/or you might have a `Material` trait with `Metallic` `Plastic` and `Wooden`.

Every entity and tile in your game is then defined by what its traits are. For instance, a "Crate" might be a `Heavy` `Wood` `Solid` `Buoyant` `Brittle` entity.

What do these values mean? Whatever you want them to mean.

In your `main.lua` you can define a function called `onMove` that will be automatically called every time an entity attempts to move. Your implementation of `onMove` can compare the Traits of the moving object to the Traits at the desired landing site.

## Config Variables, Instance Variables, and `State`

Traits only get you so far. Sometimes you want to store actual variables inside an object instance.

Every object in SokoMaker holds a table in it called `state`. The `state` holds all of the ephemeral information about the object that isn't native to that object type. This is where instructions for rendering the object are dispatched, and it's also where unique flags and behaviors might be defined.

`state` is a concept that only exists in lua at runtime. It's obtained by first gathering up all the Config Variables, then appending (or overwriting) them with Instance Variables, and then finally converting them into the `state` table realized in game.

That probably didn't make much sense, so let's break that down.

### Config (Config Variables)
Every type of object has a configuration file defined in Json. I call these "Configs." A Config for a "crate" might look like this:

```jsonc
// entities/crate.json
"config_variables": [
    {
      "data": {
        "key": "renderer",
        "value": "SingleFrame"
      }
    },
    {
      "data": {
        "key": "sheet",
        "value": "entities"
      }
    },
    {
      "data": {
        "key": "behavior",
        "value": "pushable_block"
      }
    },
]
```

(Ideally you wouldn't be editing the json directly, but that's how it works today)

### Editor Instances (Instance Variables)

When you instantiate an instance of the object, you can select it to read its Instance Variables.

![Alt](/assets/images/sokomaker.instance-variables.png "A screenshot from the SokoMaker editor where we see a crate with an orange box around it. To the left sidebar is a list of keys and values, renderer SingleFrame, sheet entities, and behavior pushable_block")

Instance Variables are a list of keys and values that will be appended to the Config Variables. If a key is reused, we will use the "latest" one.

In the above screenshot. We set the objects `sheet` to `entities` on the Config layer, and then (redundantly) overwrite the value as `entities`. However, if we changed the value to `tiles`, the final table would have `sheet` set to `tiles`, which would change the behavior for this particular instance of `crate`.

### Gameplay Instances (State)

Once the object is realized at runtime, the written and overwritten Instance Variables key value pairs are converted into a lua table (or at least, a structure that behaves a lot like a lua table).

```lua
-- assuming `entity` is our entity
print(entity.state["renderer"])

-- also valid
print(entity.state.renderer)

-- either of above logs `SingleFrame`
```

Up until this point, we're limited as to what types we can load into the Instance/Config Variables. Basically we only have primitives to work with (strings, booleans, numbers). However, once we have our fully realized `state` object. We can load whatever we want into it!

We're also free to overwrite values and do all sorts of crazy things!

```lua
-- use the magic "lua" renderer
entity.state["renderer"] = "lua"

-- provide a custom render function
entity.state["render_function"] = function(painter, drawArguments)
    -- custom draw code goes here
end
```

## Sokobjects Types
There are 3 types of "objects" in SokoMaker (collectively called `Sokobjects`). Tiles, Entities, and Props.

### Tiles
For every grid position there is exactly 1 tile. If the level does not specify there should be a tile at a position, SokoMaker will act is though the "default" tile is there. You specify the default tile in your `mod.json`, which lives at the root of your project.

Tiles all share the same `state` table. This means if you change a `state` table in one tile. You'll affect the `state` of _all_ instances of that tile's template in the game session.

### Entities
An entity has a grid position, and multiple entities are free to occupy the same grid position. Each entity also has a unique state table.

In editor, you can select any entity and modify it's Instance Variables which will be realized as a different `state`. When the object is created.

### Props
Props are not on the grid. They're mainly used for non-grid-aligned decorations. Similar to tiles, they also have a shared state with anything that shares the same Config. However, you can spawn a Prop at runtime via a lua script. These spawned props do not share a state with anything else.

![Alt](/assets/images/sokomaker.ernesto-whip.png "A screenshot of a SokoMaker level in play mode, the player character,is using his Lasso to hook onto a glass bottle. There is a brown line connecting his hand to the lasso, with a black outline around it.")

For example, Ernesto's Lasso spawns 2 props, one to represent "the rope" and the other to represent the loop at the end of the rope.

## Magic Keys

There are certain keys you can set in an object's `State` that will magically affect behavior. The generated documentation that comes packaged with SokoMaker explains this.

For example, if you have a key called `behavior` with a value `crate`. SokoMaker will look up the `crate.lua` module and gives that object that behavior.

I think the most interesting ones to talk about are `renderer` and `sheet`.

As a mentioned before. Variables are just a set of key/value pairs that get converted in a lua table. But some of those keys get read by internal systems and result in things showing up on screen.

For example, if you have a key called `renderer` and a value called `SingleFrame`, and a key called `sheet` and a value called `entities` then the following will happen:

- When we try to draw this entity, we'll look at the sprite sheet `entities.png` (if it exists)
- If there is an additional key `frame` defined, we'll read that key to determine which frame to draw in the sprite sheet. If `frame` is not found, we'll draw the first frame.

Similar to magic keys, there are also magic "correct" values for `renderer` such as:

- `SingleFrame`: Draws the `frame` that is in the sprite sheet represented in `sheet`
- `LoopFrames`: Draws the `pose` that is represented in `sheet`.
    - The value of `pose` is a key that is used to reach back into the variables list. If your `pose` is `idle` we look for a key called `idle` that is a comma separated list in square brackets: `[3,6,7]`
    - We'll loop animation frames, in the above example we'll show frame `3` then `6`, then `7`.
    - Caveat: This implementation of "lists" in Instance Variables is clunky. I'd like to do better but this is what I have right now.
- `SmartTile`: Used for things like water tiles. I don't want to belabor this blog post with the full details of how it works. Fundamentally, it takes a sprite sheet and some frames to figure out what sections of the sprite sheet to draw for each scenario.

You can also implement your own custom renderers if you're not satisfied with the built-in ones.

- `lua:<script_name>`: Provided there's a `renderers/<script_name>.lua` this will run the render function defined in that script.

Or, if your desired draw behavior is truly dynamic, you can implement your entire renderer inside a lua closure.

- `lua`: Only makes sense if you have a `render_function` key defined with a lambda for your custom draw code.