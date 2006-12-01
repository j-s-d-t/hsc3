playBuf numChannels bufnum rate trigger startPos loop

Sample playback oscillator.  Plays back a memory resident sample.

numChannels - number of channels that the buffer will be.  This
              must be a fixed integer. The architechture of the
              SynthDef cannot change after it is compiled.
              Warning: if you supply a bufnum of a buffer that
              has a different numChannels then you have specified
              to the PlayBuf, it will fail silently.

bufnum      - the index of the buffer to use

rate        - 1.0 is the server's sample rate, 2.0 is one octave up, 0.5
              is one octave down -1.0 is backwards normal rate
              etc. Interpolation is cubic.  Note: If the buffer's
              sample rate is different from the server's, you will
              need to multiply the desired playback rate by (file's
              rate / server's rate). The UGen BufRateScale.kr(bufnum)
              returns this factor. See examples below. BufRateScale
              should be used in virtually every case.

trigger       - a trigger causes a jump to the startPos.  A
              trigger occurs when a signal changes from <= 0
              to > 0.

startPos    - sample frame to start playback.

loop        - 1 means true, 0 means false.  This is modulate-able.

Allocate buffer.

> withSC3 (\fd -> do send fd (b_allocRead 10 "/home/rohan/sw/sw-01/audio/metal.wav" 0 0)
>                    wait fd "/done")

Play once only.

> audition $ playBuf 1 AR 10 (bufRateScale KR 10) 1 0 0

Play in infinite loop.

> audition $ playBuf 1 AR 10 (bufRateScale KR 10) 1 0 1

Trigger playback at each pulse.

> let t = impulse KR 2 0
> audition $ playBuf 1 AR 10 (bufRateScale KR 10) t 0 0

Trigger playback at each pulse (diminishing intervals).

> let f = xLine KR 0.1 100 10 RemoveSynth
>     t = impulse KR f 0
> audition $ playBuf 1 AR 10 (bufRateScale KR 10) t 0 0

Loop playback, accelerating pitch.

> let r = xLine KR 0.1 100 60 RemoveSynth
> audition $ playBuf 1 AR 10 r 1 0 1

Sine wave control of playback rate, negative rate plays backwards.

> let f = xLine KR 0.2 8 30 RemoveSynth
>     r = fSinOsc KR f 0 * 3 + 0.6
> audition $ playBuf 1 AR 10 (bufRateScale KR 10 * r) 1 0 1

Release buffer.

> withSC3 (\fd -> send fd (b_free 10))
