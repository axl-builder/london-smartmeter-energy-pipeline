{{ config(materialized='view') }}

with raw_weather as (
    select * from {{ source('raw_london_energy', 'weather_daily_darksky') }}
),

casted as (
    select
        cast(cast(time as timestamp) as date) as weather_date,
        
        -- ACÁ ESTÁ EL ARREGLO: usamos los nombres normalizados por dlt
        cast(temperature_max as numeric) as max_temp_celsius,
        cast(temperature_min as numeric) as min_temp_celsius,
        cast(precip_type as numeric) as precip_type,
        
        icon as weather_summary

    from raw_weather
    where time is not null
)

select * from casted