# Look up a single pipeline step in the contract

Look up a single pipeline step in the contract

## Usage

``` r
contract_step(command, contract = gdalviz_contract())
```

## Arguments

- command:

  Step command name (e.g. `"reproject"`).

- contract:

  A `gdalviz_contract`. Defaults to the bundled contract.

## Value

The step definition list, or `NULL` if the command is unknown.
