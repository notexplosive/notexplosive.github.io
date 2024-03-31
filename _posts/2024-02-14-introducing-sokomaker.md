---
layout: post
title: "Introducing: SokoMaker"
date: 2024-02-14
excerpt: Announcing a big project I've been working
---

I'm excited to announce a project I've been working on for the last 8 months or so. **SokoMaker**!

When describing this project in a sentence, I say "I'm making the _Knytt Stories_ of Sokoban games" or "I'm making the RPG Maker for Sokoban games."

However, neither of those descriptions really do the project justice, a more honest pitch would look like:

I am making a Sokoban game, as well as rich tooling around that game. The tools are rich enough that you could build a million different-but-similar games than the one that I'm making. Also, I intend to release this tooling alongside the game.

## The Game

The game is a sequel/spiritual successor/re-telling of [Duel-ity](http://notexplosive.net/duelity). Andrew Murray ([andrfw](http://andrfw.com)) and I made Duel-ity in 10 days for Global Game Jam in 2022. 

Andrew composed at least 4 tracks, drew all the characters, and wrote all the dialogue (with a few "wouldn't it be funny if" ideas from me). Meanwhile, I wrote all the code and designed all the levels. Because I am... well, me, this also involved writing a map editor from scratch. I called it the _Dueled-itor_.

Here's a video of what that looked like:

<iframe width="640" height="360" src="https://www.youtube.com/embed/VaA0bCBY9CI" title="Duelity - Development Montage &amp; Commentary" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

That game was a ton of fun to make, but it has the problem that most jam games have: the moment the jam is over I don't want to touch it anymore. The tools, the animations, the game logic, all of it was slapped together in 10 days and by the 9th day it was really starting to show its (lack of) age.

So, a few years later I decided to start the whole thing over from scratch. This time, much more methodically.

## The Tools

Duel-ity 2 (not it's real title) is made in a set of tools I'm working on called SokoMaker. My hope is that I can release SokoMaker independently of 2uel-ity (not it's real title either). What I might do is release 2Duel-2ity and just say it comes with "a rich editor that lets you rewrite the whole game." For now, I'll be calling the tool SokoMaker.

SokoMaker is block pushing puzzle game maker. You can use it to:
- Make grid based environments using `Tiles`, there is exactly 1 tile at every grid position, tiles don't typically move, but can be replaced at runtime.
- Subdivide those environments into `Rooms`, where you can walk off the edge of one room and into the next.
- Populate those environments with `Entity` instances. Each instance can be initialized with one-off tweaks to give them all unique features and behavior.
- Script behavior and the rules of your game in Lua.
- Create player characters with special abilities.
- Write dialogue with animated text and character portraits.
- Create cutscenes to tell stories within your game.

When I've mentioned SokoMaker to other people in the puzzle game scene, I often get the question: how does this compare to PuzzleScript. PuzzleScript is a great tool for designing Sokoban mechanics with very terse and clear rules-based definitions. However, PuzzleScript has very little flexibility for the game's presentation. For example, it's hard to make a story-based game using PuzzleScript.

With SokoMaker, I'm more interested in giving people the tools to tell stories through the medium of a grid based game. SokoMaker is much less elegant than PuzzleScript in terms of writing mechanics. In exchange, SokoMaker gives you a ton of flexibility in how your game looks and feels to play. There are limits to this currently (for example: the dialogue system is very restrictive on how it's presented) but I hope to address them in future versions of the engine.

## Where can you get it?

SokoMaker isn't finished, but it is usable. I intend to release some version of it as Early Access. Long term, I want to release the editor on steam with Steam Workshop support so people have an easy, built-in marketplace to share their games.

This brings us to the release date... As I mentioned, the editor will be released as early access first to get it in people's hands and get feedback. Although, any feedback I act on might result in API-breaking changes for anyone making an early mod. Releasing software is scary.

That being said, if you're very interested in SokoMaker, and are willing to accept that any mod you write in it might become deprecated by future versions, shoot me an email: sokomaker (at) notexplosive (dot) net