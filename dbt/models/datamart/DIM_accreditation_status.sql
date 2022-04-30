{{ config(
      materialized='table'
) }}

WITH source_publication_date AS (
    SELECT {{ adapter.quote('date') }} AS dte
          ,{{ adapter.quote('rank') }} AS rnk
          ,{{ adapter.quote('max') }} AS mx
    FROM {{ ref('DIM_publication_date') }}
),
source_diplomats AS (
    SELECT DIPLOMAT_HK
          ,publication_date
    FROM {{ ref('DIM_diplomat') }} 
),
grouped AS (
    SELECT * 
        -- grouping sequential numbers of rank into an interval (business meaning: a complete timespan in which the diplomat was stationed in Germany)
        ,dt.rnk - ROW_NUMBER() OVER(PARTITION BY dip.DIPLOMAT_HK ORDER BY dt.dte) AS grp
    FROM source_diplomats AS dip
    LEFT JOIN source_publication_date AS dt ON dip.publication_date = dt.dte
)
SELECT DIPLOMAT_HK
      ,publication_date
      -- mark first date of interval with status 'new' unless it is the first available date in the dataset (in this we don't know if a diplomat came on that point of time)
      -- note: grp > LAG(grp) will return NULL on the first row, therefore we need to encapsulate with NULLIF to accept NULL and TRUE as valid return values
      ,CASE WHEN rnk > 1 AND NULLIF(grp > LAG(grp) OVER(PARTITION BY DIPLOMAT_HK ORDER BY rnk), TRUE) IS NULL THEN 'begin'
            -- mark last date of interval with status 'leave' unless it is the first available date in the dataset (in this we don't know if a diplomat came on that point of time)
            WHEN rnk < mx AND NULLIF(grp < LEAD(grp) OVER(PARTITION BY DIPLOMAT_HK ORDER BY rnk), TRUE) IS NULL THEN 'end'
            ELSE 'continue' END AS accreditation_status
FROM grouped
ORDER BY DIPLOMAT_HK, rnk