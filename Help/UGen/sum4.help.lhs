> import Sound.SC3 {- hsc3 -}

> g_01 = sum4 (sinOsc AR 440 0) (sinOsc AR 441 0) (sinOsc AR 442 0) (sinOsc AR 443 0) * 0.1

> g_02 = mix (sinOsc AR (mce [440 .. 443]) 0) * 0.1
