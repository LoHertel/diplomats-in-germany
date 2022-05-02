{{ config(
      materialized='table'
) }}

WITH source_diplomat_hub AS (
    SELECT * 
    FROM {{ ref('hub_diplomat') }}
)
, source_diplomat_sat AS (
    SELECT * 
    FROM {{ ref('sat_diplomat') }}
)
, diplomat AS (
    SELECT hub.DIPLOMAT_HK
          ,sat.title
          ,sat.gender
          ,hub.name
          ,sat.position_name
          ,sat.order
          ,sat.partner_gender
          ,sat.partner_name
          ,hub.date_since
          ,hub.country
          ,sat.EFFECTIVE_FROM AS publication_date
    FROM source_diplomat_sat AS sat
    LEFT JOIN source_diplomat_hub AS hub
        ON sat.DIPLOMAT_HK = hub.DIPLOMAT_HK
)
, source_country_sat AS (
    SELECT COUNTRY_NAME_HK
          ,ISO_3166_1_alpha2
    FROM {{ ref('sat_country') }}
)
, source_diplomat_country_link AS (
    SELECT DIPLOMAT_HK
          ,COUNTRY_NAME_HK
    FROM {{ ref('link_diplomat_country') }}
)
, diplomat_country AS (
    SELECT diplomat.DIPLOMAT_HK
          ,diplomat.title
          ,diplomat.gender
          ,diplomat.name
          ,diplomat.position_name
          ,diplomat.order
          ,diplomat.partner_gender
          ,diplomat.partner_name
          ,diplomat.date_since
          ,country.ISO_3166_1_alpha2 AS country_ISO
          ,diplomat.publication_date
    FROM diplomat
    LEFT JOIN source_diplomat_country_link AS link
        ON diplomat.DIPLOMAT_HK = link.DIPLOMAT_HK
    LEFT JOIN source_country_sat AS country
        ON link.COUNTRY_NAME_HK = country.COUNTRY_NAME_HK
    GROUP BY diplomat.DIPLOMAT_HK
            ,diplomat.title
            ,diplomat.gender
            ,diplomat.name
            ,diplomat.position_name
            ,diplomat.order
            ,diplomat.partner_gender
            ,diplomat.partner_name
            ,diplomat.date_since
            ,country.ISO_3166_1_alpha2
            ,diplomat.publication_date
)
, source_diplomat_match AS (
    SELECT * 
    FROM {{ ref('diplomat_match') }}
) 
, diplomat_merged AS (
    SELECT COALESCE(merged.NEW_DIPLOMAT_HK, diplomat.DIPLOMAT_HK) AS DIPLOMAT_HK
          ,diplomat.title
          ,diplomat.gender
          ,diplomat.name
          ,diplomat.position_name
          ,diplomat.order
          ,diplomat.partner_gender
          ,diplomat.partner_name
          ,diplomat.date_since
          ,diplomat.country_ISO
          ,diplomat.publication_date
    FROM diplomat_country AS diplomat
    -- source_match contains a list of different DIPLOMAT_HK values, which belong to the same person and therefore need to be merged into one key
    LEFT JOIN source_diplomat_match AS merged
        ON diplomat.DIPLOMAT_HK = merged.DIPLOMAT_HK
)
SELECT *
FROM diplomat_merged
