{{ config(
      materialized='incremental' 
) }}

{%- set source_model = "v_stg_diplomat"        -%}
{%- set src_pk = "DIPLOMAT_COUNTRY_HK"         -%}
{%- set src_fk = ["DIPLOMAT_HK", "COUNTRY_NAME_HK"] -%}
{%- set src_ldts = "LOAD_DATETIME"           -%}
{%- set src_source = "SOURCE"         -%}

{{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                 src_source=src_source, source_model=source_model) }}