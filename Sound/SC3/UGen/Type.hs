--  | Unit Generator ('UGen'), and associated types and instances.
module Sound.SC3.UGen.Type where

import Data.Bits
import Data.List
import Data.Maybe
import Sound.SC3.UGen.Identifier
import Sound.SC3.UGen.Operator
import Sound.SC3.UGen.Rate
import System.Random {- random -}

-- * Basic types

-- | Data type for internalised identifier at 'UGen'.
data UGenId = NoId | UId Int
              deriving (Eq,Show)

-- | Constants.
--
-- > Constant 3 == Constant 3
-- > (Constant 3 > Constant 1) == True
data Constant = Constant {constantValue :: Double}
                deriving (Eq,Ord,Show)

-- | Control inputs.
data Control = Control {controlOperatingRate :: Rate
                       ,controlName :: String
                       ,controlDefault :: Double
                       ,controlTriggered :: Bool}
               deriving (Eq,Show)

-- | Labels.
data Label = Label {ugenLabel :: String}
             deriving (Eq,Show)

-- | Unit generator output descriptor.
type Output = Rate

-- | Operating mode of unary and binary operators.
newtype Special = Special Int
    deriving (Eq, Show)

-- | UGen primitives.
data Primitive = Primitive {ugenRate :: Rate
                           ,ugenName :: String
                           ,ugenInputs :: [UGen]
                           ,ugenOutputs :: [Output]
                           ,ugenSpecial :: Special
                           ,ugenId :: UGenId}
                 deriving (Eq,Show)

-- | Proxy to multiple channel input.
data Proxy = Proxy {proxySource :: Primitive
                   ,proxyIndex :: Int}
            deriving (Eq,Show)

-- | Multiple channel expansion.
data MCE = MCE {mceProxies :: [UGen]}
            deriving (Eq,Show)

-- | Multiple root graph.
data MRG = MRG {mrgLeft :: UGen
               ,mrgRight :: UGen}
           deriving (Eq,Show)

-- | Union type of Unit Generator forms.
data UGen = Constant_U Constant
          | Control_U Control
          | Label_U Label
          | Primitive_U Primitive
          | Proxy_U Proxy
          | MCE_U MCE
          | MRG_U MRG
            deriving (Eq,Show)

-- * Predicates

-- | Constant node predicate.
isConstant :: UGen -> Bool
isConstant u =
    case u of
      Constant_U _ -> True
      _ -> False

-- | True if input is a sink 'UGen', ie. has no outputs.
isSink :: UGen -> Bool
isSink u =
    case u of
      Primitive_U p -> null (ugenOutputs p)
      MCE_U m -> all isSink (mceProxies m)
      MRG_U m -> isSink (mrgLeft m)
      _ -> False

-- * Validators

-- | Ensure input 'UGen' is valid, ie. not a sink.
checkInput :: UGen -> UGen
checkInput u =
    if isSink u
    then error ("checkInput: illegal input: " ++ show u)
    else u

-- * Accessors

-- | Value of 'Constant_U' 'Constant'.
u_constant :: UGen -> Double
u_constant u =
    case u of
      Constant_U (Constant n) -> n
      _ -> error "u_constant"

-- * Constructors

-- | Constant value node constructor.
constant :: (Real a) => a -> UGen
constant = Constant_U . Constant . realToFrac

-- | Multiple channel expansion node constructor.
mce :: [UGen] -> UGen
mce xs =
    case xs of
      [] -> error "mce: empty list"
      [x] -> x
      _ -> MCE_U (MCE xs)

-- | Multiple root graph constructor.
mrg :: [UGen] -> UGen
mrg u =
    case u of
      [] -> error "mrg: null"
      [x] -> x
      (x:xs) -> MRG_U (MRG x (mrg xs))

-- | Unit generator proxy node constructor.
proxy :: UGen -> Int -> UGen
proxy u n =
    case u of
      Primitive_U p -> Proxy_U (Proxy p n)
      _ -> error "proxy"

-- * MCE

-- | Multiple channel expansion node ('MCE_U') predicate.
isMCE :: UGen -> Bool
isMCE u =
    case u of
      MCE_U _ -> True
      _ -> False

-- | Output channels of UGen as a list.
mceChannels :: UGen -> [UGen]
mceChannels u =
    case u of
      MCE_U (MCE l) -> l
      MRG_U (MRG x y) -> let r:rs = mceChannels x in MRG_U (MRG r y) : rs
      _ -> [u]

-- | Number of channels to expand to.
mceDegree :: UGen -> Int
mceDegree u =
    case u of
      MCE_U (MCE l) -> length l
      MRG_U (MRG x _) -> mceDegree x
      _ -> error "mceDegree: illegal ugen"

