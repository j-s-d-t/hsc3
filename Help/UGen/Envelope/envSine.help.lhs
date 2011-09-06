> Sound.SC3.UGen.Help.viewSC3Help "Env.*sine"
> :t envSine

> import Sound.SC3

> let {s = envSine 9 0.1
>     ;e = envGen KR 1 1 0 1 RemoveSynth s}
> in audition (out 0 (sinOsc AR 440 0 * e))

