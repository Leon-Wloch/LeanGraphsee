module

public meta import ProofWidgets.Component.Panel.Basic
public meta import ProofWidgets.Component.OfRpcMethod
public meta import Graphsee.Graph

public meta section

open Lean Meta Server ProofWidgets Jsx

@[server_rpc_method]
def GraphseeWidget.rpc (props : PanelWidgetProps) : RequestM (RequestTask Html) :=
  RequestM.asTask do
    if props.goals.isEmpty then
      return <span></span>

    let some g := props.goals[0]? | unreachable!

    -- Check whether user set_option to display the graph
    let showGraph ← g.ctx.val.runMetaM {} do
      let options ← getOptions
      return options.getBool `graphsee.showGraph true

    if !showGraph then
      return <span></span>

    -- Generate graphHTML using drawGraph
    let graphHTML ← g.ctx.val.runMetaM {} do
      let md ← g.mvarId.getDecl
      let lctx := md.lctx |>.sanitizeNames.run' {options := (← getOptions)}
      Meta.withLCtx lctx md.localInstances do
        drawGraph lctx md.type

    return <details «open»={true}>
      <summary className="mv2 pointer">Graph Display</summary>
      <div className="ml1">{graphHTML}</div>
    </details>

@[widget_module]
def GraphseeWidget : Component ProofWidgets.PanelWidgetProps :=
  mk_rpc_widget% GraphseeWidget.rpc

show_panel_widgets [GraphseeWidget]
