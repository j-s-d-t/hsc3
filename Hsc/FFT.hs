module Hsc.FFT where

import Hsc.Rate (Rate(AR, KR))
import Hsc.Construct (mkOsc, mkOsc', uniquify, zeroUId)

fft  buf i = mkOsc KR "FFT"  [buf,i] 1 0
ifft buf   = mkOsc AR "IFFT" [buf]   1 0

pv_Add ba bb = mkOsc KR "PV_Add" [ba,bb] 1 0
pv_BinScramble buf wp width trg = mkOsc KR "PV_BinScramble" [buf,wp,width,trg] 1 0
pv_BinShift buf str shift = mkOsc KR "PV_BinShift" [buf,str,shift] 1 0
pv_BinWipe ba bb wp = mkOsc KR "PV_BinWipe" [ba,bb,wp] 1 0
pv_BrickWall buf wp = mkOsc KR "PV_BrickWall" [buf,wp] 1 0
pv_ConformalMap buf real imag = mkOsc KR "PV_ConformalMap" [buf,real,imag] 1 0
pv_CopyPhase ba bb = mkOsc KR "PV_CopyPhase" [ba,bb] 1 0
pv_Diffuser buf trg = mkOsc KR "PV_Diffuser" [buf,trg] 1 0
pv_HainsworthFoote buf h f thr wait = mkOsc KR "PV_HainsworthFoote" [buf,h,f,thr,wait] 1 0
pv_JensenAndersen buf sc hfe hfc sf thr wait = mkOsc KR "PV_JensenAndersen" [buf,sc,hfe,hfc,sf,thr,wait] 1 0
pv_LocalMax buf thr = mkOsc KR "PV_LocalMax" [buf,thr] 1 0
pv_MagAbove buf thr = mkOsc KR "PV_MagAbove" [buf,thr] 1 0
pv_MagBelow buf thr = mkOsc KR "PV_MagBelow" [buf,thr] 1 0
pv_MagClip buf thr = mkOsc KR "PV_MagClip" [buf,thr] 1 0
pv_MagFreeze buf frz = mkOsc KR "PV_MagFreeze" [buf,frz] 1 0
pv_MagMul ba bb = mkOsc KR "PV_MagMul" [ba,bb] 1 0
pv_MagNoise buf = mkOsc KR "PV_MagNoise" [buf] 1 0
pv_MagShift buf str shift = mkOsc KR "PV_MagShift" [buf,str,shift] 1 0
pv_MagSmear buf bins = mkOsc KR "PV_MagSmear" [buf,bins] 1 0
pv_MagSquared buf = mkOsc KR "PV_MagSquared" [buf] 1 0
pv_Max ba bb = mkOsc KR "PV_Max" [ba,bb] 1 0
pv_Min ba bb = mkOsc KR "PV_Min" [ba,bb] 1 0
pv_Mul ba bb = mkOsc KR "PV_Mul" [ba,bb] 1 0
pv_PhaseShift buf shift = mkOsc KR "PV_PhaseShift" [buf,shift] 1 0
pv_PhaseShift270 buf = mkOsc KR "PV_PhaseShift270" [buf] 1 0
pv_PhaseShift90 buf = mkOsc KR "PV_PhaseShift90" [buf] 1 0
pv_RectComb buf teeth phase width = mkOsc KR "PV_RectComb" [buf,teeth,phase,width] 1 0
pv_RectComb2 ba bb teeth phase width = mkOsc KR "PV_RectComb2" [ba,bb,teeth,phase,width] 1 0

pv_RandComb' id buf wp trg = mkOsc' KR "PV_RandComb" [buf,wp,trg] 1 0 id
pv_RandWipe' id ba bb wp trg = mkOsc' KR "PV_RandWipe" [ba,bb,wp,trg] 1 0 id

pv_RandComb buf wp trg = uniquify (pv_RandComb' zeroUId buf wp trg)
pv_RandWipe ba bb wp trg = uniquify (pv_RandWipe' zeroUId ba bb wp trg)

-- Local Variables:
-- truncate-lines:t
-- End:
