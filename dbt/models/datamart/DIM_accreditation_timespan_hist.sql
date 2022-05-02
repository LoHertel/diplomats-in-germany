{{ config(
      materialized='table'
) }}

WITH source_accreditation_status AS (
    SELECT *
    FROM {{ ref('DIM_accreditation_status') }} 
)
, source_publication_date AS (
    SELECT MAX({{ adapter.quote('date') }}) AS max_publication_date
    FROM {{ ref('DIM_publication_date') }}
)
, join_status_max_date AS (
    SELECT *
    FROM source_accreditation_status
    CROSS JOIN source_publication_date
)
, aggregate_timespan AS (
    SELECT DIPLOMAT_HK
          ,publication_date
          ,max_publication_date
          ,accreditation_status
          ,MIN(date_since) AS on_post_start
    FROM join_status_max_date
    GROUP BY DIPLOMAT_HK, publication_date, max_publication_date, accreditation_status
)
, calculate_post_end AS (
    SELECT DIPLOMAT_HK
          ,publication_date
          ,on_post_start
          ,CASE WHEN accreditation_status = 'end' THEN publication_date ELSE NULL END AS on_post_end
          ,DATE_DIFF(publication_date, on_post_start, DAY) AS number_days
    FROM aggregate_timespan
)
SELECT *
FROM calculate_post_end
ORDER BY DIPLOMAT_HK, publication_date