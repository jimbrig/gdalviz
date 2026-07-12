import dagre from "@dagrejs/dagre";
import { Position, type Node, type Edge } from "@xyflow/react";
import { valueLines } from "./format";
import type { GraphNode, GraphEdge, WidgetOptions } from "./types";

export const NODE_WIDTH = 264;

// dagre needs node sizes before react flow measures them, so estimate the
// card height from its contents (mirrors the css in styles.css)
export function measureNode(n: GraphNode): number {
  const valued = n.args.filter((a) => a.value !== null);
  const flags = n.args.filter((a) => a.value === null && a.kind === "flag").length;
  let h = 32; // header
  h += 18; // body padding
  if (valued.length === 0) {
    h += 18; // description line
  } else {
    for (const a of valued) {
      h += valueLines(a.value ?? "") * 15 + 5; // wrapped value rows
    }
  }
  if (flags > 0) h += 28;
  return h;
}

export function layoutGraph(
  nodes: GraphNode[],
  edges: GraphEdge[],
  direction: WidgetOptions["direction"]
): { rfNodes: Node[]; rfEdges: Edge[] } {
  const g = new dagre.graphlib.Graph();
  g.setGraph({
    rankdir: direction,
    nodesep: 42,
    ranksep: direction === "LR" || direction === "RL" ? 90 : 56,
    marginx: 24,
    marginy: 24,
  });
  g.setDefaultEdgeLabel(() => ({}));

  for (const n of nodes) {
    g.setNode(n.id, { width: NODE_WIDTH, height: measureNode(n) });
  }
  for (const e of edges) {
    g.setEdge(e.from, e.to);
  }
  dagre.layout(g);

  const horizontal = direction === "LR" || direction === "RL";
  const [sourcePos, targetPos] =
    direction === "LR"
      ? [Position.Right, Position.Left]
      : direction === "RL"
        ? [Position.Left, Position.Right]
        : direction === "BT"
          ? [Position.Top, Position.Bottom]
          : [Position.Bottom, Position.Top];

  const rfNodes: Node[] = nodes.map((n) => {
    const pos = g.node(n.id);
    return {
      id: n.id,
      type: "pipeline",
      position: { x: pos.x - NODE_WIDTH / 2, y: pos.y - pos.height / 2 },
      data: { node: n, horizontal },
      sourcePosition: sourcePos,
      targetPosition: targetPos,
      width: NODE_WIDTH,
      height: pos.height,
    };
  });

  const byId = new Map(nodes.map((n) => [n.id, n]));
  const rfEdges: Edge[] = edges.map((e, i) => {
    const target = byId.get(e.to);
    const isBranch =
      e.kind === "merge" || e.kind === "config" || target?.branch_role === "tee" || target?.implicit;
    return {
      id: `e${i}`,
      source: e.from,
      target: e.to,
      type: "smoothstep",
      className: isBranch ? "gv-edge gv-edge-branch" : "gv-edge",
      animated: !isBranch,
      label: e.badge ?? undefined,
      labelBgPadding: [6, 3] as [number, number],
      labelBgBorderRadius: 4,
      markerEnd: { type: "arrowclosed" as const, width: 16, height: 16 },
      style: isBranch ? { strokeDasharray: "5 4" } : undefined,
    };
  });

  return { rfNodes, rfEdges };
}
