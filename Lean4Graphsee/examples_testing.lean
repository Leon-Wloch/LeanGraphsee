module

import Lean4Graphsee.experiment2

set_option linter.unusedVariables false

set_option Kripke.showGraph true

example (w1 w2 w3 : W)
  (R : W → W → Prop)
  (h1 : R w1 w2)
(h2 : R w2 w3) : True := by
  have h3 : R w1 w3 := by sorry


  trivial

example (w1 w2 w3 : W)
  (R : W → W → Prop)
  (h1 : R w1 w2)
  (h2 : R w1 w3) : True := by

  trivial

example (w1 w2 w3 : W)
  (R : W → W → Prop)
  (h1 : R w1 w2)
  (h2 : R w2 w3)
  (h3 : R w1 w3) : True := by

  trivial

example (w1 w2 w3 : W)
  (R : W → W → Prop)
   : True := by

  trivial

theorem otherExample
  (W : Type)
  (n : Nat → W)
  (R : W → W → Prop)
  (h2 : R (n 1) (n 2))
  (h3 : R (n 2) (n 25))
  : True := by

  sorry
