{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 
  staging: "diplomats"
derived_columns:
  SOURCE: "!AA_PDF"
  LOAD_DATETIME: "CURRENT_DATETIME()"
  EFFECTIVE_FROM: "date"
  START_DATE: "date_since"
  END_DATE: "DATE(9999, 12, 31)"
hashed_columns:
  DIPLOMAT_HK:
    - "name"
    - "country"
  PARTNER_HK:
    - "name"
    - "country"
    - "partner_name"
  COUNTRY_NAME_HK: "country"
  DIPLOMAT_HASHDIFF:
    is_hashdiff: true
    columns:
      - "title"
      - "gender"
      - "name"
      - "position_name"
      - "date_since"
      - "order"
      - "country"
      - "country_long"
      - "date"
  PARTNER_HASHDIFF:
    is_hashdiff: true
    columns:
      - "name"
      - "partner_gender"
      - "partner_name"
      - "country"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(include_source_columns=true,
                  source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns'],
                  ranked_columns=none) }}