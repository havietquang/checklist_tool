{% macro get_staging_config(source_name, source_table) %}
  {%- if not execute -%}
    {{- return({'source_event_date_col': none, 'source_event_date_dttype': 'str+date'}) -}}
  {%- endif -%}

  {%- set sources = graph.get('sources', {}) -%}
  {%- set ns = namespace(source_node=none) -%}

  {%- for node in sources.values() -%}
    {%- if node.source_name == source_name and node.name == source_table -%}
      {%- set ns.source_node = node -%}
    {%- endif -%}
  {%- endfor -%}

  {%- if ns.source_node is none -%}
    {%- do exceptions.raise_compiler_error('Source not found: ' ~ source_name ~ '.' ~ source_table) -%}
  {%- endif -%}

  {%- set meta = ns.source_node.meta -%}
  {%- set current_mode = var('run_mode', 'daily') -%}

  {%- if meta is defined and meta.get('run_mode') is not none -%}
    {%- set run_mode_map = meta.get('run_mode') -%}
    {%- set mode_config = run_mode_map.get(current_mode) -%}

    {%- if mode_config is none -%}
      {{- return({'source_event_date_col': none, 'source_event_date_dttype': 'str+date'}) -}}
    {%- endif -%}

    {%- set ns2 = namespace(col=none, dttype='str+date') -%}
    {%- if mode_config is iterable and mode_config is not string -%}
      {%- for cfg_item in mode_config -%}
        {%- if cfg_item is mapping -%}
          {%- if 'source_event_date_col' in cfg_item -%}
            {%- set ns2.col = cfg_item['source_event_date_col'] -%}
          {%- endif -%}
          {%- if 'source_event_date_dttype' in cfg_item -%}
            {%- set ns2.dttype = cfg_item['source_event_date_dttype'] -%}
          {%- endif -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif -%}

    {%- if ns2.col is string and ns2.col | lower in ['none', 'null', 'fullload', 'full load'] -%}
      {{- return({'source_event_date_col': none, 'source_event_date_dttype': ns2.dttype}) -}}
    {%- endif -%}

    {{- return({'source_event_date_col': ns2.col, 'source_event_date_dttype': ns2.dttype}) -}}

  {%- else -%}
    {%- set config = none -%}
    {%- if meta is defined -%}
      {%- set config = meta.get('source_event_date_col') -%}
    {%- endif -%}
    {%- if config is none and ns.source_node.config is defined and ns.source_node.config.meta is defined -%}
      {%- set config = ns.source_node.config.meta.get('source_event_date_col') -%}
    {%- endif -%}

    {%- if config is none -%}
      {{- return({'source_event_date_col': none, 'source_event_date_dttype': 'str+date'}) -}}
    {%- endif -%}

    {%- if config is mapping -%}
      {%- set col = config.get(current_mode) -%}
    {%- else -%}
      {%- set col = config -%}
    {%- endif -%}

    {%- if col is string and col | lower in ['none', 'null', 'fullload', 'full load'] -%}
      {{- return({'source_event_date_col': none, 'source_event_date_dttype': 'str+date'}) -}}
    {%- endif -%}

    {{- return({'source_event_date_col': col, 'source_event_date_dttype': 'str+date'}) -}}
  {%- endif -%}
{% endmacro %}


{% macro get_source_event_date_col(source_name, source_table, required=false) %}
  {%- if not execute -%}
    {{- return(none) -}}
  {%- endif -%}

  {%- set sources = graph.get('sources', {}) -%}
  {%- set ns = namespace(source_node=none) -%}

  {%- for node in sources.values() -%}
    {%- if node.source_name == source_name and node.name == source_table -%}
      {%- set ns.source_node = node -%}
    {%- endif -%}
  {%- endfor -%}

  {%- if ns.source_node is none -%}
    {%- do exceptions.raise_compiler_error('Source not found: ' ~ source_name ~ '.' ~ source_table) -%}
  {%- endif -%}

  {%- set source_node = ns.source_node -%}
  {%- set meta = source_node.meta -%}

  {%- if meta is defined and meta.get('run_mode') is not none -%}
    {%- set staging_config = get_staging_config(source_name, source_table) -%}
    {{- return(staging_config.source_event_date_col) -}}
  {%- endif -%}

  {%- set config = none -%}
  {%- if meta is defined -%}
    {%- set config = meta.get('source_event_date_col') -%}
  {%- endif -%}
  {%- if config is none and source_node.config is defined and source_node.config.meta is defined -%}
    {%- set config = source_node.config.meta.get('source_event_date_col') -%}
  {%- endif -%}

  {%- if config is none -%}
    {{- return(none) -}}
  {%- endif -%}

  {%- if config is mapping -%}
    {%- if 'backfill' not in config or 'daily' not in config -%}
      {%- do exceptions.raise_compiler_error(
        'source_event_date_col for source ' ~ source_name ~ '.' ~ source_table ~
        ' must define both backfill and daily keys.'
      ) -%}
    {%- endif -%}

    {%- set source_event_date_col = config.get('backfill') if var('run_mode') == 'backfill' else config.get('daily') -%}
  {%- else -%}
    {%- set source_event_date_col = config -%}
  {%- endif -%}

  {%- if source_event_date_col is string and source_event_date_col | lower in ['none', 'null', 'fullload', 'full load', 'kickoff fullload', 'kickoff full load'] -%}
    {{- return(none) -}}
  {%- endif -%}

  {{- return(source_event_date_col) -}}
{% endmacro %}
