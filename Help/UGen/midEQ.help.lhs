> import Sound.SC3 {- hsc3 -}

> g_01 =
>     let f = midiCPS (fSinOsc KR 1 0 * 24 + 84)
>     in midEQ (saw AR 200 * 0.2) f 0.3 12

> g_02 =
>     let i = pinkNoise 'α' AR * 0.2 + sinOsc AR 600 0 * 0.1
>         f = sinOsc KR 0.2 (0.5 * pi) * 2 + 600
>     in midEQ i f 0.01 (-24)
