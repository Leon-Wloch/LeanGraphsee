module

public meta import ProofWidgets.Component.GraphDisplay

public meta section

open Lean Meta ProofWidgets Jsx

-- Check if an expression is of the form T → T → Prop.
def isRelationType (e : Expr) : MetaM (Option Expr) := do
  match e with
  | .forallE _ t1 (.forallE _ t2 (.sort .zero) _) _ =>
    if ← isDefEq t1 t2 then
      return some t1
    else
      return none
  | _ => return none

-- Stores a relation and its corresponding world type.
structure RelationInfo where
  relation : Expr
  worldType : Expr

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

def extractEdgesFromRelation (lctx : LocalContext) (info : RelationInfo) : MetaM (Array (String × String)) := do
  let mut edges : Array (String × String) := #[]
  for decl in lctx do
    match decl.type with
    | .app (.app r w1) w2 =>
      if ← isDefEq r info.relation then
        let w1str := toString (← ppExpr w1)
        let w2str := toString (← ppExpr w2)
        edges := edges.push (w1str, w2str)
    | _ => pure ()
  return edges

def createGraphDisplayVertices (worlds : Std.HashSet String) : Array GraphDisplay.Vertex :=
  worlds.toArray.map ({id := ·})

def createGraphDisplayEdges (edges : Array (String × String)) : Array GraphDisplay.Edge :=
  edges.map (fun (src, tgt) => {source := src, target := tgt})

-- Build the Kripke frame graph from the local context.
def drawKripkeGraph (lctx : LocalContext) : MetaM Html := do
  let relations ← findAllRelations lctx

  if relations.isEmpty then
    return <span>No relation of the form R: T → T → Prop found.</span>

  -- Use the relations to find all worlds.
  let worlds ←  findAllWorlds lctx relations

  -- Find all the edges by extracting edges from each relation type one by one.
  let mut allEdges := #[]
  for info in relations do
    let edges ← extractEdgesFromRelation lctx info
    allEdges := allEdges ++ edges

  -- Creating GraphDisplay vertices and edges from words and relations.
  let vertices : Array GraphDisplay.Vertex := createGraphDisplayVertices worlds
  let edges : Array GraphDisplay.Edge := createGraphDisplayEdges allEdges

  return <GraphDisplay
    vertices={vertices}
    edges={edges}
    showDetails={false}
  />
