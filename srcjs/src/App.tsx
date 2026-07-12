import { useCallback, useMemo, useState } from "react";
import {
  ReactFlow,
  ReactFlowProvider,
  Background,
  BackgroundVariant,
  Controls,
  MiniMap,
  type Node,
  type NodeMouseHandler,
} from "@xyflow/react";
import { layoutGraph } from "./layout";
import { PipelineNode } from "./PipelineNode";
import { Inspector } from "./Inspector";
import type { GraphNode, Payload } from "./types";

const nodeTypes = { pipeline: PipelineNode };

function Legend({ nodes }: { nodes: GraphNode[] }) {
  const cats = useMemo(() => {
    const seen = new Map<string, { label: string; color: string }>();
    for (const n of nodes) {
      if (!seen.has(n.category)) {
        seen.set(n.category, { label: n.category_label, color: n.color });
      }
    }
    return [...seen.values()];
  }, [nodes]);

  return (
    <div className="gv-legend">
      {cats.map((c) => (
        <span key={c.label} className="gv-legend-item">
          <span className="gv-legend-swatch" style={{ background: c.color }} />
          {c.label}
        </span>
      ))}
    </div>
  );
}

export function App({ payload }: { payload: Payload }) {
  const { options } = payload;
  const [selected, setSelected] = useState<string | null>(null);

  const { rfNodes, rfEdges } = useMemo(
    () => layoutGraph(payload.nodes, payload.edges, options.direction),
    [payload, options.direction]
  );

  const onNodeClick: NodeMouseHandler = useCallback((_evt, node: Node) => {
    setSelected((cur) => (cur === node.id ? null : node.id));
  }, []);

  const selectedNode = payload.nodes.find((n) => n.id === selected) ?? null;

  return (
    <div className={`gv-root gv-theme-${options.theme}`}>
      <ReactFlowProvider>
        <ReactFlow
          nodes={rfNodes}
          edges={rfEdges}
          nodeTypes={nodeTypes}
          fitView
          fitViewOptions={{ padding: 0.15, maxZoom: 1.25 }}
          minZoom={0.2}
          maxZoom={2}
          nodesDraggable={options.draggable}
          nodesConnectable={false}
          elementsSelectable
          onNodeClick={onNodeClick}
          onPaneClick={() => setSelected(null)}
          proOptions={{ hideAttribution: true }}
          colorMode={options.theme}
        >
          <Background variant={BackgroundVariant.Dots} gap={22} size={1} />
          {options.controls && <Controls showInteractive={false} />}
          {options.minimap && (
            <MiniMap
              pannable
              zoomable
              nodeColor={(n) => (n.data as { node: GraphNode }).node.color}
              nodeStrokeWidth={0}
            />
          )}
        </ReactFlow>
        {options.legend && <Legend nodes={payload.nodes} />}
        {selectedNode && <Inspector node={selectedNode} onClose={() => setSelected(null)} />}
      </ReactFlowProvider>
    </div>
  );
}
