> Sound.SC3.UGen.Help.viewSC3Help "PV_BinScramble"
> Sound.SC3.UGen.DB.ugenSummary "PV_BinScramble"

> import Sound.SC3.ID

> let fileName = "/home/rohan/data/audio/pf-c5.snd"
> in withSC3 (\fd -> do {_ <- async fd (b_alloc 10 2048 1)
>                       ;async fd (b_allocRead 12 fileName 0 0)})

> let {a = playBuf 1 AR 12 (bufRateScale KR 12) 1 0 Loop DoNothing
>     ;f = fft' 10 a
>     ;x = mouseX' KR 0.0 1.0 Linear 0.1
>     ;y = mouseY' KR 0.0 1.0 Linear 0.1
>     ;g = pv_BinScramble 'a' f x y (impulse KR 4 0)}
> in audition (out 0 (pan2 (ifft' g) 0 0.5))
