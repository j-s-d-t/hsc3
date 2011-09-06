> Sound.SC3.UGen.Help.viewSC3Help "FreqShift"
> Sound.SC3.UGen.DB.ugenSummary "FreqShift"

> import Sound.SC3.ID

shifting a 100Hz tone by 1 Hz rising to 500Hz
> let {i = sinOsc AR 100 0
>     ;s = xLine KR 1 500 5 RemoveSynth}
> in audition (out 0 (freqShift i s 0 * 0.1))

shifting a complex tone by 1 Hz rising to 500Hz
> let {d = klangSpec [101, 303, 606, 808] [1, 1, 1, 1] [1, 1, 1, 1]
>     ;i = klang AR 1 0 d
>     ;s = xLine KR 1 500 5 RemoveSynth}
> in audition (out 0 (freqShift i s 0 * 0.1))

modulating shift and phase
> let {s = lfNoise2 'a' AR 0.3
>     ;i = sinOsc AR 10 0
>     ;p = linLin (sinOsc AR 500 0) (-1) 1 0 (2 * pi)}
> in audition (out 0 (freqShift i (s * 1500) p * 0.1))

shifting bandpassed noise
> let {n1 = whiteNoise 'a' AR
>     ;n2 = lfNoise0 'a' AR 5.5
>     ;i = bpf n1 1000 0.001
>     ;s = n2 * 1000}
> in audition (out 0 (freqShift i s 0 * 32))
