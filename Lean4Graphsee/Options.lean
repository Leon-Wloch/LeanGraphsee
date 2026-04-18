module

import Lean
public import Lean.Data.Options

register_option Kripke.showGraph : Bool := {
  defValue := false
  descr := "Show the graph in the Lean InfoView"
}
