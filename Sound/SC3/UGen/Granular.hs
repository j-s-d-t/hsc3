module Sound.SC3.UGen.Granular where

import Sound.SC3.UGen.Rate
import Sound.SC3.UGen.UGen
import Sound.SC3.UGen.UGen.Construct

grainBuf :: Int -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen
grainBuf nc t d s r p i l e = mkOsc AR "GrainBuf" [t, d, s, r, p, i, l, e] nc

grainFM :: Int -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen
grainFM nc t d c m i l e = mkOsc AR "GrainFM" [t, d, c, m, i, l, e] nc

grainIn :: Int -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen
grainIn nc t d i l e = mkOsc AR "GrainIn" [t, d, i, l, e] nc

grainSin :: Int -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen
grainSin nc t d f l e = mkOsc AR "GrainSin" [t, d, f, l, e] nc

warp1 :: Int -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen
warp1 nc b p f w e o r i = mkOsc AR "Warp1" [b, p, f, w, e, o, r, i] nc

-- Local Variables:
-- truncate-lines:t
-- End: