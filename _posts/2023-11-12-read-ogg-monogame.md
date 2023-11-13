---
layout: post
title: "How To Read an Ogg Vorbis in MonoGame without Content Pipeline"
date: 2023-11-12
excerpt: How to convert from an Ogg Vorbis file to a MonoGame SoundEffect.
---

This is a highly specific technical blog post for a highly specific technical problem. I couldn't find a straight answer for how to accomplish this on Google so hopefully this post will find the next person searching as I did.

## Summary

We'll use `NVorbis` (which comes packaged with MonoGame) to read the samples from an ogg file, then convert those samples into a MonoGame `SoundEffect` object. We will accomplish all of this at runtime without using the Content Pipeline.

## Code

```cs
using System;
using Microsoft.Xna.Framework.Audio;
using NVorbis;

public static class ReadOgg {
    private static void ConvertFloatBufferToShortBuffer(
        float[] inBuffer, short[] outBuffer, int length)
    {
        // The float[] we get from NVorbis has the range [-1f, 1f],
        // we need to convert that to a short[] with a range of [-32768, 32767]
        for (var i = 0; i < length; i++)
        {
            var temp = (int) (short.MaxValue * inBuffer[i]);
            temp = Math.Clamp(temp, short.MinValue, short.MaxValue);
            outBuffer[i] = (short) temp;
        }
    }

    public static SoundEffect ReadSoundEffect(string fullFileName)
    {
        // VorbisReader comes from NVorbis.
        using var vorbis = new VorbisReader(fullFileName);

        // TotalSamples is actually in Frames, 
        // so we need to multiply it by channels to get Samples.
        var frames = new float[vorbis.TotalSamples * vorbis.Channels];

        // Read all frames (again, NVorbis calls them Samples), 
        // starting at index 0 and reading to the end.
        var length = vorbis.ReadSamples(frames, 0, frames.Length);

        // frames is a float[], we need a short[].
        var castBuffer = new short[length];
        ConvertFloatBufferToShortBuffer(frames, castBuffer, castBuffer.Length);

        // Now that we have the sound represented as a short[], 
        // we need to convert that to bytes. 
        // Each short is 2 bytes long, so we need 2X as many bytes
        // as we have shorts.
        var bytes = new byte[castBuffer.Length * 2];

        for (var i = 0; i < castBuffer.Length; i++)
        {
            var b = BitConverter.GetBytes(castBuffer[i]);
            bytes[i * 2] = b[0];
            bytes[i * 2 + 1] = b[1];
        }

        // Finally, we convert the vorbis.Channels count to the AudioChannels enum. 
        // Casting like this: `(AudioChannels) vorbis.Channels` would also work.
        var channels = vorbis.Channels == 2 ? AudioChannels.Stereo : AudioChannels.Mono;

        // Put it all together!
        return new SoundEffect(bytes, vorbis.SampleRate, channels);;
    }
}
```

## Caveats
The above code is quite slow. Even loading a single sound will cause your game to hiccup. This is something you'd want to do during a loading screen or perhaps do asynchronously in the background.

There are probably ways to make this more efficient, but this is enough to get something working.

Anyway, I hope that helps.