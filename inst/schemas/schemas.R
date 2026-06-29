
#  ------------------------------------------------------------------------
#
# Title : Download Schemas Script
#    By : Jimmy Briggs
#  Date : 2026-05-27
#
#  ------------------------------------------------------------------------

# gdalg -----------------------------------------------------------------------------------------------------------

curl::curl_download(
  "https://raw.githubusercontent.com/OSGeo/gdal/refs/heads/master/frmts/gdalg/data/gdalg.schema.json",
  destfile = "inst/schemas/gdalg.schema.json"
)

# gdal_algorithm.schema.json --------------------------------------------------------------------------------------

curl::curl_download(
  "https://raw.githubusercontent.com/OSGeo/gdal/refs/heads/master/apps/data/gdal_algorithm.schema.json",
  destfile = "inst/schemas/gdal_algorithm.schema.json"
)

# gdalinfo_output.schema.json -------------------------------------------------------------------------------------

curl::curl_download(
  "https://raw.githubusercontent.com/OSGeo/gdal/refs/heads/master/apps/data/gdalinfo_output.schema.json",
  destfile = "inst/schemas/gdalinfo_output.schema.json"
)

# ogrinfo_output.schema.json --------------------------------------------------------------------------------------

curl::curl_download(
  "https://raw.githubusercontent.com/OSGeo/gdal/refs/heads/master/apps/data/ogrinfo_output.schema.json",
  destfile = "inst/schemas/ogrinfo_output.schema.json"
)

# ogrvrt.xsd ------------------------------------------------------------------------------------------------------

curl::curl_download(
  "https://raw.githubusercontent.com/OSGeo/gdal/refs/heads/master/ogr/ogrsf_frmts/vrt/data/ogrvrt.xsd",
  destfile = "inst/schemas/ogrvrt.xsd"
)

# ogr_fields_override.schema.json ---------------------------------------------------------------------------------

curl::curl_download(
  "https://raw.githubusercontent.com/OSGeo/gdal/refs/heads/master/ogr/data/ogr_fields_override.schema.json",
  destfile = "inst/schemas/ogr_fields_override.schema.json"
)

# NOTE: projjson reference
# "projjson": {
#   "$ref": "https://proj.org/schemas/v0.5/projjson.schema.json"
# },

# projjson --------------------------------------------------------------------------------------------------------

curl::curl_download(
  "https://proj.org/schemas/v0.5/projjson.schema.json",
  destfile = "inst/schemas/projjson.schema.json"
)





