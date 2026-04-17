module

public meta import ProofWidgets.Component.GraphDisplay
public meta import ProofWidgets.Component.HtmlDisplay

public meta section

open ProofWidgets Jsx

def mkEdge (st : String × String) : GraphDisplay.Edge := {source := st.1, target := st.2}

def vertices : Array  GraphDisplay.Vertex := #["a", "b", "c", "d", "e", "f"].map ({id := ·})
def edges : Array GraphDisplay.Edge := #[("b","c"), ("d","e"), ("e","f"), ("f","d")].map mkEdge

#html <GraphDisplay vertices={vertices} edges={edges}  />
