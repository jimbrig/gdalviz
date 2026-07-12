import type { GraphNode } from "./types";

const STATE_FIELDS: Array<[keyof GraphNode, string]> = [
  ["crs", "CRS"],
  ["geom", "Geometry"],
  ["fields", "Fields"],
  ["validity", "Validity"],
  ["ordering", "Ordering"],
];

export function Inspector({ node, onClose }: { node: GraphNode; onClose: () => void }) {
  const state = STATE_FIELDS.map(([key, label]) => ({ label, value: node[key] as string | null })).filter(
    (s) => s.value !== null && s.value !== ""
  );

  return (
    <div className="gv-inspector">
      <div className="gv-inspector-header">
        <span className="gv-inspector-title" style={{ color: node.color }}>
          {node.command}
          {node.count > 1 ? ` \u00d7${node.count}` : ""}
        </span>
        <button className="gv-btn-close" onClick={onClose} aria-label="close inspector">
          {"\u2715"}
        </button>
      </div>
      {node.description && <div className="gv-inspector-desc">{node.description}</div>}

      {node.code && (
        <>
          <div className="gv-inspector-section">step</div>
          <pre className="gv-inspector-code">{`${node.command} ${node.code}`.trim()}</pre>
        </>
      )}

      {node.args.length > 0 && (
        <>
          <div className="gv-inspector-section">arguments</div>
          <table className="gv-inspector-args">
            <tbody>
              {node.args.map((a, i) => (
                <tr key={i}>
                  <td className="gv-arg-key">{a.name ? `--${a.name}` : "(positional)"}</td>
                  <td className="gv-arg-value">
                    {a.kind === "nested" ? "[ nested pipeline ]" : (a.value ?? "true")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}

      {state.length > 0 && (
        <>
          <div className="gv-inspector-section">stream state after this step</div>
          <table className="gv-inspector-args">
            <tbody>
              {state.map((s) => (
                <tr key={s.label}>
                  <td className="gv-arg-key">{s.label}</td>
                  <td className="gv-arg-value">{s.value}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}

      {node.docs_url && (
        <a className="gv-docs-link" href={node.docs_url} target="_blank" rel="noreferrer">
          GDAL documentation {"\u2197"}
        </a>
      )}
    </div>
  );
}
