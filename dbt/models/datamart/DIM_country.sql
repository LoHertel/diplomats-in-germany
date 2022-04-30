{{ config(
      materialized='table'
) }}

WITH source_country_hub AS (
    SELECT * 
    FROM {{ ref('hub_country') }}
)
, source_country_sat AS (
    SELECT * 
    FROM {{ ref('sat_country') }}
)
, country AS (
    SELECT sat.ISO_3166_1_alpha2
          ,sat.ISO_3166_1_alpha3
          ,sat.name_EN
          ,hub.name_DE
          ,sat.full_name_EN
          ,sat.full_name_DE
    FROM source_country_sat AS sat
    LEFT JOIN source_country_hub AS hub
        ON sat.COUNTRY_NAME_HK = hub.COUNTRY_NAME_HK
)
SELECT * 
FROM country
