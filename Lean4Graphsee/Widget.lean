module

public meta import ProofWidgets.Component.Panel.Basic
public meta import ProofWidgets.Component.OfRpcMethod
public meta import Lean4Graphsee.Graph
public meta import Lean4Graphsee.Options

public meta section

open Lean Meta Server ProofWidgets Jsx

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
