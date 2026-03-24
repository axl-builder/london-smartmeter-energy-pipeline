{{ config(
    materialized='table',
    schema='prod_london_energy',
    partition_by={
      "field": "consumption_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["household_id", "is_holiday"] 
) }}

with daily_energy as (
    -- Referenciamos a nuestro modelo de Staging (ya limpio)
    select * from {{ ref('stg_daily_consumption') }}
),

daily_weather as (
    -- Referenciamos a nuestro modelo de Staging (ya limpio)
    select * from {{ ref('stg_weather_daily') }}
),

holidays as (
    -- Los feriados los traemos directo del RAW porque son simples
    select 
        cast(Bank_holidays as date) as holiday_date,
        Type as holiday_name
    from {{ source('raw_london_energy', 'uk_bank_holidays') }}
),

final_mart as (
    select
        e.household_id,
        e.consumption_date,
        e.energy_sum as total_kwh,
        
        w.max_temp_celsius,
        w.min_temp_celsius,
        w.weather_summary,
        
        -- Marcamos si el día fue feriado o no
        case when h.holiday_date is not null then true else false end as is_holiday,
        h.holiday_name

    from daily_energy e
    -- Hacemos LEFT JOIN para no perder días de consumo si falta el clima
    inner join daily_weather w 
        on e.consumption_date = w.weather_date
    left join holidays h 
        on e.consumption_date = h.holiday_date
)

select * from final_mart