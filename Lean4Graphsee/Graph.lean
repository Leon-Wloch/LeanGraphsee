module

public meta import ProofWidgets.Component.GraphDisplay
public meta import Lean4Graphsee.Options
public meta import Lean4Graphsee.Colours

public meta section

open Lean Meta ProofWidgets Jsx

-- Stores a relation and its corresponding world type.
structure RelationInfo where
  relation : Expr
  worldType : Expr
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
      }
  return relations

def findAllWorlds (lctx : LocalContext) (relations : Array RelationInfo) : MetaM (Std.HashSet String) := do
  let mut worlds : Std.HashSet String := {}
  for info in relations do
    for decl in lctx do
      if ← isDefEq decl.type info.worldType then
        worlds := worlds.insert decl.userName.toString
  return worlds

def getCurrentColourPalette : MetaM (Array String) := do
  let options ← getOptions
  let paletteName := options.get `Kripke.edgeColours "default"
  return getPalette paletteName

def extractEdgesFromRelation (lctx : LocalContext) (info : RelationInfo) (colour : String) : MetaM (Array (String × String × String)) := do
  let mut edges : Array (String × String × String) := #[]
  for decl in lctx do
    match decl.type with
    | .app (.app r w1) w2 =>
      if ← isDefEq r info.relation then
        let w1str := toString (← ppExpr w1)
        let w2str := toString (← ppExpr w2)
        edges := edges.push (w1str, w2str, colour)
    | _ => pure ()
  return edges

def createGraphDisplayVertices (worlds : Std.HashSet String) : Array GraphDisplay.Vertex :=
  worlds.toArray.map ({id := ·})

def createGraphDisplayEdges (edges : Array (String × String × String)) : Array GraphDisplay.Edge :=
  edges.map (fun (src, tgt, col) => {
    source := src,
    target := tgt,
    attrs := #[
      ("stroke", col),
      ("fill", col)
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
  let mut allEdges : Array (String × String × String) := #[]
  for i in [:relations.size] do
    let info := relations[i]!
    let colour := currentEdgePalette[i % currentEdgePalette.size]!
    let edges ← extractEdgesFromRelation lctx info colour
    allEdges := allEdges ++ edges

  -- Creating GraphDisplay vertices and edges from words and relations.
  let vertices : Array GraphDisplay.Vertex := createGraphDisplayVertices worlds
  let edges : Array GraphDisplay.Edge := createGraphDisplayEdges allEdges

  return <GraphDisplay
    vertices={vertices}
    edges={edges}
    showDetails={false}
  />
