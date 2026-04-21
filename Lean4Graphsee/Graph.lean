module

public meta import ProofWidgets.Component.GraphDisplay
public meta import Lean4Graphsee.Options
public meta import Lean4Graphsee.Colours

public meta section

open Lean Meta ProofWidgets Jsx

-- Stores the relation's expression, corresponding world type, and user-friendly name.
structure RelationInfo where
  relation : Expr
  worldType : Expr
  name : String
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

def findAllRelations (lctx : LocalContext) : MetaM (Array RelationInfo) := do
  let mut relations : Array RelationInfo := #[]
  for decl in lctx do
    if let some t ← isRelationType decl.type then
      relations := relations.push {
        relation := mkFVar decl.fvarId
        worldType := t
        name := decl.userName.toString
      }
  return relations

def findAllWorlds (lctx : LocalContext) (relations : Array RelationInfo) : MetaM (Std.HashSet String) := do
  let mut worlds : Std.HashSet String := {}
  -- TODO: ineffecient looping: we are looping over lctx for each relation.
  for info in relations do
  -- TODO: this for-loop is very similar to the one from extracEdgesFromRelation.
  -- Possibly extract all instances of relations first and pass them to both functions?
    for decl in lctx do
      match decl.type with
      | .app (.app r w1) w2 =>
        if ← isDefEq r info.relation then
          let w1Type ← inferType w1
          let w2Type ← inferType w2
          if (← isDefEq w1Type info.worldType) && (← isDefEq w2Type info.worldType) then
            let w1str := toString (← ppExpr w1)
            let w2str := toString (← ppExpr w2)
            worlds := worlds.insert w1str
            worlds := worlds.insert w2str
      | _ => pure ()
  return worlds

def getCurrentColourPalette : MetaM (Array String) := do
  let options ← getOptions
  let paletteName := options.get `Kripke.edgeColours "default"
  return getPalette paletteName

def extractEdgesFromRelation (lctx : LocalContext) (info : RelationInfo) (colour : String) : MetaM (Array (String × String × String × String)) := do
  let mut edges : Array (String × String × String × String) := #[]
  for decl in lctx do
    match decl.type with
    | .app (.app r w1) w2 =>
      if ← isDefEq r info.relation then
        let w1str := toString (← ppExpr w1)
        let w2str := toString (← ppExpr w2)
        let relationName := info.name
        edges := edges.push (w1str, w2str, colour, relationName)
    | _ => pure ()
  return edges

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

def createGraphDisplayEdges (edges : Array (String × String × String × String)) : Array GraphDisplay.Edge :=
  edges.map (fun (src, tgt, col, name) => {
    source := src,
    target := tgt,
    label? := <text
      fontSize="10"
      fill="#FFF"
      textAnchor="middle"
      dy="-4"
    >
    {Html.text name}
    </text>,
    attrs := #[
      ("stroke", col)
    ]
  }
  )

-- Build the Kripke frame graph from the local context.
def drawKripkeGraph (lctx : LocalContext) : MetaM Html := do
  let relations ← findAllRelations lctx

  if relations.isEmpty then
    return <span>No relation of the form R: T → T → Prop found.</span>

  -- Use the relations to find all worlds.
  let worlds ←  findAllWorlds lctx relations

  -- Find the current edge colours palette
  let currentEdgePalette ← getCurrentColourPalette

  -- Find all the edges by extracting edges from each relation type one by one.
  let mut allEdges : Array (String × String × String × String) := #[]
  for i in [:relations.size] do
    let info := relations[i]!
    let colour := currentEdgePalette[i % currentEdgePalette.size]!
    let edges ← extractEdgesFromRelation lctx info colour
    allEdges := allEdges ++ edges

  -- Creating GraphDisplay vertices and edges from words and relations.
  let vertices : Array GraphDisplay.Vertex := createGraphDisplayVertices worlds
  let edges : Array GraphDisplay.Edge := createGraphDisplayEdges allEdges

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
