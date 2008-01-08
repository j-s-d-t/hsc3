linRand lo hi minmax

Generates a single random float value in linear distribution from
lo to hi, skewed towards lo if minmax < 0, otherwise skewed towards
hi.

> f <- linRand 200.0 10000.0 (mce [-1, 1])
> audition (out 0 (fSinOsc AR f 0 * line KR 0.4 0 0.01 RemoveSynth))
