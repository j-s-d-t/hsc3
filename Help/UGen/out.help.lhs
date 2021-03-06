> import Sound.SC3 {- hsc3 -}

Oscillators at outputs zero (330) and one (331)

> g_01 = out 0 (sinOsc AR (mce2 330 331) 0 * 0.1)

`out` is summing, as opposed to `replaceOut`

> g_02 = mrg [out 0 (sinOsc AR (mce2 330 990) 0 * 0.1)
>            ,out 0 (sinOsc AR (mce2 331 991) 0 * 0.1)]
