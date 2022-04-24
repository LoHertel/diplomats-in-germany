{{ config(
      materialized='incremental', 
      full_refresh = false
) }}

{%- set source_model = "v_stg_diplomats"   -%}

{%- set src_pk = "DIPLOMAT_HK"             -%}
{%- set src_nk = ["name", "country"]       -%}
{%- set src_ldts = "LOAD_DATETIME"         -%}
{%- set src_source = "SOURCE"              -%}

{{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}