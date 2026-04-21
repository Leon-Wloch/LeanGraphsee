module

public meta import ProofWidgets.Component.GraphDisplay
public meta import Lean4Graphsee.Options
public meta import Lean4Graphsee.Colours

public meta section

open Lean Meta ProofWidgets Jsx

structure relationInstance where
  relationName : String
  source : String
  target : String
  colour : String
  deriving Inhabited

-- Check if an expression is of the form T → T → Prop.
def isRelationType (e : Expr) : MetaM (Option Expr) := do
  match e with
  | .forallE _ t1 (.forallE _ t2 (.sort .zero) _) _ =>
    if ← isDefEq t1 t2 then
      return some t1
    else
      return none
  | _ => return none

-- Helper function defined in Lean4Graphsee.Colours to fetch edge colour palette
def getCurrentColourPalette : MetaM (Array String) := do
  let options ← getOptions
  let paletteName := options.get `Kripke.edgeColours "default"
  return getPalette paletteName

def findRelationsAndWorlds (lctx : LocalContext) : MetaM (Std.HashSet String × Array relationInstance) := do
  let mut worlds : Std.HashSet String := {}
  let mut relationInstances := #[]
  -- Hashmap for colouring identical relations the same colour
  let mut relationColours : Std.HashMap String String := {}
  let mut nextColourIdx : Nat := 0
  let edgeColourPalette ← getCurrentColourPalette

  for decl in lctx do
    match decl.type with
    | .app (.app r w1) w2 =>
      if let some _ ← isRelationType (← inferType r) then
        let relationName := toString (← ppExpr r)

        let colour ← match relationColours.get? relationName with
          | some col => pure col
          | none =>
            let col := edgeColourPalette[nextColourIdx % edgeColourPalette.size]!
            relationColours := relationColours.insert relationName col
            nextColourIdx := nextColourIdx + 1
            pure col

        let w1str := toString (← ppExpr w1)
        let w2str := toString (← ppExpr w2)

        relationInstances := relationInstances.push {
          relationName := relationName
          source := w1str
          target := w2str
          colour := colour
        }
        worlds := worlds.insert w1str
        worlds := worlds.insert w2str
    | _ => pure ()
  return (worlds, relationInstances)

def createGraphDisplayVertices (worlds : Std.HashSet String) : Array GraphDisplay.Vertex :=
  worlds.toArray.map (fun worldName => {
    id := worldName
    label := <g>
      <circle
      r="6"
      fill="var(--vscode-editor-background)"
      stroke="var(--vscode-editor-foreground)"
      strokeWidth="1.5"/>
      <text
        fontSize="10"
        fill="var(--vscode-editor-foreground)"
        textAnchor="start"
        x="10"
        dy="0.3em"
        fontFamily="monospace">
      {Html.text worldName}
      </text>
    </g>
    boundingShape := .circle 6
  })

def createGraphDisplayEdges (edges : Array relationInstance) : Array GraphDisplay.Edge :=
  edges.map (fun relInst => {
    source := relInst.source,
    target := relInst.target,
    label? := <text
      fontSize="10"
      fill="#FFF"
      textAnchor="middle"
      dy="-4"
    >
    {Html.text relInst.relationName}
    </text>,
    attrs := #[
      ("stroke", relInst.colour)
    ]
  }
  )

-- Build the Kripke frame graph from the local context.
def drawKripkeGraph (lctx : LocalContext) : MetaM Html := do
  -- Find all worlds and relation instances
  let (worlds, relations) ← findRelationsAndWorlds lctx

  if relations.isEmpty then
    return <span>No relation of the form R: T → T → Prop found.</span>

  -- Creating GraphDisplay vertices and edges from words and relations.
  let vertices : Array GraphDisplay.Vertex := createGraphDisplayVertices worlds
  let edges : Array GraphDisplay.Edge := createGraphDisplayEdges relations

  -- Making edges longer and adjusting forces accordingly
  let forces : Array GraphDisplay.ForceParams := #[
    .link {
      distance? := some 125,
      strength? := some 0.1,
      iterations? := some 1
    },
    .manyBody {
      strength? := some (-100)
    },
    .x {
      strength? := some 0.01
    },
    .y {
      strength? := some 0.01
    }
  ]

  return <GraphDisplay
    vertices={vertices}
    edges={edges}
    forces={forces}
    showDetails={false}
  />
