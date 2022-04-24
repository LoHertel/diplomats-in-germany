{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: "countries"
derived_columns:
  SOURCE: "!CSV"
  LOAD_DATETIME: "CURRENT_DATETIME()"
hashed_columns:
  COUNTRY_HK: "ISO_3166_1_alpha2"
  COUNTRY_NAME_HK: "name_DE"
  COUNTRY_HASHDIFF:
    is_hashdiff: true
    columns:
      - "ISO_3166_1_alpha2"
      - "ISO_3166_1_alpha3"
      - "name_EN"
      - "full_name_EN"
      - "name_DE"
      - "full_name_DE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(include_source_columns=true,
                  source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns'],
                  ranked_columns=none) }}