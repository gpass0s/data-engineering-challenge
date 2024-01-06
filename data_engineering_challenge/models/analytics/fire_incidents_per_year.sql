{{
    config(
        materialized='table',
    )
}}

with distinct_fire_incidents as (
    select distinct
        incident_number,
        year(incident_date) as year
   from {{ ref('san_francisco_fire_incidents') }}
),
fire_incidents_per_year as (
    select
        count(incident_number) as incidents,
        to_varchar(year) as year
    from distinct_fire_incidents
    group by year
)
select * from fire_incidents_per_year order by year
