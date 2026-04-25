module

import Lean

public meta section

-- Palettes for relation edges

-- This palette was taken from https://sashamaps.net/docs/resources/20-colors/
def defaultPalette : Array String := #[
  "#e6194b", -- Red
  "#3cb44b", -- Green
  "#ffe119", -- Yellow
  "#4363d8", -- Blue
  "#f58231", -- Orange
  "#911eb4" -- Purple
]

-- This palette was taken from https://www.figma.com/color-palettes/monochromatic/
def grayscalePalette : Array String := #[
  "#918D8A",
  "#E8E8E6",
  "#636261",
  "#ADADAD",
  "#464243",
  "#C5C2BE"
]

-- This palette was taken from https://mk.bcgsc.ca/colorblind/palettes.mhtml
def colourblindPalette : Array String := #[
  "#2271B2", -- Honolulu Blue
  "#F748A5", -- Barbie Pink
  "359B73", -- Ocean Green
  "D55E00", -- Bamboo
  "3DB7E9", -- Summer Sky
  "E69F00" -- Gamboge
]

-- This palette was taken from https://www.schemecolor.com/stunning-bright-color-scheme.php
def vibrantPalette : Array String := #[
  "#66FF00", -- Bright Lime
  "#b000ff", --Bright Purple
  "#08E8DE", -- Bright Cyan
  "#FFF000", -- Bright Yellow
  "#FFAA1D", -- Bright Orange
  "#FF007F" -- Bright Pink
]

def getPalette (paletteName : String) : Array String :=
  match paletteName with
  | "grayscale" => grayscalePalette
  | "greyscale" => grayscalePalette
  | "colourblind" => colourblindPalette
  | "colorblind" => colourblindPalette
  | "vibrant" => vibrantPalette
  | _ => defaultPalette