-- | Extend UGen to specified degree.
mceExtend :: Int -> UGen -> [UGen]
mceExtend n u =
    case u of
      MCE_U (MCE l) -> take n (cycle l)
      MRG_U (MRG x y) -> let (r:rs) = mceExtend n x
                         in MRG_U (MRG r y) : rs
      _ -> replicate n u

-- | Apply MCE transform to a list of inputs.
mceInputTransform :: [UGen] -> Maybe [[UGen]]
mceInputTransform i =
    if any isMCE i
    then let n = maximum (map mceDegree (filter isMCE i))
         in Just (transpose (map (mceExtend n) i))
    else Nothing

-- | Build a UGen after MCE transformation of inputs.
mceBuild :: ([UGen] -> UGen) -> [UGen] -> UGen
mceBuild f i =
    case mceInputTransform i of
      Nothing -> f i
      Just i' -> MCE_U (MCE (map (mceBuild f) i'))

-- | Determine the rate of a UGen.
rateOf :: UGen -> Rate
rateOf u =
    case u of
      Constant_U _ -> IR
      Control_U c -> controlOperatingRate c
      Label_U _ -> IR
      Primitive_U p -> ugenRate p
      Proxy_U p -> ugenRate (proxySource p)
      MCE_U _ -> maximum (map rateOf (mceChannels u))
      MRG_U m -> rateOf (mrgLeft m)

-- | Apply proxy transformation if required.
proxify :: UGen -> UGen
proxify u =
    case u of
      MCE_U m -> mce (map proxify (mceProxies m))
      MRG_U m -> mrg [proxify (mrgLeft m), mrgRight m]
      Primitive_U p ->
          let o = ugenOutputs p
          in case o of
               (_:_:_) -> mce (map (proxy u) [0..(length o - 1)])
               _ -> u
      Constant_U _ -> u
      _ -> error "proxify: illegal ugen"

-- | Construct proxied and multiple channel expanded UGen.
mkUGen :: Maybe ([Double] -> Double) -> [Rate] -> Maybe Rate ->
          String -> [UGen] -> Int -> Special -> UGenId -> UGen
