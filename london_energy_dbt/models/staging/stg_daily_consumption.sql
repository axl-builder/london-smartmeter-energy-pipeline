{{ config(
    materialized='view' 
) }}

-- 1. Importamos la fuente usando la macro de dbt
with raw_daily as (
    select * from {{ source('raw_london_energy', 'daily_consumption_ext') }}
),

-- 2. Limpiamos y estandarizamos la tabla
renamed_and_casted as (
    select
        -- Identificador de la casa (lo pasamos a minúsculas para prolijidad)
        LCLid as household_id,
        
        -- Convertimos el texto de la fecha a un formato DATE real de BigQuery
        cast(day as date) as consumption_date,
        
        -- Casteamos las métricas de energía a números decimales (NUMERIC)
        cast(energy_median as numeric) as energy_median,
        cast(energy_mean as numeric) as energy_mean,
        cast(energy_max as numeric) as energy_max,
        cast(energy_count as integer) as energy_count,
        cast(energy_std as numeric) as energy_std,
        cast(energy_sum as numeric) as energy_sum,
        cast(energy_min as numeric) as energy_min

    from raw_daily
    -- Filtramos posibles filas vacías o corruptas que hayan venido del CSV
    where LCLid is not null
    and energy_sum is not null
)

-- 3. Resultado final
select * from renamed_and_casted