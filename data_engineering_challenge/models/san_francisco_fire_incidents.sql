{{
    config(
        materialized='incremental',
        unique_key='incident_number',
        transient=false
    )
}}
with san_francisco_fire_incidents as (
    select
        content:"incident_number"::integer as incident_number,
        content:"exposure_number"::integer as exposure_number,
        content:"id"::varchar as id,
        content:"address"::varchar as address,
        content:"incident_date"::date as incident_date,
        content:"call_number"::varchar as call_number,
        content:"alarm_dttm"::timestamp as alarm_dttm,
        content:"arrival_dttm"::timestamp as arrival_dttm,
        content:"close_dttm"::timestamp as close_dttm,
        content:"city"::varchar as city,
        content:"zipcode"::varchar as zipcode,
        content:"battalion"::varchar as battalion,
        content:"station_area"::varchar as station_area,
        content:"box"::varchar as box,
        content:"suppression_units"::integer as suppression_units,
        content:"suppression_personnel"::integer as suppression_personnel,
        content:"ems_units"::integer as ems_units,
        content:"ems_personnel"::integer as ems_personnel,
        content:"other_units"::integer as other_units,
        content:"other_personnel"::integer as other_personnel,
        content:"first_unit_on_scene"::varchar as first_unit_on_scene,
        content:"estimated_property_loss"::integer as estimated_property_loss,
        content:"estimated_contents_loss"::integer as estimated_contents_loss,
        content:"fire_fatalities"::integer as fire_fatalities,
        content:"fire_injuries"::integer as fire_injuries,
        content:"civilian_fatalities"::integer as civilian_fatalities,
        content:"number_of_alarms"::integer as number_of_alarms,
        content:"primary_situation"::varchar as primary_situation,
        content:"mutual_aid"::varchar as mutual_aid,
        content:"action_taken_primary"::varchar as action_taken_primary,
        content:"action_taken_other"::varchar as action_taken_other,
        content:"detector_alerted_occupants"::varchar as detector_alerted_occupants,
        content:"property_use"::varchar as property_use,
        content:"area_of_fire_origin"::varchar as area_of_fire_origin,
        content:"ignition_cause"::varchar as ignition_cause,
        content:"ignition_factor_primary"::varchar as ignition_factor_primary,
        content:"ignition_factor_secondary"::varchar as ignition_factor_secondary,
        content:"heat_source"::varchar as heat_source,
        content:"item_first_ignited"::varchar as item_first_ignited,
        content:"human_factors_associated_with_ignition"::varchar as human_factors_associated_with_ignition,
        content:"structure_type"::varchar as structure_type,
        content:"structure_status"::varchar as structure_status,
        content:"floor_of_fire_origin"::varchar as floor_of_fire_origin,
        content:"fire_spread"::varchar as fire_spread,
        content:"no_flame_spead"::varchar as no_flame_spead,
        content:"number_of_floors_with_minimum_damage"::integer as number_of_floors_with_minimum_damage,
        content:"number_of_floors_with_significant_damage"::integer as number_of_floors_with_significant_damage,
        content:"number_of_floors_with_heavy_damage"::integer as number_of_floors_with_heavy_damage,
        content:"number_of_floors_with_extreme_damage"::integer as number_of_floors_with_extreme_damage,
        content:"detectors_present"::varchar as detectors_present,
        content:"detector_type"::varchar as detector_present,
        content:"detector_operation"::varchar as detector_operation,
        content:"detector_effectiveness"::varchar as detector_effectiveness,
        content:"detector_failure_reason"::varchar as detector_failure_reason,
        content:"automatic_extinguishing_system_present"::varchar as automatic_extinguishing_system_present,
        content:"automatic_extinguishing_system_type"::varchar as automatic_extinguishing_system_type,
        content:"automatic_extinguishing_failure_reason"::varchar as automatic_extinguishing_failure_reason,
        content:"number_of_sprinkler_heads_operating"::integer as number_of_sprinkler_heads_operating,
        content:"supervisor_district"::varchar as supervisor_district,
        content:"neighborhood_district"::varchar as neighborhood_district,
        content:"point"."coordinates"::variant as coordinates,
        content:"lng"::float as longitude,
        content:"lat"::float as latitude,
        ingestion_time::timestamp as ingestion_time
    from {{ source('landing', 's3_landing_table') }}
)
select * from san_francisco_fire_incidents