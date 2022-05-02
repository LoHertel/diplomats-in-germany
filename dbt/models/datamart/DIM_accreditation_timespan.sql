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
/* , calculate_days AS (
    SELECT *
          ,CASE WHEN accreditation_status = 'begin' THEN 1
                ELSE DATE_DIFF(publication_date, LAG(publication_date) OVER(PARTITION BY DIPLOMAT_HK ORDER BY publication_date), DAY)
                END AS days
    FROM join_status_max_date
) */
, aggregate_timespan AS (
    SELECT DIPLOMAT_HK
          ,max_publication_date
          ,MIN(date_since) AS on_post_start
          ,MAX(publication_date) AS on_post_end
    FROM join_status_max_date
    GROUP BY DIPLOMAT_HK, max_publication_date
)
, calculate_post_end AS (
    SELECT DIPLOMAT_HK
          ,on_post_start
          ,CASE WHEN on_post_end < max_publication_date THEN on_post_end ELSE NULL END AS on_post_end
          ,CASE WHEN on_post_end < max_publication_date THEN DATE_DIFF(on_post_end, on_post_start, DAY)
                ELSE DATE_DIFF(max_publication_date, on_post_start, DAY)
                END AS number_days
    FROM aggregate_timespan
)
SELECT *
FROM calculate_post_end
ORDER BY DIPLOMAT_HK