> import Sound.SC3 {- hsc3 -}

see vOsc help for code to allocate and fill tables 0 to 7...

oscillator at buffers 0 through 7, mouse selects buffer.

> f_01 k0 kN =
>     let x = mouseX KR k0 (k0 + kN - 1) Linear 0.1
>         y = mouseY KR 0.01 0.2 Exponential 0.2
>         o1 = vOsc3 AR x 120 121 129
>         o2 = vOsc3 AR x 119 123 127
>     in mce2 o1 o2 * y

> g_01 = f_01 0 8

  let k = 0 in audition (f_01 k 24)
  audition (f_01 0 102)
  audition (f_01 19 31)
