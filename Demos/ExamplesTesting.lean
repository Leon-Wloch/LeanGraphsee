import Graphsee

set_option linter.unusedVariables false

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

set_option Graphsee.edgeColours "vibrant"

-- Simple example
example (w1 w2 w3 : W)
  (R : W → W → Prop)
   : True := by
  trivial

example (w1 w2 w3 : W)
  (R : W → W → Prop)
  (h : R a a2)
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

-- Example for visualising the goal using dashed arrow
theorem goalExample
  (W : Type) (v w u : W) (R : W → W → Prop)
  (h1 : R v w)
  (h2 : R w u)
  : R v u := by
  -- show a dashed line from v to u in this case?
  sorry

-- Example with function
theorem otherExample
  (W : Type)
  (n : Nat → W)
  (R : W → W → Prop)
  (h2 : R (n 1) (n 2))
  (h3 : R (n 2) (n 25))
  : True := by

  sorry

-- Dynamic tactic example
theorem otherExample2
  (W : Type)
  (n : Nat → W)
  (R : W → W → Prop)
  (h1 : R (n 1) (n 2))
  (h2 : R (n 2) (n 25))
  (h3 : R (n 1) (n (5*5)))
  : False := by
  simp at *
  sorry

-- Example for valuation function/atomic propositions
theorem annotationExample
  (W : Type) (v w u : W) (R : W → W → Prop)
  (h1 : R v w)
  (h2 : R v u)
  (isNice : W → Prop)
  (isNotNice : W → Prop)
  (v_nice : isNice v)
  (v_not_nice : isNotNice w)
  : ∃ x, R v x ∧ isNice x := by
  -- also show "isNice" inside node `v` in this case?
  sorry

-- Example with agents (currently doesn't work as R isn't in form T → T → Prop)
theorem agentsExample
  (W Agent : Type)
  (w v u : W)
  (R : Agent → W → W → Prop)
  (a b : Agent)
  (h1 : R a v w)
  (h2 : R b w u)
  : False := by
  sorry
