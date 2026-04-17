module

public meta import ProofWidgets.Component.GraphDisplay
public meta import ProofWidgets.Component.Panel.Basic
public meta import ProofWidgets.Component.OfRpcMethod
import Lean4Graphsee.graph_options

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

-- Build the Kripke frame graph from the local context.
def drawKripkeGraph (lctx : LocalContext) : MetaM Html := do
  let mut worldType? : Option Expr := none
  let mut relationName? : Option Expr := none
  -- Infer worldtypes and relation names
  for decl in lctx do
    if let some t ← isRelationType decl.type then
      worldType? := some t
      relationName? := some (mkFVar decl.fvarId)
      break

  let some worldType := worldType? | do
    return <span>No relation of the form R : T → T → Prop found.</span>
  let some rel := relationName? | unreachable!

  -- Find all worlds
  let mut worlds : Array String := #[]
  for decl in lctx do
    if ← isDefEq decl.type worldType then
      worlds := worlds.push decl.userName.toString

  -- Create GraphDisplay edges from found relations
  let mut edges : Array GraphDisplay.Edge := #[]
  for decl in lctx do
    match decl.type with
    | .app (.app r w1) w2 =>
      if ← isDefEq r rel then
        let w1str := toString (← ppExpr w1)
        let w2str := toString (← ppExpr w2)
        edges := edges.push {source := w1str, target := w2str}
    | _ => pure ()

  let vertices : Array GraphDisplay.Vertex := worlds.map ({id := ·})
  return <GraphDisplay
    vertices={vertices}
    edges={edges}
    showDetails={false}
  />


open Lean Server ProofWidgets in
@[server_rpc_method]
def KripkeGraph.rpc (props : PanelWidgetProps) : RequestM (RequestTask Html) :=
  RequestM.asTask do
    let inner : Html ← do
      if props.goals.isEmpty then
        return <span>No goals.</span>
      let some g := props.goals[0]? | unreachable!
      g.ctx.val.runMetaM {} do
        let md ← g.mvarId.getDecl
        let lctx := md.lctx |>.sanitizeNames.run' {options := (← getOptions)}
        let options ← getOptions
        if !options.getBool `Kripke.showGraph then
          return <span></span>
        Meta.withLCtx lctx md.localInstances do
          drawKripkeGraph lctx
    return <details «open»={true}>
      <summary className="mv2 pointer">Graph Display</summary>
      <div className="ml1">{inner}</div>
    </details>

@[widget_module]
def KripkeGraph : Component ProofWidgets.PanelWidgetProps :=
  mk_rpc_widget% KripkeGraph.rpc

show_panel_widgets [KripkeGraph]
