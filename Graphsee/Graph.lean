module

public meta import ProofWidgets.Component.GraphDisplay
public meta import Graphsee.Options
public meta import Graphsee.Colours

public meta section

open Lean Meta ProofWidgets Jsx

structure GraphOptionsConfig where
  showGoal : Bool
  showHeteroRelations : Bool
  edgeColours : Array String
  edgeLength : Nat
  edgeThickness : Nat
  edgeFontSize : Nat
  vertexRadius : Nat
  vertexFontSize : Nat
  atomicPropsFontSize : Nat

-- Fetch the graph options config set by the user. The default options are defined here.
def getGraphOptionsConfig : MetaM GraphOptionsConfig := do
  let options ← getOptions
  let paletteName := options.get `graphsee.edgeColours "default"
  return {
    showGoal := options.getBool `graphsee.showGoal true
    showHeteroRelations := options.getBool `graphsee.showHeteroRelations false
    edgeColours := getPalette (paletteName)
    edgeLength := options.get `graphsee.edgeLength 125
    edgeThickness := options.get `graphsee.edgeThickness 2
    edgeFontSize := options.get `graphsee.edgeFontSize 11
    vertexRadius := options.get `graphsee.vertexRadius 12
    vertexFontSize := options.get `graphsee.vertexFontSize 11
    atomicPropsFontSize := options.get `graphsee.atomicPropsFontSize 11
  }

structure worldInstance where
  worldName : String
  atomicProps : List String

structure relationInstance where
  relationName : String
  source : String
  target : String
  colour : String
  isGoal : Bool

-- Check if an expression is of the form T → T → Prop.
def isRelationType (e : Expr) (graphOptionsConfig: GraphOptionsConfig) : MetaM Bool := do
  match e with
  | .forallE _ t1 (.forallE _ t2 (.sort .zero) _) _ =>
    if graphOptionsConfig.showHeteroRelations then
      return true
    else
      return ← isDefEq t1 t2
  | _ => return false

-- Check if an expression is of the form T → Prop.
def isAtomicPropType (e : Expr) : MetaM Bool := do
  match e with
  | .forallE _ _ (.sort .zero) _ => return true
  | _ => return false


def findRelationsAndWorlds (lctx : LocalContext) (goalType : Expr) (graphOptionsConfig: GraphOptionsConfig) : MetaM (Array worldInstance × Array relationInstance) := do
  -- We include the worldName alongside the worldInstance for quicker lookup
  let mut worlds : Std.HashMap String worldInstance := {}
  let mut relationInstances := #[]
  -- Hashmap for colouring identical relations the same colour
  let mut relationColours : Std.HashMap String String := {}
  let mut nextColourIdx : Nat := 0
  let edgeColourPalette := graphOptionsConfig.edgeColours

  for decl in lctx do
    match decl.type with
    | .app (.app r w1) w2 =>
      if ← isRelationType (← inferType r) graphOptionsConfig then
        let relationName := toString (← ppExpr r)

        let colour ← match relationColours.get? relationName with
          | some col => pure col
          | none =>
            let col := edgeColourPalette[nextColourIdx % edgeColourPalette.size]!
            relationColours := relationColours.insert relationName col
            nextColourIdx := nextColourIdx + 1
            pure col

        let w1Name := toString (← ppExpr w1)
        let w2Name := toString (← ppExpr w2)

        if !worlds.contains w1Name then
          worlds := worlds.insert w1Name { worldName := w1Name, atomicProps := [] }
        if !worlds.contains w2Name then
          worlds := worlds.insert w2Name { worldName := w2Name, atomicProps := [] }

        relationInstances := relationInstances.push {
          relationName := relationName
          source := w1Name
          target := w2Name
          colour := colour
          isGoal := False
        }
    | .app p w =>
      let pType ← inferType p
      if ← isAtomicPropType pType then
        let propName := toString (← ppExpr p)
        let worldName := toString (← ppExpr w)
        let existing : worldInstance := worlds.getD worldName {worldName := worldName, atomicProps := []}
        let updated := { existing with atomicProps := existing.atomicProps ++ [propName] }
        worlds := worlds.insert worldName updated
    | _ => pure ()

  -- Next we check if the goal is in the form of a relation, and if it is,
  -- we visualise it as a dashed arrow
  if graphOptionsConfig.showGoal then
    match goalType with
    | .app (.app r w1) w2 =>
      if ← isRelationType (← inferType r) graphOptionsConfig then
        let relationName := toString (← ppExpr r)
        let colour ← match relationColours.get? relationName with
          | some col => pure col
          | none =>
            let col := edgeColourPalette[nextColourIdx % edgeColourPalette.size]!
            pure col
        let w1Name := toString (← ppExpr w1)
        let w2Name := toString (← ppExpr w2)
        relationInstances := relationInstances.push {
          relationName := relationName
          source := w1Name
          target := w2Name
          colour := colour
          isGoal := True
        }
        if !worlds.contains w1Name then
          worlds := worlds.insert w1Name { worldName := w1Name, atomicProps := [] }
        if !worlds.contains w2Name then
          worlds := worlds.insert w2Name { worldName := w2Name, atomicProps := [] }
    | _ => pure ()
  let worldInstances := worlds.toArray.map (·.2)
  return (worldInstances, relationInstances)

-- Finds the maximum circle radius needed to fit the atomic propositions of the world with
-- the most atomic propositions that take up the most space
def computeMaxVertexRadius (worlds : Array worldInstance) (graphOptionsConfig : GraphOptionsConfig) : Nat :=
  worlds.foldl
    (fun acc worldInstance =>
      let propsText := String.intercalate ", " worldInstance.atomicProps
       -- Approximate text width using monospace character width (0.6 * fontSize per character)
      let charsWidth := propsText.length * graphOptionsConfig.vertexFontSize * 6 / 10
      let r := if worldInstance.atomicProps.isEmpty
        then graphOptionsConfig.vertexRadius
        -- Radius must be at least half the text width (since text is centered), with padding
        else Nat.max graphOptionsConfig.vertexRadius (charsWidth / 2 + 4)
      Nat.max acc r)
    -- Start with the default vertex radius as floor
    graphOptionsConfig.vertexRadius

def createGraphDisplayVertices (worlds : Array worldInstance) (graphOptionsConfig : GraphOptionsConfig): Array GraphDisplay.Vertex :=
  let vertexRadius := computeMaxVertexRadius worlds graphOptionsConfig
  worlds.map (fun worldInstance =>
    let propsText := String.intercalate ", " worldInstance.atomicProps
    {
    id := worldInstance.worldName
    label := <g>
      <circle
        r={toString vertexRadius}
        fill="var(--vscode-editor-background)"
        stroke="var(--vscode-editor-foreground)"
        strokeWidth="1.5"/>
      <text
        fontSize={toString graphOptionsConfig.vertexFontSize}
        fill="var(--vscode-editor-foreground)"
        stroke="var(--vscode-editor-background)"
        strokeWidth="2"
        paintOrder="stroke"
        textAnchor="start"
        x={toString (vertexRadius)}
        dy={toString (-(vertexRadius.toInt64 / 2))}
        fontFamily="monospace">
      {Html.text worldInstance.worldName}
      </text>
      <text
        fontSize={toString graphOptionsConfig.atomicPropsFontSize}
        fill="var(--vscode-editor-foreground)"
        stroke="var(--vscode-editor-background)"
        strokeWidth="2"
        paintOrder="stroke"
        textAnchor="middle"
        dy="4"
        fontFamily="monospace">
      {Html.text propsText}
      </text>
    </g>
    boundingShape := .circle vertexRadius.toFloat
  })

def createGraphDisplayEdges (edges : Array relationInstance) (graphOptionsConfig : GraphOptionsConfig): Array GraphDisplay.Edge :=
  edges.map (fun relInst => {
    source := relInst.source,
    target := relInst.target,
    label? := <text
      fontSize={toString graphOptionsConfig.edgeFontSize}
      fill={relInst.colour}
      stroke="var(--vscode-editor-background)"
      strokeWidth="5"
      paintOrder="stroke"
      textAnchor="middle"
      dy="-4"
    >
    {Html.text relInst.relationName}
    </text>,
    attrs := #[
      ("stroke", relInst.colour),
      ("stroke-width", toString graphOptionsConfig.edgeThickness),
      ("stroke-dasharray", if relInst.isGoal then "5,5" else "none")
    ]
  }
  )

-- Build the graph from the local context.
def drawGraph (lctx : LocalContext) (goalType : Expr) : MetaM Html := do
  let graphOptionsConfig ← getGraphOptionsConfig

  -- Find all worlds and relation instances
  let (worlds, relations) ← findRelationsAndWorlds lctx goalType graphOptionsConfig

  if relations.isEmpty then
    return <span>No instances of a relation of form R : T → T → Prop found.</span>

  -- Creating GraphDisplay vertices and edges from words and relations.
  let vertices : Array GraphDisplay.Vertex := createGraphDisplayVertices worlds graphOptionsConfig
  let edges : Array GraphDisplay.Edge := createGraphDisplayEdges relations graphOptionsConfig

  -- Making edges longer and adjusting forces accordingly
  let forces : Array GraphDisplay.ForceParams := #[
    .center {
      strength? := some 0
    },
    .collide {
      radius? := some ((computeMaxVertexRadius worlds graphOptionsConfig).toFloat * 1.1)
      strength? := some 0.1
      iterations? := some 1
    },
    .link {
      distance? := some graphOptionsConfig.edgeLength.toFloat,
      strength? := some 0.1,
      iterations? := some 1
    },
    .manyBody {
      strength? := some 0
    },
    .x {
      strength? := some 0
    },
    .y {
      strength? := some 0
    }
  ]

  return <GraphDisplay
    vertices={vertices}
    edges={edges}
    forces={forces}
    showDetails={false}
  />
