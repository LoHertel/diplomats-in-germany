{{ config(
      materialized='table'
) }}

WITH source_diplomat AS (
    SELECT DISTINCT publication_date AS {{ adapter.quote('date') }}
    FROM {{ ref('DIM_diplomat') }}
    ORDER BY {{ adapter.quote('date') }}
)
, ranked AS (
    SELECT *
        ,ROW_NUMBER() OVER (ORDER BY {{ adapter.quote('date') }}) AS {{ adapter.quote('rank') }}
    FROM source_diplomat
)
, max_rank AS (
    SELECT MAX({{ adapter.quote('rank') }}) AS {{ adapter.quote('max') }}
    FROM ranked
)
SELECT * FROM ranked
CROSS JOIN max_rank