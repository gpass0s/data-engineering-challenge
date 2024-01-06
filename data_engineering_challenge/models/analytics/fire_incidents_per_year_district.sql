{{
    config(
        materialized='table',
    )
}}

with distinct_fire_incidents as (
    select distinct
        incident_number,
        neighborhood_district,
        year(incident_date) as year
   from {{ ref('san_francisco_fire_incidents') }}
),
fire_incidents_per_year_district as (
    select
        count(incident_number) as incidents,
        neighborhood_district,
        to_varchar(year) as year
    from distinct_fire_incidents
    group by year, neighborhood_district
)
select * from fire_incidents_per_year_district order by year