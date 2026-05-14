module

import Lean
public import Lean.Data.Options

register_option Graphsee.showGraph : Bool := {
  defValue := true
  descr := "Enable the Graph Display"
}

register_option Graphsee.showGoal : Bool := {
  defValue := true
  descr := "Enable visualisation of the goal in the form of a dashed arrow"

}

register_option Graphsee.edgeColours : String := {
  defValue := "default"
  descr := "Colour palette for relation edges (options: default, grayscale, colourblind, vibrant)"
}

register_option Graphsee.edgeLength : Nat := {
  defValue := 125
  descr := "Length of edges in pixels"
}

register_option Graphsee.edgeThickness : Nat := {
  defValue := 2
  descr := "Thickness of edges in pixels"
}

register_option Graphsee.edgeFontSize : Nat := {
  defValue := 11
  descr := "Font size for edge labels in pixels"
}

register_option Graphsee.vertexRadius : Nat := {
  defValue := 12
  descr := "Radius of vertex circles in pixels"
}

register_option Graphsee.vertexFontSize : Nat := {
  defValue := 11
  descr := "Font size for vertex labels in pixels"
}

register_option Graphsee.atomicPropsFontSize : Nat := {
  defValue := 11
  descr := "Font size for atomic propositions inside vertices"
}
