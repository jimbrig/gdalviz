
#  ------------------------------------------------------------------------
#
# Title : GDALG Pipelines
#    By : Jimmy Briggs
#  Date : 2026-06-03
#
#  ------------------------------------------------------------------------

source("inst/extdata/pipelines/gdal_cli_run.R")
gdal_cli_run(args = "--version", label = "GDAL Version")

# configurations & options ----------------------------------------------------------------------------------------

gdal_log_file <- "inst/extdata/pipelines/tiger.gdal.log"

gdal_config_opts <- c(
  "--config", "GDAL_NUM_THREADS=ALL_CPUS",
  "--config", "GDAL_ALGORITHM_ALLOW_WRITES_IN_STREAM=YES",
  "--config", "CPL_LOG_ERRORS=ON",
  "--config", "CPL_TIMESTAMP=ON",
  "--config", "CPL_DEBUG=ON",
  "--config", glue::glue("CPL_LOG={gdal_log_file}")
)

gdal_vsi_opts <- c(
  "--config", "GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR",
  "--config", "VSI_CACHE=TRUE",
  "--config", glue::glue("VSI_CACHE_SIZE={as.character(128 * 1024 * 1024)}"),
  "--config", "GDAL_HTTP_CONNECTTIMEOUT=30",
  "--config", "GDAL_HTTP_TIMEOUT=60",
  "--config", "GDAL_HTTP_MAX_RETRY=5",
  "--config", "GDAL_HTTP_RETRY_DELAY=2",
  "--config", "GDAL_HTTP_RETRY_CODES=429,500,502,503,504",
  "--config", "CPL_VSIL_CURL_USE_HEAD=NO",
  "--config", "GDAL_HTTP_TCP_KEEPALIVE=YES",
  "--config", "GDAL_HTTP_USERAGENT=gdalviz/0.0.1"
)

gdal_shp_opts <- c(
  "--config", "SHAPE_RESTORE_SHX=NO"
)

gdal_shp_open_opts <- c(
  "--open-option", "ENCODING=UTF-8",
  "--open-option", "ADJUST_GEOM_TYPE=FIRST_SHAPE",
  "--open-option", "AUTO_REPACK=YES",
  "--open-option", "DBF_EOF_CHAR=YES"
)

# setup tiger -----------------------------------------------------------------------------------------------------

non_conus_state_fips <- c("02", "15", "60", "66", "69", "72", "74", "78")
non_conus_state_fips_sql <- paste0("STATEFP NOT IN (", as.character(glue::glue_sql_collapse(sQuote(non_conus_state_fips), sep = ",")), ")")

tiger_states_url <- "https://www2.census.gov/geo/tiger/TIGER2025/STATE/tl_2025_us_state.zip"
tiger_states_dsn <- gdalraster::vsi_glob(paste0("/vsizip/", gdalraster::vsi_uri_to_vsi_path(tiger_states_url), "/*.shp"))
tiger_states_layer <- gdalraster::ogr_ds_layer_names(tiger_states_dsn)[[1]]
tiger_states_driver <- gdalraster::ogr_ds_format(tiger_states_dsn)
tiger_states_fields <- gdalraster::ogr_layer_field_names(tiger_states_dsn)

tiger_counties_url <- "https://www2.census.gov/geo/tiger/TIGER2025/COUNTY/tl_2025_us_county.zip"
tiger_counties_dsn <- gdalraster::vsi_glob(paste0("/vsizip/", gdalraster::vsi_uri_to_vsi_path(tiger_counties_url), "/*.shp"))
tiger_counties_layer <- gdalraster::ogr_ds_layer_names(tiger_counties_dsn)[[1]]
tiger_counties_driver <- gdalraster::ogr_ds_format(tiger_counties_dsn)
tiger_counties_fields <- gdalraster::ogr_layer_field_names(tiger_counties_dsn)

tiger_states_sql <- glue::glue_sql(
  stringr::str_squish(
  "
  SELECT
    GEOID AS geoid,
    STATEFP AS state_fips,
    STUSPS AS state_abbr,
    NAME AS state_name,
    ALAND AS area_land_m2,
    AWATER AS area_water_m2
  FROM {`tiger_states_layer`}
  "
  ),
  .con = DBI::ANSI()
)

tiger_counties_sql <- glue::glue_sql(
  stringr::str_squish(
    "
  SELECT
    GEOID AS geoid,
    STATEFP AS state_fips,
    COUNTYFP AS county_fips,
    NAME AS county_name,
    ALAND AS area_land_m2,
    AWATER AS area_water_m2
  FROM {`tiger_counties_layer`}
  "
  ),
  .con = DBI::ANSI()
)


# gdalg -----------------------------------------------------------------------------------------------------------

tiger_states_gdalg_file <- "inst/extdata/pipelines/tiger_states_gdalg.json"

tiger_states_gdalg_args <- c(
  "vector", "pipeline", "--progress", gdal_config_opts, gdal_vsi_opts, gdal_shp_opts,
  "!", "read", "--input", tiger_states_dsn, "--input-layer", tiger_states_layer, gdal_shp_open_opts,
  "!", "filter", "--where", non_conus_state_fips_sql,
  "!", "sql", "--sql", tiger_states_sql,
  "!", "make-valid",
  "!", "set-geom-type", "--multi", "--skip",
  "!", "reproject", "--output-crs", "EPSG:4326",
  "!", "sort", "--method", "hilbert",
  "!", "write", "--output", tiger_states_gdalg_file, "--output-format", "GDALG", "--overwrite"
)

res_tiger_states_gdalg <- gdal_cli_run(args = tiger_states_gdalg_args, label = "GDALG Pipeline: Tiger States")

tiger_counties_gdalg_file <- "inst/extdata/pipelines/tiger_counties_gdalg.json"

tiger_counties_gdalg_args <- c(
  "vector", "pipeline", "--progress", gdal_config_opts, gdal_vsi_opts, gdal_shp_opts,
  "!", "read", "--input", tiger_counties_dsn, "--input-layer", tiger_counties_layer, gdal_shp_open_opts,
  "!", "filter", "--where", non_conus_state_fips_sql,
  "!", "sql", "--sql", tiger_counties_sql,
  "!", "make-valid",
  "!", "set-geom-type", "--multi", "--skip",
  "!", "reproject", "--output-crs", "EPSG:4326",
  "!", "sort", "--method", "hilbert",
  "!", "write", "--output", tiger_counties_gdalg_file, "--output-format", "GDALG", "--overwrite"
)

res_tiger_counties_gdalg <- gdal_cli_run(args = tiger_counties_gdalg_args, label = "GDALG Pipeline: Tiger Counties")
