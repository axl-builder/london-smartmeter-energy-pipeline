{{ config(
    materialized='view' 
) }}

-- 1. Import the source using the dbt macro
with raw_daily as (
    select * from {{ source('raw_london_energy', 'daily_consumption_ext') }}
),

-- 2. Clean and standardize the table
renamed_and_casted as (
    select
        -- Household identifier (converted to lowercase for consistency)
        LCLid as household_id,
        
        -- Cast date string to a proper BigQuery DATE format
        cast(day as date) as consumption_date,
        
        -- Cast energy metrics to decimal numbers (NUMERIC)
        cast(energy_median as numeric) as energy_median,
        cast(energy_mean as numeric) as energy_mean,
        cast(energy_max as numeric) as energy_max,
        cast(energy_count as integer) as energy_count,
        cast(energy_std as numeric) as energy_std,
        cast(energy_sum as numeric) as energy_sum,
        cast(energy_min as numeric) as energy_min

    from raw_daily
    -- Filter out empty or corrupted rows from the CSV source
    where LCLid is not null
    and energy_sum is not null
)

-- 3. Final output
select * from renamed_and_casted