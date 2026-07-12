// payload shapes mirror the R side (snake_case keys from gdalviz_graph)

export interface StepArg {
  name: string | null;
  value: string | null;
  kind: "flag" | "positional" | "nested";
}

export interface GraphNode {
  id: string;
  command: string;
  category: string;
  category_label: string;
  verb: string;
  code: string | null;
  description: string | null;
  icon: string;
  color: string;
  docs_url: string | null;
  crs: string | null;
  geom: string | null;
  fields: string | null;
  validity: string | null;
  ordering: string | null;
  branch_role: "main" | "tee" | "input" | "config";
  depth: number;
  implicit: boolean;
  count: number;
  args: StepArg[];
}

export interface GraphEdge {
  from: string;
  to: string;
  kind: "main" | "merge" | "config";
  badge: string | null;
}

export interface WidgetOptions {
  direction: "TB" | "LR" | "BT" | "RL";
  theme: "light" | "dark";
  minimap: boolean;
  controls: boolean;
  legend: boolean;
  draggable: boolean;
}

export interface Payload {
  nodes: GraphNode[];
  edges: GraphEdge[];
  meta: {
    command_line: string | null;
    pipeline_type: string | null;
  };
  options: WidgetOptions;
}
