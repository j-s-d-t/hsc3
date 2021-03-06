> import Sound.SC3 {- hsc3 -}

Frequency at X axis and amplitude at Y axis.

> g_01 =
>     let freq = mouseX KR 20 2000 Exponential 0.1
>         ampl = mouseY KR 0.01 0.1 Linear 0.1
>     in sinOsc AR freq 0 * ampl

There is a variant with equal arguments but a random traversal.

> g_02 =
>     let freq = mouseX' KR 20 2000 Exponential 0.1
>         ampl = mouseY' KR 0.01 0.1 Linear 0.1
>     in sinOsc AR freq 0 * ampl
