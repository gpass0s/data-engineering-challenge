{{
    config(
        materialized='table',
    )
}}

with distinct_fire_incidents as (
    select distinct
        incident_number,
        battalion,
        year(incident_date) as year
   from {{ ref('san_francisco_fire_incidents') }}
),
fire_incidents_per_year_battalion as (
    select
        count(incident_number) as incidents,
        battalion,
        to_varchar(year) as year
    from distinct_fire_incidents
    group by year, battalion
)
select * from fire_incidents_per_year_battalion order by year