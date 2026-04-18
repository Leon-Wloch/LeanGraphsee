module

import Lean

public meta section

-- Palettes for relation edges

-- This list of colours was taken from https://sashamaps.net/docs/resources/20-colors/
def defaultPalette : Array String := #[
  "#e6194b", -- Red
  "#3cb44b", -- Green
  "#ffe119", -- Yellow
  "#4363d8", -- Blue
  "#f58231", -- Orange
  "#911eb4", -- Purple
]

def getPalette (paletteName : String) : Array String :=
  match paletteName with
  | _ => defaultPalette
