{{ config(
    materialized='table',
    schema='prod_london_energy',
    partition_by={
      "field": "consumption_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["acorn_group"]
) }}

with daily_consumption as (
    select * from {{ ref('stg_daily_consumption') }}
),

households as (
    select 
        lc_lid as household_id, 
        acorn_grouped as acorn_group 
    from {{ source('raw_london_energy', 'informations_households') }}
),

joined_data as (
    select
        c.consumption_date,
        h.acorn_group,
        sum(c.energy_sum) as total_kwh,
        avg(c.energy_sum) as avg_kwh_per_household,
        count(distinct c.household_id) as active_households
    from daily_consumption c
    inner join households h 
        on c.household_id = h.household_id
    group by 1, 2
)

select * from joined_data