> Sound.SC3.UGen.Help.viewSC3Help "WT_FilterScale"
> Sound.SC3.UGen.DB.ugenSummary "WT_FilterScale"

> import Sound.SC3

> let {i = whiteNoise 'α' AR * 0.2
>     ;b = localBuf 'β' 2048 1
>     ;c = dwt b i 0.5 0 1 0 0
>     ;x = mouseX KR (-1) 1 Linear 0.1
>     ;c' = wt_FilterScale c x}
> in audition (out 0 (pan2 (idwt c' 0 0 0) x 1))