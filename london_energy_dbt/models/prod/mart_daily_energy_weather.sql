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
    -- Reference our Staging model (already cleaned)
    select * from {{ ref('stg_daily_consumption') }}
),

daily_weather as (
    -- Reference our Staging model (already cleaned)
    select * from {{ ref('stg_weather_daily') }}
),

holidays as (
    -- The holidays we fetch directly from the RAW data because they are simple
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
        
        -- Flag whether the day was a holiday or not
        case when h.holiday_date is not null then true else false end as is_holiday,
        h.holiday_name

    from daily_energy e
    -- Using LEFT JOIN to avoid losing consumption data if weather is missing
    inner join daily_weather w 
        on e.consumption_date = w.weather_date
    left join holidays h 
        on e.consumption_date = h.holiday_date
)

select * from final_mart