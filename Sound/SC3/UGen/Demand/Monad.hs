-- | Monad constructors for demand 'UGen's, see also
-- "Sound.SC3.UGen.Demand.ID".
module Sound.SC3.UGen.Demand.Monad where

import Sound.SC3.UGen.Demand.ID as D
import Sound.SC3.UGen.Enum
import Sound.SC3.UGen.Type
import Sound.SC3.UGen.UGen.Lift
import Sound.SC3.UGen.UId

-- | Buffer demand ugen.
dbufrd :: (UId m) => UGen -> UGen -> Loop -> m UGen
dbufrd = liftU3 D.dbufrd

-- | Buffer write on demand unit generator.
dbufwr :: (UId m) => UGen -> UGen -> UGen -> Loop -> m UGen
dbufwr = liftU4 D.dbufwr

-- | Demand rate white noise.
dwhite :: (UId m) => UGen -> UGen -> UGen -> m UGen
dwhite = liftU3 D.dwhite

-- | Demand rate integer white noise.
diwhite :: (UId m) => UGen -> UGen -> UGen -> m UGen
diwhite = liftU3 D.diwhite

-- | Demand rate brown noise.
dbrown :: (UId m) => UGen -> UGen -> UGen -> UGen -> m UGen
dbrown = liftU4 D.dbrown

-- | Demand rate integer brown noise.
dibrown :: (UId m) => UGen -> UGen -> UGen -> UGen -> m UGen
dibrown = liftU4 D.dibrown

-- | Demand rate random selection.
drand :: (UId m) => UGen -> UGen -> m UGen
drand = liftU2 D.drand

-- | Demand rate random selection with no immediate repetition.
dxrand :: (UId m) => UGen -> UGen -> m UGen
dxrand = liftU2 D.dxrand

-- | Demand rate weighted random sequence generator.
dwrand :: (UId m) => UGen -> UGen -> UGen -> m UGen
dwrand = liftU3 D.dwrand

-- | Demand rate arithmetic series.
dseries :: (UId m) => UGen -> UGen -> UGen -> m UGen
dseries = liftU3 D.dseries

-- | Demand rate geometric series.
dgeom :: (UId m) => UGen -> UGen -> UGen -> m UGen
dgeom = liftU3 D.dgeom

-- | Demand rate sequence generator.
dseq :: (UId m) => UGen -> UGen -> m UGen
dseq = liftU2 D.dseq

-- | Demand rate series generator.
dser :: (UId m) => UGen -> UGen -> m UGen
dser = liftU2 D.dser

-- | Demand rate sequence shuffler.
dshuf :: (UId m) => UGen -> UGen -> m UGen
dshuf = liftU2 D.dshuf

-- | Demand input replication
dstutter :: (UId m) => UGen -> UGen -> m UGen
dstutter = liftU2 D.dstutter

-- | Demand rate input switching.
dswitch1 :: (UId m) => UGen -> UGen -> m UGen
dswitch1 = liftU2 D.dswitch1

-- | Demand rate input switching.
dswitch :: (UId m) => UGen -> UGen -> m UGen
dswitch = liftU2 D.dswitch