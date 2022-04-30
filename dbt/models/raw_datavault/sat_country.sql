{{ config(
      materialized='incremental'
) }}

{%- set yaml_metadata -%}
source_model: "v_stg_country"
src_pk: "COUNTRY_NAME_HK"
src_hashdiff: 
    source_column: "COUNTRY_HASHDIFF"
    alias: "HASHDIFF"
src_payload:
    - "ISO_3166_1_alpha2"
    - "ISO_3166_1_alpha3"
    - "name_EN"
    - "full_name_EN"
    - "full_name_DE"
src_eff: "EFFECTIVE_FROM"
src_ldts: "LOAD_DATETIME"
src_source: "SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.sat(src_pk=metadata_dict["src_pk"],
                src_hashdiff=metadata_dict["src_hashdiff"],
                src_payload=metadata_dict["src_payload"],
                src_eff=metadata_dict["src_eff"],
                src_ldts=metadata_dict["src_ldts"],
                src_source=metadata_dict["src_source"],
                source_model=metadata_dict["source_model"])   }}