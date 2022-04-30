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
    - "date_since"
  PARTNER_HK:
    - "name"
    - "country"
    - "date_since"
    - "partner_name"
  COUNTRY_NAME_HK: "country"
  DIPLOMAT_COUNTRY_HK:
    - "name"
    - "country"
    - "date_since"
  DIPLOMAT_HASHDIFF:
    is_hashdiff: true
    columns:
      - "title"
      - "gender"
      - "position_name"
      - "order"
      - "partner_gender"
      - "partner_name"
      - "country_long"
      - "date"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(include_source_columns=true,
                  source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns'],
                  ranked_columns=none) }}