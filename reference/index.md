# Package index

## Read and parse

Turn command lines, GDALG files, and shell scripts into pipelines.

- [`parse_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/parse_pipeline.md)
  : Parse a GDAL vector pipeline into a structured object
- [`read_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/read_gdalg.md)
  : Read a GDAL pipeline from a GDALG file or raw string
- [`parse_script()`](http://docs.jimbrig.com/gdalviz/reference/parse_script.md)
  : Parse a shell or powershell script into a pipeline
- [`read_script()`](http://docs.jimbrig.com/gdalviz/reference/read_script.md)
  : Read a shell or powershell script file into a pipeline

## Validate

Check pipelines against the GDAL –json-usage contract.

- [`lint_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/lint_pipeline.md)
  : Lint a GDAL pipeline against the GDAL contract
- [`validate_pipeline()`](http://docs.jimbrig.com/gdalviz/reference/validate_pipeline.md)
  : Validate a GDAL pipeline against the GDAL contract
- [`gdalviz_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_contract.md)
  : GDAL vector pipeline contract registry
- [`gdalviz_refresh_contract()`](http://docs.jimbrig.com/gdalviz/reference/gdalviz_refresh_contract.md)
  : Regenerate the GDAL pipeline contract snapshot from the installed
  GDAL
- [`contract_step()`](http://docs.jimbrig.com/gdalviz/reference/contract_step.md)
  : Look up a single pipeline step in the contract

## Graph model

- [`pipeline_graph()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_graph.md)
  : Build a renderer-agnostic graph model from a parsed pipeline

## Render

Interactive and static visualizations.

- [`render_reactflow()`](http://docs.jimbrig.com/gdalviz/reference/render_reactflow.md)
  : Render a pipeline graph as an interactive React Flow widget
- [`pipelineFlowOutput()`](http://docs.jimbrig.com/gdalviz/reference/pipelineFlowOutput.md)
  [`renderPipelineFlow()`](http://docs.jimbrig.com/gdalviz/reference/pipelineFlowOutput.md)
  : Shiny bindings for pipeline_flow widgets
- [`render_diagrammer()`](http://docs.jimbrig.com/gdalviz/reference/render_diagrammer.md)
  : Render a pipeline graph as a Graphviz diagram (static-capable)
- [`pipeline_dot()`](http://docs.jimbrig.com/gdalviz/reference/pipeline_dot.md)
  : Generate the DOT specification for a pipeline graph
- [`render_g6()`](http://docs.jimbrig.com/gdalviz/reference/render_g6.md)
  : Render a pipeline graph as an interactive g6 (AntV G6) widget

## Serialize

Back out to command lines, scripts, and GDALG.

- [`render_command_line()`](http://docs.jimbrig.com/gdalviz/reference/render_command_line.md)
  : Render a pipeline as a canonical GDALG command line
- [`render_script()`](http://docs.jimbrig.com/gdalviz/reference/render_script.md)
  : Render a pipeline as a formatted shell script
- [`as_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/as_gdalg.md)
  : Convert a pipeline to a GDALG specification list
- [`write_gdalg()`](http://docs.jimbrig.com/gdalviz/reference/write_gdalg.md)
  : Write a pipeline to a GDALG JSON file
