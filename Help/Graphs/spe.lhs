spe (jmcc)

> let { chain n f = foldl (>=>) return (replicate n f)
>     ; rapf i = do { r <- clone 2 (rand 0 0.05)
>                   ; return (allpassN i 0.05 r 4) }
>     ; src = let { t = impulse KR 9 0
>                 ; e = envGen KR t 0.1 0 1 DoNothing envPerc'
>                 ; s = mce [ 00, 03, 02, 07
>                           , 08, 32, 16, 18
>                           , 00, 12, 24, 32 ] }
>             in do { n <- lfNoise1 KR 1
>                   ; m <- dseq dinf s
>                   ; let { f = midiCPS (demand t 0 m + 32)
>                         ; o = lfSaw AR f 0 * e
>                         ; rq = midiCPS (n * 36 + 110) }
>                     in return (rlpf o rq 0.1) } }
> in audition . (out 0) =<< chain 4 rapf =<< src

[variant of graph in streams & patterns tutorial]