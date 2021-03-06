-- | Common unit generator graphs.
module Sound.SC3.UGen.Bindings.Composite where

import Control.Monad {- base -}
import Data.List {- base -}
import qualified Data.List.Split as Split {- split -}
import Data.Maybe {- base -}

import Sound.SC3.Common.Enum
import Sound.SC3.Common.Envelope
import Sound.SC3.Common.Math
import Sound.SC3.Common.Math.Filter.BEQ
import Sound.SC3.Common.Math.Operator
import Sound.SC3.Common.Rate
import Sound.SC3.Common.UId

import Sound.SC3.UGen.Bindings.DB
import Sound.SC3.UGen.Bindings.HW
import Sound.SC3.UGen.Bindings.Monad
import Sound.SC3.UGen.Type
import Sound.SC3.UGen.UGen

-- | Generate a localBuf and use setBuf to initialise it.
asLocalBuf :: ID i => i -> [UGen] -> UGen
asLocalBuf i xs =
    let b = localBuf i 1 (fromIntegral (length xs))
        s = setBuf' b xs 0
    in mrg2 b s

-- | 24db/oct rolloff - 4th order resonant Low Pass Filter
bLowPass4 :: UGen -> UGen -> UGen -> UGen
bLowPass4 i f rq =
  let (a0, a1, a2, b1, b2) = bLowPassCoef sampleRate f rq
      flt z = sos z a0 a1 a2 b1 b2
  in flt (flt i)

-- | 24db/oct rolloff - 4th order resonant Hi Pass Filter
bHiPass4 :: UGen -> UGen -> UGen -> UGen
bHiPass4 i f rq =
  let (a0, a1, a2, b1, b2) = bHiPassCoef sampleRate f rq
      flt z = sos z a0 a1 a2 b1 b2
  in flt (flt i)

-- | Buffer reader (no interpolation).
bufRdN :: Int -> Rate -> UGen -> UGen -> Loop UGen -> UGen
bufRdN n r b p l = bufRd n r b p l NoInterpolation

-- | Buffer reader (linear interpolation).
bufRdL :: Int -> Rate -> UGen -> UGen -> Loop UGen -> UGen
bufRdL n r b p l = bufRd n r b p l LinearInterpolation

-- | Buffer reader (cubic interpolation).
bufRdC :: Int -> Rate -> UGen -> UGen -> Loop UGen -> UGen
bufRdC n r b p l = bufRd n r b p l CubicInterpolation

-- | Triggers when a value changes
changed :: UGen -> UGen -> UGen
changed input threshold = abs (hpz1 input) `greater_than` threshold

-- | 'mce' variant of 'lchoose'.
choose :: ID m => m -> UGen -> UGen
choose e = lchoose e . mceChannels

-- | 'liftUId' of 'choose'.
chooseM :: UId m => UGen -> m UGen
chooseM = liftUId1 choose

-- | 'clearBuf' of 'localBuf'.
clearLocalBuf :: ID a => a -> UGen -> UGen -> UGen
clearLocalBuf z nc nf = clearBuf (localBuf z nc nf)

-- | Demand rate (:) function.
dcons :: ID m => (m,m,m) -> UGen -> UGen -> UGen
dcons (z0,z1,z2) x xs =
    let i = dseq z0 1 (mce2 0 1)
        a = dseq z1 1 (mce2 x xs)
    in dswitch z2 i a

-- | Demand rate (:) function.
dconsM :: (UId m) => UGen -> UGen -> m UGen
dconsM x xs = do
  i <- dseqM 1 (mce2 0 1)
  a <- dseqM 1 (mce2 x xs)
  dswitchM i a

-- | Dynamic klang, dynamic sine oscillator bank
dynKlang :: Rate -> UGen -> UGen -> UGen -> UGen
dynKlang r fs fo s =
    let gen (f:a:ph:xs) = sinOsc r (f * fs + fo) ph * a + gen xs
        gen _ = 0
    in gen (mceChannels s)

-- | Dynamic klank, set of non-fixed resonating filters.
dynKlank :: UGen -> UGen -> UGen -> UGen -> UGen -> UGen
dynKlank i fs fo ds s =
    let gen (f:a:d:xs) = ringz i (f * fs + fo) (d * ds) * a + gen xs
        gen _ = 0
    in gen (mceChannels s)

-- | 'linExp' with input range of (-1,1).
exprange :: UGen -> UGen -> UGen -> UGen
exprange l r s = linExp s (-1) 1 l r

