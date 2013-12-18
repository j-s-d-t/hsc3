> Sound.SC3.UGen.Help.viewSC3Help "PlayBuf"
> Sound.SC3.UGen.DB.ugenSummary "PlayBuf"

> import Sound.SC3

Load sound file to buffer zero (single channel file required for examples)

> let fn = "/home/rohan/data/audio/pf-c5.aif"
> in withSC3 (async (b_allocRead 0 fn 0 0))

Play once only.

> let s = bufRateScale KR 0
> in audition (out 0 (playBuf 1 AR 0 s 1 0 NoLoop RemoveSynth))

Play in infinite loop.

> let s = bufRateScale KR 0
> in audition (out 0 (playBuf 1 AR 0 s 1 0 Loop DoNothing))

Trigger playback at each pulse.

> let {t = impulse KR 2 0
>     ;s = bufRateScale KR 0}
> in audition (out 0 (playBuf 1 AR 0 s t 0 NoLoop DoNothing))

Trigger playback at each pulse (diminishing intervals).

> let {f = xLine KR 0.1 100 10 RemoveSynth
>     ;t = impulse KR f 0
>     ;s = bufRateScale KR 0}
> in audition (out 0 (playBuf 1 AR 0 s t 0 NoLoop DoNothing))

Loop playback, accelerating pitch.

> let r = xLine KR 0.1 100 60 RemoveSynth
> in audition (out 0 (playBuf 1 AR 0 r 1 0 Loop DoNothing))

Sine wave control of playback rate, negative rate plays backwards.

> let {f = xLine KR 0.2 8 30 RemoveSynth
>     ;r = fSinOsc KR f 0 * 3 + 0.6
>     ;s = bufRateScale KR 0 * r}
> in audition (out 0 (playBuf 1 AR 0 s 1 0 Loop DoNothing))

Release buffer.

> withSC3 (send (b_free 0))

Channel mismatch, single channel buffer, two channel playBuf, result
is silence and channel mismatch message in server log.

> let fn = "/home/rohan/data/audio/pf-c5.aif"
> in withSC3 (async (b_allocRead 0 fn 0 0))

> let s = bufRateScale KR 0
> in audition (out 0 (playBuf 2 AR 0 s 1 0 Loop DoNothing))

Graph will sound after loading a two channel signal to buffer, and
stop again after loading a single channel sound file.

> let fn = "/home/rohan/data/audio/sp/tinguely.aif"
> in withSC3 (async (b_allocRead 0 fn 0 0))

Scan sequence of buffers:

> let {n = 29 * 6
>     ;b = mouseX KR 0 n Linear 0.2
>     ;r = bufRateScale KR b}
> in audition (out 0 (playBuf 1 AR b r 1 0 Loop DoNothing))

In sclanguage:

{var fn = "/home/rohan/data/audio/pf-c5.aif"
;s.sendMsg("/b_allocRead",0,fn,0,0)}.value

{var sc = BufRateScale.kr(0)
;Out.ar(0,PlayBuf.ar(2,0,sc,1,0,1,0))}.play

{var fn = "/home/rohan/data/audio/sp/tinguely.aif"
;s.sendMsg("/b_allocRead",0,fn,0,0)}.value

{var b = MouseX.kr(32,64,0,0.2)
;var r = BufRateScale.kr(b)
;Out.ar(0,PlayBuf.ar(1,b,r,1,0,1,0))}.play
