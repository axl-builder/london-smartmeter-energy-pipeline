{{ config(materialized='table', schema='prod_london_energy') }}

with half_hourly_data as (
    -- Usamos tu nombre exacto de tabla externa
    select * from {{ source('raw_london_energy', 'hh_consumption_ext') }}
),

households as (
    select 
        LCLid as household_id, 
        Acorn_grouped as acorn_group 
    from {{ source('raw_london_energy', 'informations_households') }}
),

hourly_aggregated as (
    select
        EXTRACT(HOUR FROM h.tstp) as hour_of_day,
        hh.acorn_group,
        avg(h.energy_kwh) as avg_kwh_per_household
    from half_hourly_data h
    inner join households hh 
        on h.LCLid = hh.household_id
    where h.energy_kwh is not null
    group by 1, 2
)

select * from hourly_aggregated