mkUGen cf rs r nm i o s z =
    let f h = let r' = fromMaybe (maximum (map rateOf h)) r
                  o' = replicate o r'
                  u = Primitive_U (Primitive r' nm h o' s z)
              in if r' `elem` rs
                 then case cf of
                        Just cf' ->
                            if all isConstant h
                            then constant (cf' (map u_constant h))
                            else u
                        Nothing -> u
                 else error ("mkUGen: rate restricted: " ++ show (r,rs,nm))
    in proxify (mceBuild f (map checkInput i))

-- * Operators

-- | Operator UGen constructor.
mkOperator :: ([Double] -> Double) -> String -> [UGen] -> Int -> UGen
mkOperator f c i s =
    mkUGen (Just f) all_rates Nothing c i 1 (Special s) NoId

-- | Unary math constructor with constant optimization.
mkUnaryOperator :: Unary -> (Double -> Double) -> UGen -> UGen
mkUnaryOperator i f a =
    let g [x] = f x
        g _ = error "mkUnaryOperator: non unary input"
    in mkOperator g "UnaryOpUGen" [a] (fromEnum i)

-- | Binary math constructor with constant optimization.
--
-- > let o = sinOsc AR 440 0
--
-- > o * 1 == o && 1 * o == o && o * 2 /= o
-- > o + 0 == o && 0 + o == o && o + 1 /= o
-- > o - 0 == o && 0 - o /= o
-- > o / 1 == o && 1 / o /= o
-- > o ** 1 == o && o ** 2 /= o
mkBinaryOperator_optimize :: Binary -> (Double -> Double -> Double) ->
                             (Either Double Double -> Bool) ->
                             UGen -> UGen -> UGen
mkBinaryOperator_optimize i f o a b =
   let g [x,y] = f x y
       g _ = error "mkBinaryOperator: non binary input"
       r = case (a,b) of
             (Constant_U (Constant a'),_) ->
                 if o (Left a') then Just b else Nothing
             (_,Constant_U (Constant b')) ->
                 if o (Right b') then Just a else Nothing
             _ -> Nothing
   in maybe (mkOperator g "BinaryOpUGen" [a, b] (fromEnum i)) id r

-- | Binary math constructor with constant optimization.
mkBinaryOperator :: Binary -> (Double -> Double -> Double) ->
                    UGen -> UGen -> UGen
mkBinaryOperator i f a b =
   let g [x,y] = f x y
       g _ = error "mkBinaryOperator: non binary input"
   in mkOperator g "BinaryOpUGen" [a, b] (fromEnum i)

-- * Numeric instances

-- | Unit generators are numbers.
instance Num UGen where
    negate = mkUnaryOperator Neg negate
    (+) = mkBinaryOperator_optimize Add (+) (`elem` [Left 0,Right 0])
    (-) = mkBinaryOperator_optimize Sub (-) ((==) (Right 0))
    (*) = mkBinaryOperator_optimize Mul (*) (`elem` [Left 1,Right 1])
    abs = mkUnaryOperator Abs abs
    signum = mkUnaryOperator Sign signum
    fromInteger = Constant_U . Constant . fromInteger

-- | Unit generators are fractional.
instance Fractional UGen where
    recip = mkUnaryOperator Recip recip
    (/) = mkBinaryOperator_optimize FDiv (/) ((==) (Right 1))
    fromRational = Constant_U . Constant . fromRational

-- | Unit generators are floating point.
instance Floating UGen where
    pi = Constant_U (Constant pi)
    exp = mkUnaryOperator Exp exp
    log = mkUnaryOperator Log log
    sqrt = mkUnaryOperator Sqrt sqrt
    (**) = mkBinaryOperator_optimize Pow (**) ((==) (Right 1))
    logBase a b = log b / log a
    sin = mkUnaryOperator Sin sin
    cos = mkUnaryOperator Cos cos
    tan = mkUnaryOperator Tan tan
    asin = mkUnaryOperator ArcSin asin
    acos = mkUnaryOperator ArcCos acos
    atan = mkUnaryOperator ArcTan atan
    sinh = mkUnaryOperator SinH sinh
    cosh = mkUnaryOperator CosH cosh
    tanh = mkUnaryOperator TanH tanh
    asinh x = log (sqrt (x*x+1) + x)
    acosh x = log (sqrt (x*x-1) + x)
    atanh x = (log (1+x) - log (1-x)) / 2

-- | Unit generators are real.
instance Real UGen where
    toRational (Constant_U (Constant n)) = toRational n
    toRational _ = error "toRational at non-constant UGen"

-- | Unit generators are integral.
instance Integral UGen where
    quot = mkBinaryOperator IDiv (error "ugen: quot")
    rem = mkBinaryOperator Mod (error "ugen: rem")
    quotRem a b = (quot a b, rem a b)
    div = mkBinaryOperator IDiv (error "ugen: div")
    mod = mkBinaryOperator Mod (error "ugen: mod")
    toInteger (Constant_U (Constant n)) = floor n
    toInteger _ = error "toInteger at non-constant UGen"

-- | Unit generators are orderable (when 'Constants').
--
-- > (constant 2 > constant 1) == True
instance Ord UGen where
    (Constant_U a) < (Constant_U b) = a < b
    _ < _ = error "< at UGen is partial, see <*"
    (Constant_U a) <= (Constant_U b) = a <= b
    _ <= _ = error "<= at UGen is partial, see <=*"
    (Constant_U a) > (Constant_U b) = a > b
    _ > _ = error "> at UGen is partial, see >*"
    (Constant_U a) >= (Constant_U b) = a >= b
    _ >= _ = error ">= at UGen is partial, see >=*"
    min = mkBinaryOperator Min min
    max = mkBinaryOperator Max max

-- | Unit generators are enumerable.
instance Enum UGen where
    succ u = u + 1
    pred u = u - 1
    toEnum n = Constant_U (Constant (fromIntegral n))
    fromEnum (Constant_U (Constant n)) = truncate n
    fromEnum _ = error "cannot enumerate non-constant UGens"
    enumFrom = iterate (+1)
    enumFromThen n m = iterate (+(m-n)) n
    enumFromTo n m = takeWhile (<= m+1/2) (enumFrom n)
    enumFromThenTo n n' m =
        let p = if n' >= n then (>=) else (<=)
        in takeWhile (p (m + (n'-n)/2)) (enumFromThen n n')

-- | Unit generators are stochastic.
instance Random UGen where
    randomR (Constant_U (Constant l),Constant_U (Constant r)) g =
        let (n, g') = randomR (l,r) g
        in (Constant_U (Constant n), g')
    randomR _ _ = error "randomR: non constant (l,r)"
    random = randomR (-1.0, 1.0)

-- | UGens are bit patterns.
instance Bits UGen where
    (.&.) = mkBinaryOperator BitAnd undefined
    (.|.) = mkBinaryOperator BitOr undefined
    xor = mkBinaryOperator BitXor undefined
    complement = mkUnaryOperator BitNot undefined
    shift = error "Bits/UGen is partial"
    rotate = error "Bits/UGen is partial"
    bitSize = error "Bits/UGen is partial"
    isSigned _ = True

-- * UGen ID Instance

-- | Hash function for unit generators.
hashUGen :: UGen -> Int
hashUGen = hash . show

instance ID UGen where
    resolveID = hashUGen