module

import Lean
public import Lean.Data.Options

register_option graphsee.showGraph : Bool := {
  defValue := true
  descr := "Enable the Graph Display"
}

register_option graphsee.showGoal : Bool := {
  defValue := true
  descr := "Enable visualisation of the goal in the form of a dashed arrow"

}

register_option graphsee.edgeColours : String := {
  defValue := "default"
  descr := "Colour palette for relation edges (options: default, grayscale, colourblind, vibrant)"
}

register_option graphsee.edgeLength : Nat := {
  defValue := 125
  descr := "Length of edges in pixels"
}

register_option graphsee.edgeThickness : Nat := {
  defValue := 2
  descr := "Thickness of edges in pixels"
}

register_option graphsee.edgeFontSize : Nat := {
  defValue := 11
  descr := "Font size for edge labels in pixels"
}

register_option graphsee.vertexRadius : Nat := {
  defValue := 12
  descr := "Radius of vertex circles in pixels"
}

register_option graphsee.vertexFontSize : Nat := {
  defValue := 11
  descr := "Font size for vertex labels in pixels"
}

register_option graphsee.atomicPropsFontSize : Nat := {
  defValue := 11
  descr := "Font size for atomic propositions inside vertices in pixels"
}
