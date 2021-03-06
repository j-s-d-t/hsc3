-- | The SC3 multiple channel expansion rules over an abstract type.
module Sound.SC3.UGen.MCE where

-- | Multiple channel expansion.
data MCE n = MCE_Unit n | MCE_Vector [n]
             deriving (Eq,Read,Show)

-- | Elements at 'MCE'.
mce_elem :: MCE t -> [t]
mce_elem m =
    case m of
      MCE_Unit e -> [e]
      MCE_Vector e -> e

-- | Extend 'MCE' to specified degree.
mce_extend :: Int -> MCE n -> MCE n
mce_extend n m =
    case m of
      MCE_Unit e -> MCE_Vector (replicate n e)
      MCE_Vector e -> MCE_Vector (take n (cycle e))

-- | Apply /f/ at elements of /m/.
mce_map :: (a -> b) -> MCE a -> MCE b
mce_map f m =
    case m of
      MCE_Unit e -> MCE_Unit (f e)
      MCE_Vector e -> MCE_Vector (map f e)

-- | Apply /f/ pairwise at elements of /m1/ and /m2/.
mce_binop :: (a -> b -> c) -> MCE a -> MCE b -> MCE c
mce_binop f m1 m2 =
    case (m1,m2) of
      (MCE_Unit e1,MCE_Unit e2) -> MCE_Unit (f e1 e2)
      (MCE_Unit e1,MCE_Vector e2) -> MCE_Vector (map (f e1) e2)
      (MCE_Vector e1,MCE_Unit e2) -> MCE_Vector (map (`f` e2) e1)
      (MCE_Vector e1,MCE_Vector e2) ->
          let n = max (length e1) (length e2)
              ext = take n . cycle
          in MCE_Vector (zipWith f (ext e1) (ext e2))

instance Num n => Num (MCE n) where
    (+) = mce_binop (+)
    (-) = mce_binop (-)
    (*) = mce_binop (*)
    abs = mce_map abs
    negate = mce_map negate
    signum = mce_map signum
    fromInteger = MCE_Unit . fromInteger

instance Fractional n => Fractional (MCE n) where
    (/) = mce_binop (/)
    fromRational = MCE_Unit . fromRational
