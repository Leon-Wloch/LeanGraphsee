import Lean4Graphsee.experiment2

set_option linter.unusedVariables false

set_option Kripke.showGraph true

-- Simple example
example (w1 w2 w3 : W)
  (R : W → W → Prop)
  (h1 : R w1 w2)
  (h2 : R w2 w3) : True := by
  have h3 : R w1 w3 := by sorry
  trivial

-- Simple example
example (w1 w2 w3 : W)
  (R : W → W → Prop)
  (h1 : R w1 w2)
  (h2 : R w2 w3)
  (h3 : R w1 w3) : True := by
  trivial

-- Simple example
example (w1 w2 w3 : W)
  (R : W → W → Prop)
   : True := by
  trivial

-- Multiple relations example
example (w1 w2 w3 : W)
  (R1 : W → W → Prop)
  (R2: W → W → Prop)
  (h1 : R1 w1 w2)
  (h2 : R2 w1 w3) : True := by

  trivial

-- Example with relations with different worldtypes
example (w1 w2 : W) (s1 s2 : S)
  (R : W → W → Prop)
  (R2 : S → S → Prop)
  (h1 : R w1 w2)
  (h2 : R2 s1 s2) : True := by
  trivial

-- Example with function
theorem otherExample
  (W : Type)
  (n : Nat → W)
  (R : W → W → Prop)
  (h2 : R (n 1) (n 2))
  (h3 : R (n 2) (n 25))
  : True := by

  sorry
