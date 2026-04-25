module

import Lean
public import Lean.Data.Options

register_option Kripke.showGraph : Bool := {
  defValue := true
  descr := "Enable the Graph Display"
}

register_option Kripke.edgeColours : String := {
  defValue := "default"
  descr := "Colour palette for relation edges (options: default, grayscale, colourblind, vibrant)"
}

register_option Kripke.edgeLength : Nat := {
  defValue := 125
  descr := "Length of edges in pixels"
}

register_option Kripke.edgeThickness : Nat := {
  defValue := 2
  descr := "Thickness of edges in pixels"
}

register_option Kripke.edgeFontSize : Nat := {
  defValue := 11
  descr := "Font size for edge labels in pixels"
}

register_option Kripke.vertexRadius : Nat := {
  defValue := 12
  descr := "Radius of vertex circles in pixels"
}

register_option Kripke.vertexFontSize : Nat := {
  defValue := 11
  descr := "Font size for vertex labels in pixels"
}
