module

public meta import ProofWidgets.Component.GraphDisplay
public meta import Lean4Graphsee.Options
public meta import Lean4Graphsee.Colours

public meta section

open Lean Meta ProofWidgets Jsx

structure OptionsConfig where
  showGraph : Bool
  edgeColours : Array String
  edgeLength : Nat
  edgeThickness : Nat
  edgeFontSize : Nat
  vertexRadius : Nat
  vertexFontSize : Nat

def getOptionsConfig : MetaM OptionsConfig := do
  let options ← getOptions
  let paletteName := options.get `Kripke.edgeColours "default"
  return {
    showGraph := options.getBool `Kripke.showGraph
    edgeColours := getPalette (paletteName)
    edgeLength := options.get `Kripke.edgeLength 125
    edgeThickness := options.get `Kripke.edgeThickness 2
    edgeFontSize := options.get `Kripke.edgeFontSize 10
    vertexRadius := options.get `Kripke.vertexRadius 6
    vertexFontSize := options.get `Kripke.vertexFontSize 10
  }

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


def findRelationsAndWorlds (lctx : LocalContext) (optionsConfig: OptionsConfig) : MetaM (Std.HashSet String × Array relationInstance) := do
  let mut worlds : Std.HashSet String := {}
  let mut relationInstances := #[]
  -- Hashmap for colouring identical relations the same colour
  let mut relationColours : Std.HashMap String String := {}
  let mut nextColourIdx : Nat := 0
  let edgeColourPalette := optionsConfig.edgeColours

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

def createGraphDisplayVertices (worlds : Std.HashSet String) (optionsConfig : OptionsConfig): Array GraphDisplay.Vertex :=
  worlds.toArray.map (fun worldName => {
    id := worldName
    label := <g>
      <circle
      r={toString optionsConfig.vertexRadius}
      fill="var(--vscode-editor-background)"
      stroke="var(--vscode-editor-foreground)"
      strokeWidth="1.5"/>
      <text
        fontSize={toString optionsConfig.vertexFontSize}
        fill="var(--vscode-editor-foreground)"
        textAnchor="start"
        x={toString (optionsConfig.vertexRadius)}
        dy={toString (-(optionsConfig.vertexRadius / 2).toInt64)}
        fontFamily="monospace">
      {Html.text worldName}
      </text>
    </g>
    boundingShape := .circle optionsConfig.vertexRadius.toFloat
  })

def createGraphDisplayEdges (edges : Array relationInstance) (optionsConfig : OptionsConfig): Array GraphDisplay.Edge :=
  edges.map (fun relInst => {
    source := relInst.source,
    target := relInst.target,
    label? := <text
      fontSize={toString optionsConfig.edgeFontSize}
      fill="#FFF"
      textAnchor="middle"
      dy="-4"
    >
    {Html.text relInst.relationName}
    </text>,
    attrs := #[
      ("stroke", relInst.colour),
      ("stroke-width", toString optionsConfig.edgeThickness)
    ]
  }
  )

-- Build the Kripke frame graph from the local context.
def drawKripkeGraph (lctx : LocalContext) : MetaM Html := do
  let optionsConfig ← getOptionsConfig

  -- Find all worlds and relation instances
  let (worlds, relations) ← findRelationsAndWorlds lctx optionsConfig

  if relations.isEmpty then
    return <span>No relation of the form R : T → T → Prop found.</span>

  -- Creating GraphDisplay vertices and edges from words and relations.
  let vertices : Array GraphDisplay.Vertex := createGraphDisplayVertices worlds optionsConfig
  let edges : Array GraphDisplay.Edge := createGraphDisplayEdges relations optionsConfig

  -- Making edges longer and adjusting forces accordingly
  let forces : Array GraphDisplay.ForceParams := #[
    .link {
      distance? := some optionsConfig.edgeLength.toFloat,
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
