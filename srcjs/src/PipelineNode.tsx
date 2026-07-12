import { memo } from "react";
import { Handle, Position, type NodeProps } from "@xyflow/react";
import { prettyValue } from "./format";
import type { GraphNode } from "./types";

const GLYPHS: Record<string, string> = {
  source: "\u25B8", // ▸
  sink: "\u25A0", // ■
  attribute: "\u2637", // ☷
  crs: "\u25CE", // ◎
  filter: "\u2260", // ≠
  order: "\u2195", // ↕
  branch: "\u2442", // ⑂
  inspect: "\u2315", // ⌕
  geometry: "\u25C7", // ◇
  runtime: "\u2699", // ⚙
  other: "\u22EF", // ⋯
};

function valueClass(name: string | null): string {
  if (!name) return "gv-val";
  if (/input|output|like/.test(name)) return "gv-val gv-val-path";
  if (/where|sql/.test(name)) return "gv-val gv-val-sql";
  if (/crs|method|dialect|format|geometry-type/.test(name)) return "gv-val gv-val-enum";
  if (/option/.test(name)) return "gv-val gv-val-opt";
  return "gv-val";
}

export type PipelineNodeData = { node: GraphNode; horizontal: boolean };

function PipelineNodeInner({ data, selected }: NodeProps) {
  const { node, horizontal } = data as PipelineNodeData;
  const valued = node.args.filter((a) => a.value !== null);
  const flags = node.args.filter((a) => a.value === null && a.kind === "flag");
  const glyph = GLYPHS[node.category] ?? GLYPHS.other;

  return (
    <div
      className={`gv-node gv-cat-${node.category}${selected ? " gv-selected" : ""}${node.implicit ? " gv-implicit" : ""}`}
      style={{ ["--gv-accent" as string]: node.color }}
    >
      <Handle type="target" position={horizontal ? Position.Left : Position.Top} className="gv-handle" />
      <div className="gv-node-header">
        <span className="gv-node-title">
          <span className="gv-glyph">{glyph}</span>
          <span className="gv-command">{node.command}</span>
        </span>
        <span className="gv-badge">{node.category_label}</span>
      </div>
      <div className="gv-node-body">
        {valued.length === 0 && (
          <div className="gv-desc">{node.description ?? "no parameters"}</div>
        )}
        {valued.map((a, i) => (
          <div key={i} className="gv-arg-row">
            <span className="gv-arg-key">{a.name ?? "\u2022"}</span>
            <span className={valueClass(a.name)}>{prettyValue(a.value ?? "")}</span>
          </div>
        ))}
        {flags.length > 0 && (
          <div className="gv-flags">
            {flags.map((f, i) => (
              <span key={i} className="gv-flag">--{f.name}</span>
            ))}
          </div>
        )}
      </div>
      <Handle type="source" position={horizontal ? Position.Right : Position.Bottom} className="gv-handle" />
    </div>
  );
}

export const PipelineNode = memo(PipelineNodeInner);
