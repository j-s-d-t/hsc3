-- | Decode a binary 'Graph Definition'.
module Sound.SC3.Server.Synthdef.Read where

import Control.Monad {- base -}
import qualified Data.ByteString.Lazy as L {- bytestring -}
import qualified Data.ByteString.Char8 as C {- bytestring -}
import System.IO {- base -}

import Sound.OSC.Coding.Byte {- hosc -}
import Sound.OSC.Type {- hosc -}

read_i8 :: Handle -> IO Int
read_i8 h = fmap decode_i8 (L.hGet h 1)

read_i16 :: Handle -> IO Int
read_i16 h = fmap decode_i16 (L.hGet h 2)

read_i32 :: Handle -> IO Int
read_i32 h = fmap decode_i32 (L.hGet h 4)

read_f32 :: Handle -> IO Float
read_f32 h = fmap decode_f32 (L.hGet h 4)

read_pstr :: Handle -> IO ASCII
read_pstr h = do
  n <- fmap decode_u8 (L.hGet h 1)
  fmap decode_str (L.hGet h n)

ascii_to_string :: ASCII -> String
ascii_to_string = C.unpack

type Name = ASCII
type Control = (Name,Int)

read_control :: Handle -> IO Control
read_control h = do
  nm <- read_pstr h
  ix <- read_i16 h
  return (nm,ix)

type Input = (Int,Int)

input_ugen_ix :: Input -> Maybe Int
input_ugen_ix (u,p) = if p == -1 then Nothing else Just u

read_input :: Handle -> IO Input
read_input h = do
  u <- read_i16 h
  p <- read_i16 h
  return (u,p)

type Output = Int

read_output :: Handle -> IO Int
read_output = read_i8

type Rate = Int

type Special = Int

type UGen = (Name,Rate,[Input],[Output],Special)

ugen_inputs :: UGen -> [Input]
ugen_inputs (_,_,i,_,_) = i

read_ugen :: Handle -> IO UGen
read_ugen h = do
  name <- read_pstr h
  rate <- read_i8 h
  number_of_inputs <- read_i16 h
  number_of_outputs <- read_i16 h
  special <- read_i16 h
  inputs <- replicateM number_of_inputs (read_input h)
  outputs <- replicateM number_of_outputs (read_output h)
  return (name
         ,rate
         ,inputs
         ,outputs
         ,special)

type GraphDef = (Name, [Float], [Float], [Control], [UGen])

read_graphdef :: Handle -> IO GraphDef
read_graphdef h = do
  magic <- L.hGet h 4
  version <- read_i32 h
  number_of_definitions <- read_i16 h
  when (magic /= L.pack (map (fromIntegral . fromEnum) "SCgf"))
       (error "read_graphdef: illegal magic string")
  when (version /= 0)
       (error "read_graphdef: version not at zero")
  when (number_of_definitions /= 1)
       (error "read_graphdef: non unary graphdef file")
  name <- read_pstr h
  number_of_constants <- read_i16 h
  constants <- replicateM number_of_constants (read_f32 h)
  number_of_control_defaults <- read_i16 h
  control_defaults <- replicateM number_of_control_defaults (read_f32 h)
  number_of_controls <- read_i16 h
  controls <- replicateM number_of_controls (read_control h)
  number_of_ugens <- read_i16 h
  ugens <- replicateM number_of_ugens (read_ugen h)
  return (name
         ,constants
         ,control_defaults
         ,controls
         ,ugens)

-- > read_graphdef_file "/home/rohan/sw/rsc3-disassembler/scsyndef/simple.scsyndef"
-- > g <- read_graphdef_file "/home/rohan/sw/rsc3-disassembler/scsyndef/with-ctl.scsyndef"
-- > read_graphdef_file "/home/rohan/sw/rsc3-disassembler/scsyndef/mce.scsyndef"
-- > g <- read_graphdef_file "/home/rohan/sw/rsc3-disassembler/scsyndef/mrg.scsyndef"
read_graphdef_file :: FilePath -> IO GraphDef
read_graphdef_file nm = do
  h <- openFile nm ReadMode
  g <- read_graphdef h
  hClose h
  return g
