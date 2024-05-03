{% set partitions_to_replace = ['current_date'] %}
{% for i in range(var('static_incremental_days')) %}
    {% set partitions_to_replace = partitions_to_replace.append('date_sub(current_date, interval ' + (i+1)|string + ' day)') %}
{% endfor %}
{{ log("this.name: " ~ this.name, True)}}
{{
    config(
        pre_hook="{{ ga4.combine_property_data() }}" if var('combined_dataset', false) else "",
        materialized = 'incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            "field": "occurrence_date",
            "data_type": "date",
        },
        partitions = partitions_to_replace,
    )
}}

with source as (
    select
        pseudo_user_id
        , stream_id 
        {{ ga4.base_select_usr_source() }}
    from {{ source('ga4', 'pseudonymous_users') }}
    {% if is_incremental() %}
        where parse_date('%Y%m%d', left(replace(_table_suffix, 'intraday_', ''), 8)) in ({{ partitions_to_replace | join(',') }})
    {% endif %}
)

select * from source