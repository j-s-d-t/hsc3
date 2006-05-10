module Hsc.Rate where

data Rate = IR | KR | AR | DR deriving (Eq, Show)

instance Ord Rate where
    compare a b = compare (rateOrd a) (rateOrd b)

rateOrd IR = 0
rateOrd DR = 1
rateOrd KR = 2
rateOrd AR = 3

rateId :: Rate -> Int
rateId IR = 0
rateId KR = 1
rateId AR = 2
rateId DR = 3