-- | Variant FFT constructor with default values for hop size (0.5),
-- window type (0), active status (1) and window size (0).
fft' :: UGen -> UGen -> UGen
fft' buf i = fft buf i 0.5 0 1 0

-- | 'fft' variant that allocates 'localBuf'.
--
-- > let c = ffta 'α' 2048 (soundIn 0) 0.5 0 1 0
-- > in audition (out 0 (ifft c 0 0))
ffta :: ID i => i -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen -> UGen
ffta z nf i h wt a ws =
    let b = localBuf z 1 nf
    in fft b i h wt a ws

-- | Sum of 'numInputBuses' and 'numOutputBuses'.
firstPrivateBus :: UGen
firstPrivateBus = numInputBuses + numOutputBuses

-- | Frequency shifter, in terms of 'hilbert' (see also 'freqShift').
freqShift_hilbert :: UGen -> UGen -> UGen -> UGen
freqShift_hilbert i f p =
    let o = sinOsc AR f (mce [p + 0.5 * pi, p])
        h = hilbert i
    in mix (h * o)

-- | Variant of 'hilbert' using FFT (with a delay) for better results.
-- Buffer should be 2048 or 1024.
-- 2048 = better results, more delay.
-- 1024 = less delay, little choppier results.
hilbertFIR :: UGen -> UGen -> UGen
hilbertFIR s b =
  let c0 = fft' b s
      c1 = pv_PhaseShift90 c0
      delay = bufDur KR b
  in mce2 (delayN s delay delay) (ifft' c1)

-- | Variant ifft with default value for window type.
ifft' :: UGen -> UGen
ifft' buf = ifft buf 0 0

{-
-- | Linear interpolating variant on index.
indexL :: UGen -> UGen -> UGen
indexL b i =
    let x = index b i
        y = index b (i + 1)
    in linLin (frac i) 0 1 x y
-}

-- | Generalised Klan(k/g) specification rule.  /f/ unwraps inputs, /g/ wraps output.
--
-- > let r = [220,0.2,0,219,0.1,1,221,0.1,2]
-- > in klanx_spec_f id id [220,219,221] [0.2,0.1,0.1] [0,1,2] == r
klanx_spec_f :: (a -> [b]) -> ([b] -> c) -> a -> a -> a -> c
klanx_spec_f f g fr am z = g ((concat . transpose) [f fr,f am,f z])

-- | Format frequency, amplitude and decay time data as required for klank.
klangSpec :: [UGen] -> [UGen] -> [UGen] -> UGen
klangSpec = klanx_spec_f id mce

-- | Variant of 'klangSpec' for non-UGen inputs.
klangSpec_k :: Real n => [n] -> [n] -> [n] -> UGen
klangSpec_k = klanx_spec_f (map constant) mce

-- | Variant of 'klangSpec' for 'MCE' inputs.
klangSpec_mce :: UGen -> UGen -> UGen -> UGen
klangSpec_mce = klanx_spec_f mceChannels mce

-- | Format frequency, amplitude and decay time data as required for klank.
klankSpec :: [UGen] -> [UGen] -> [UGen] -> UGen
klankSpec = klanx_spec_f id mce

-- | Variant for non-UGen inputs.
klankSpec_k :: Real n => [n] -> [n] -> [n] -> UGen
klankSpec_k = klanx_spec_f (map constant) mce

-- | Variant of 'klankSpec' for 'MCE' inputs.
klankSpec_mce :: UGen -> UGen -> UGen -> UGen
klankSpec_mce = klanx_spec_f mceChannels mce

-- | Randomly select one of a list of UGens (initialisation rate).
lchoose :: ID m => m -> [UGen] -> UGen
lchoose e a = select (iRand e 0 (fromIntegral (length a))) (mce a)

-- | 'liftUId' of 'lchoose'.
lchooseM :: UId m => [UGen] -> m UGen
lchooseM = liftUId1 lchoose

-- | 'linExp' of (-1,1).
linExp_b :: UGen -> UGen -> UGen -> UGen
linExp_b i = linExp i (-1) 1

-- | 'linExp' of (0,1).
linExp_u :: UGen -> UGen -> UGen -> UGen
linExp_u i = linExp i 0 1

-- | Map from one linear range to another linear range.
linLin :: UGen -> UGen -> UGen -> UGen -> UGen -> UGen
linLin = linlin_ma mulAdd

-- | 'linLin' where source is (0,1).
linLin_u :: UGen -> UGen -> UGen -> UGen
linLin_u i = linLin i 0 1

-- | 'linLin' where source is (-1,1).
linLin_b :: UGen -> UGen -> UGen -> UGen
linLin_b i = linLin i (-1) 1

-- | Variant with defaults of zero.
localIn' :: Int -> Rate -> UGen
localIn' nc r = localIn nc r (mce (replicate nc 0))

-- | Generate an 'envGen' UGen with @fadeTime@ and @gate@ controls.
--
-- > import Sound.SC3
-- > audition (out 0 (makeFadeEnv 1 * sinOsc AR 440 0 * 0.1))
-- > withSC3 (send (n_set1 (-1) "gate" 0))
makeFadeEnv :: Double -> UGen
makeFadeEnv fadeTime =
    let dt = control KR "fadeTime" (realToFrac fadeTime)
        gate_ = control KR "gate" 1
        startVal = dt `less_than_or_equal_to` 0
        env = Envelope [startVal,1,0] [1,1] [EnvLin,EnvLin] (Just 1) Nothing 0
    in envGen KR gate_ 1 0 dt RemoveSynth env

-- | 'mce' of 'map' /f/ of 'id_seq' /n/.
mce_gen :: ID z => (Id -> UGen) -> Int -> z -> UGen
mce_gen f n = mce . map f . id_seq n

-- | Monad/applicative variant of mce_gen.
mce_genM :: Applicative f => f UGen -> Int -> f UGen
mce_genM f n = fmap mce (replicateM n f)

-- | Count 'mce' channels.
mceN :: UGen -> UGen
mceN = constant . length . mceChannels

-- | Collapse possible mce by summing.
mix :: UGen -> UGen
mix = sum_opt . mceChannels

-- | Mix variant, sum to n channels.
mixN :: Int -> UGen -> UGen
mixN n u =
    let xs = transpose (Split.chunksOf n (mceChannels u))
    in mce (map sum_opt xs)

-- | Construct and sum a set of UGens.
mixFill :: Integral n => Int -> (n -> UGen) -> UGen
mixFill n f = mix (mce (map f [0 .. fromIntegral n - 1]))

-- | Monad variant on mixFill.
mixFillM :: (Integral n,Monad m) => Int -> (n -> m UGen) -> m UGen
mixFillM n f = liftM sum_opt (mapM f [0 .. fromIntegral n - 1])

-- | Variant that is randomly pressed.
mouseButton' :: Rate -> UGen -> UGen -> UGen -> UGen
mouseButton' rt l r tm =
    let o = lfClipNoise 'z' rt 1
    in lag (linLin o (-1) 1 l r) tm

-- | Randomised mouse UGen (see also 'mouseX'' and 'mouseY'').
mouseR :: ID a => a -> Rate -> UGen -> UGen -> Warp UGen -> UGen -> UGen
mouseR z rt l r ty tm =
  let f = case ty of
            Linear -> linLin
            Exponential -> linExp
            _ -> undefined
  in lag (f (lfNoise1 z rt 1) (-1) 1 l r) tm

-- | Variant that randomly traverses the mouseX space.
mouseX' :: Rate -> UGen -> UGen -> Warp UGen -> UGen -> UGen
mouseX' = mouseR 'x'

-- | Variant that randomly traverses the mouseY space.
mouseY' :: Rate -> UGen -> UGen -> Warp UGen -> UGen -> UGen
mouseY' = mouseR 'y'

-- | Translate onset type string to constant UGen value.
onsetType :: Num a => String -> a
onsetType s =
    let t = ["power", "magsum", "complex", "rcomplex", "phase", "wphase", "mkl"]
    in fromIntegral (fromMaybe 3 (elemIndex s t))

-- | Onset detector with default values for minor parameters.
onsets' :: UGen -> UGen -> UGen -> UGen
onsets' c t o = onsets c t o 1 0.1 10 11 1 0

-- | Format magnitude and phase data data as required for packFFT.
packFFTSpec :: [UGen] -> [UGen] -> UGen
packFFTSpec m p =
    let interleave x = concat . zipWith (\a b -> [a,b]) x
    in mce (interleave m p)

-- | Calculate size of accumulation buffer given FFT and IR sizes.
pc_calcAccumSize :: Int -> Int -> Int
pc_calcAccumSize fft_size ir_length =
    let partition_size = fft_size `div` 2
        num_partitions = (ir_length `div` partition_size) + 1
    in fft_size * num_partitions

-- | PM oscillator.
-- cf = carrier frequency, mf = modulation frequency, pm = pm-index = 0.0, mp = mod-phase = 0.0
pmOsc :: Rate -> UGen -> UGen -> UGen -> UGen -> UGen
pmOsc r cf mf pm mp = sinOsc r cf (sinOsc r mf mp * pm)

-- | Variant of 'poll' that generates an 'mrg' value with the input
-- signal at left, and that allows a constant /frequency/ input in
-- place of a trigger.
poll' :: UGen -> UGen -> UGen -> UGen -> UGen
poll' t i l tr =
    let t' = if isConstant t then impulse KR t 0 else t
    in mrg [i,poll t' i l tr]

-- | Variant of 'in'' offset so zero if the first private bus.
privateIn :: Int -> Rate -> UGen -> UGen
privateIn nc rt k = in' nc rt (k + firstPrivateBus)

-- | Variant of 'out' offset so zero if the first private bus.
privateOut :: UGen -> UGen -> UGen
privateOut k = out (k + firstPrivateBus)

-- | Apply function /f/ to each bin of an @FFT@ chain, /f/ receives
-- magnitude, phase and index and returns a (magnitude,phase).
pvcollect :: UGen -> Int -> (UGen -> UGen -> Int -> (UGen, UGen)) -> Int -> Int -> UGen -> UGen
pvcollect c nf f from to z =
    let m = unpackFFT c nf from to 0
        p = unpackFFT c nf from to 1
        i = [from .. to]
        e = zipWith3 f m p i
        mp = uncurry packFFTSpec (unzip e)
    in packFFT c nf from to z mp

-- | /dur/ and /hop/ are in seconds, /frameSize/ and /sampleRate/ in
-- frames, though the latter maybe fractional.
--
-- > pv_calcPVRecSize 4.2832879818594 1024 0.25 48000.0 == 823299
pv_calcPVRecSize :: Double -> Int -> Double -> Double -> Int
pv_calcPVRecSize dur frame_size hop sample_rate =
    let frame_size' = fromIntegral frame_size
        raw_size = ceiling ((dur * sample_rate) / frame_size') * frame_size
    in ceiling (fromIntegral raw_size * recip hop + 3)

-- | 'rand' with left edge set to zero.
rand0 :: ID a => a -> UGen -> UGen
rand0 z = rand z 0

-- | 'UId' form of 'rand0'.
rand0M :: UId m => UGen -> m UGen
rand0M = randM 0

-- | 'rand' with left edge set to negative /n/.
rand2 :: ID a => a -> UGen -> UGen
rand2 z n = rand z (negate n) n

-- | 'UId' form of 'rand2'.
rand2M :: UId m => UGen -> m UGen
rand2M n = randM (negate n) n

-- | RMS variant of 'runningSum'.
runningSumRMS :: UGen -> UGen -> UGen
runningSumRMS z n = sqrt (runningSum (z * z) n * recip n)

-- | Mix one output from many sources
selectX :: UGen -> UGen -> UGen
selectX ix xs =
    let s0 = select (roundTo ix 2) xs
        s1 = select (trunc ix 2 + 1) xs
    in xFade2 s0 s1 (fold2 (ix * 2 - 1) 1) 1

-- | Set local buffer values.
setBuf' :: UGen -> [UGen] -> UGen -> UGen
setBuf' b xs o = setBuf b o (fromIntegral (length xs)) (mce xs)

-- | Silence.
silent :: Int -> UGen
silent n = let s = dc AR 0 in mce (replicate n s)

{- | Zero indexed audio input buses.
     Optimises case of consecutive UGens.

> soundIn (mce2 0 1) == in' 2 AR numOutputBuses
> soundIn (mce2 0 2) == in' 1 AR (numOutputBuses + mce2 0 2)

-}
soundIn :: UGen -> UGen
soundIn u =
    let r = in' 1 AR (numOutputBuses + u)
    in case u of
         MCE_U m ->
             let n = mceProxies m
             in if all (==1) (zipWith (-) (tail n) n)
                then in' (length n) AR (numOutputBuses + head n)
                else r
         _ -> r

-- | Pan a set of channels across the stereo field.
--
-- > input, spread:1, level:1, center:0, levelComp:true
splay :: UGen -> UGen -> UGen -> UGen -> Bool -> UGen
splay i s l c lc =
    let n = max 2 (fromIntegral (fromMaybe 1 (mceDegree i)))
        m = n - 1
        p = map ( (+ (-1.0)) . (* (2 / m)) ) [0 .. m]
        a = if lc then sqrt (1 / n) else 1
    in mix (pan2 i (mce p * s + c) 1) * l * a

-- | Optimised UGen sum function.
sum_opt :: [UGen] -> UGen
sum_opt = sum_opt_f sum3 sum4

-- | Single tap into a delayline
tap :: Int -> UGen -> UGen -> UGen
tap numChannels bufnum delaytime =
    let n = delaytime * negate sampleRate
    in playBuf numChannels AR bufnum 1 0 n Loop DoNothing

-- | Randomly select one of several inputs on trigger.
tChoose :: ID m => m -> UGen -> UGen -> UGen
tChoose z t a = select (tiRand z 0 (mceN a - 1) t) a

-- | Randomly select one of several inputs.
tChooseM :: (UId m) => UGen -> UGen -> m UGen
tChooseM t a = do
  r <- tiRandM 0 (constant (length (mceChannels a) - 1)) t
  return (select r a)

-- | Triangle wave as sum of /n/ sines.
-- For partial n, amplitude is (1 / square n) and phase is pi at every other odd partial.
triAS :: Int -> UGen -> UGen
triAS n f0 =
    let mk_freq i = f0 * fromIntegral i
        mk_amp i = if even i then 0 else 1 / fromIntegral (i * i)
        mk_ph i = if i + 1 `mod` 4 == 0 then pi else 0
        m = [1,3 .. n]
        param = zip3 (map mk_freq m) (map mk_ph m) (map mk_amp m)
    in sum_opt (map (\(fr,ph,am) -> sinOsc AR fr ph * am) param)

-- | Randomly select one of several inputs on trigger (weighted).
tWChoose :: ID m => m -> UGen -> UGen -> UGen -> UGen -> UGen
tWChoose z t a w n =
    let i = tWindex z t n w
    in select i a

-- | Randomly select one of several inputs (weighted).
tWChooseM :: (UId m) => UGen -> UGen -> UGen -> UGen -> m UGen
tWChooseM t a w n = do
  i <- tWindexM t n w
  return (select i a)

-- | Unpack an FFT chain into separate demand-rate FFT bin streams.
unpackFFT :: UGen -> Int -> Int -> Int -> UGen -> [UGen]
unpackFFT c nf from to w = map (\i -> unpack1FFT c (constant nf) (constant i) w) [from .. to]

-- | VarLag in terms of envGen
varLag_env :: UGen -> UGen -> Envelope_Curve UGen -> UGen -> UGen
varLag_env in_ time curve start =
  let rt = rateOf in_
      e = Envelope [start,in_] [time] [curve] Nothing Nothing 0
      time_ch = if rateOf time == IR then 0 else changed time 0
      tr = changed in_ 0 + time_ch + impulse rt 0 0
  in envGen rt tr 1 0 1 DoNothing e

{- | If @z@ isn't a sink node route to an @out@ node writing to @bus@.
     If @fadeTime@ is given multiply by 'makeFadeEnv'.

> import Sound.SC3 {- hsc3 -}
> audition (wrapOut (Just 1) (sinOsc AR 440 0 * 0.1))
> import Sound.OSC {- hosc -}
> withSC3 (sendMessage (n_set1 (-1) "gate" 0))
-}
wrapOut :: Maybe Double -> UGen -> UGen
wrapOut fadeTime z =
    let bus = control KR "out" 0
    in if isSink z
       then z
       else out bus (z * maybe 1 makeFadeEnv fadeTime)

-- * wslib

-- | Cross-fading version of 'playBuf'.
playBufCF :: Int -> UGen -> UGen -> UGen -> UGen -> Loop UGen -> UGen -> Int -> UGen
playBufCF nc bufnum rate trigger startPos loop lag' n =
    let trigger' = if rateOf trigger == DR
                   then tDuty AR trigger 0 DoNothing 1 0
                   else trigger
        index' = stepper trigger' 0 0 (constant n - 1) 1 0
        on = map
             (\i -> inRange index' (i - 0.5) (i + 0.5))
             [0 .. constant n - 1]
        rate' = case rateOf rate of
                  DR -> map (\on' -> demand on' 0 rate) on
                  KR -> map (gate rate) on
                  AR -> map (gate rate) on
                  IR -> map (const rate) on
        startPos' = if rateOf startPos == DR
                    then demand trigger' 0 startPos
                    else startPos
        lag'' = 1 / lag'
        s = map
            (\(on',r) -> let p = playBuf nc AR bufnum r on' startPos' loop DoNothing
                         in p * sqrt (slew on' lag'' lag''))
            (zip on rate')
    in sum_opt s

-- * adc

-- | An oscillator that reads through a table once.
osc1 :: Rate -> UGen -> UGen -> DoneAction UGen -> UGen
osc1 rt buf dur doneAction =
    let ph = line rt 0 (bufFrames IR buf - 1) dur doneAction
    in bufRd 1 rt buf ph NoLoop LinearInterpolation
