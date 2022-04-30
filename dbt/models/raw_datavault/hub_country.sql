{{ config(
      materialized='incremental'
) }}

{%- set source_model = "v_stg_country"   -%}

{%- set src_pk = "COUNTRY_NAME_HK"             -%}
{%- set src_nk = ["name_DE"]       -%}
{%- set src_ldts = "LOAD_DATETIME"         -%}
{%- set src_source = "SOURCE"              -%}

{{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}