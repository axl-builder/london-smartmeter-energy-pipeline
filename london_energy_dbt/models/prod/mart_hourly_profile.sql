{{ config(materialized='table', schema='prod_london_energy') }}

with half_hourly_wide as (
    select * from {{ source('raw_london_energy', 'hh_consumption_ext') }}
),

-- 1. UNPIVOTING 48 COLUMNS INTO ROWS
unpivoted_data as (
    select
        LCLid as household_id,
        day as consumption_date,
        -- Extract the column number and divide by 2 to get the hour of the day (0 to 23)
        DIV(CAST(REPLACE(hh_period, 'hh_', '') AS INT64), 2) as hour_of_day,
        energy_kwh
    from half_hourly_wide
    UNPIVOT(energy_kwh FOR hh_period IN (
        hh_0, hh_1, hh_2, hh_3, hh_4, hh_5, hh_6, hh_7, hh_8, hh_9,
        hh_10, hh_11, hh_12, hh_13, hh_14, hh_15, hh_16, hh_17, hh_18, hh_19,
        hh_20, hh_21, hh_22, hh_23, hh_24, hh_25, hh_26, hh_27, hh_28, hh_29,
        hh_30, hh_31, hh_32, hh_33, hh_34, hh_35, hh_36, hh_37, hh_38, hh_39,
        hh_40, hh_41, hh_42, hh_43, hh_44, hh_45, hh_46, hh_47
    ))
),

-- 2. AGGREGATING HALF-HOURLY DATA INTO FULL-HOUR TOTALS
hourly_sums as (
    select
        household_id,
        consumption_date,
        hour_of_day,
        sum(energy_kwh) as hourly_kwh
    from unpivoted_data
    group by 1, 2, 3
),

-- 3. FETCHING HOUSEHOLD INFORMATION (ACORN)
households as (
    select 
        lc_lid as household_id, 
        -- Cleaning up Kaggle's messy data:
        CASE 
            WHEN acorn_grouped IN ('ACORN-U', 'ACORN-') THEN 'Unknown'
            WHEN acorn_grouped IS NULL THEN 'Unknown'
            ELSE acorn_grouped 
        END as acorn_group 
    from {{ source('raw_london_energy', 'informations_households') }}
),

-- 4. JOINING AND AVERAGING DATA FOR FINAL VISUALIZATION
hourly_aggregated as (
    select
        hs.hour_of_day,
        h.acorn_group,
        avg(hs.hourly_kwh) as avg_kwh_per_household
    from hourly_sums hs
    inner join households h 
        on hs.household_id = h.household_id
    group by 1, 2
)

select * from hourly_aggregated