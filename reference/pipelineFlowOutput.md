# Shiny bindings for pipeline_flow widgets

Output and render functions for using
[`render_reactflow()`](http://docs.jimbrig.com/gdalviz/reference/render_reactflow.md)
widgets within Shiny applications.

## Usage

``` r
pipelineFlowOutput(outputId, width = "100%", height = "560px")

renderPipelineFlow(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- outputId:

  Output variable to read from.

- width, height:

  CSS dimensions for the widget container.

- expr:

  An expression that returns a `pipeline_flow` widget.

- env:

  The environment in which to evaluate `expr`.

- quoted:

  Whether `expr` is a quoted expression.

## Value

`pipelineFlowOutput()` returns a Shiny output element;
`renderPipelineFlow()` returns a Shiny render function.
