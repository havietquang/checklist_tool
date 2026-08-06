{% test unique_combination_of_columns(model, combination_of_columns, date_filter=none) %}
    {% set columns = adapter.get_columns_in_relation(model) | map(attribute='name') | map('lower') | list %}
    {% if date_filter is none %}
        {% if 'snapshot_date' in columns %}
            {% set date_filter = 'snapshot_date' %}
        {% elif 'source_event_date' in columns %}
            {% set date_filter = 'source_event_date' %}
        {% endif %}
    {% endif %}
    select
        {{ combination_of_columns | join(', ') }},
        count(*) as cnt
    from {{ model }}
    {% if date_filter is not none %}
    where {{ date_filter }} = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    {% endif %}
    group by {{ combination_of_columns | join(', ') }}
    having count(*) > 1
{% endtest %}