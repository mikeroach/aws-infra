# vpc.sls
#
# Instantiate VPC and related basic AWS network infrastructure based on
# Salt pillar data contents by name.
#
# Created on 2017-06-04 by Mike Roach <mroach@got.net>.

# FIXME:
# - Idempotently manage all supported resources to account for manipulation
#   out of band from Salt.
# - Dissassociate/reassociate IGWs after initial creation.
# - Route table creation failure in dry run (test=True) from boto_vpc state.
# - Check for existence of pillar keys before using them.

# Set AWS credentials from pillar.
{% set aws_apikey = pillar['aws_api_key'] %}
{% set aws_apisecret = pillar['aws_api_secret'] %}

# Iterate through pillar data to create VPC and its dependent resources.
{% for vpc, vpc_args in pillar['vpc'].iteritems() %}

# Ensure each VPC exists with parameters defined in pillar.
ensure VPC {{ vpc }} exists:
  boto_vpc.present:
  - name: {{ vpc }}
  - keyid: {{ aws_apikey }}
  - key: {{ aws_apisecret }}
  - cidr_block: {{ vpc_args['cidr_block'] }}
  - region: {{ vpc_args['region'] }}
  - instance_tenancy: {{ vpc_args['instance_tenancy'] }}
  - dns_support: {{ vpc_args['dns_support'] }}
  - dns_hostnames: {{ vpc_args['dns_hostnames'] }}

# Create an internet gateway and associate to VPC if defined in pillar.
# FIXME: This doesn't dissassociate/reassociate IGWs after initial creation.
{% if vpc_args['internet_gateway'] is defined %}
{% set igw = vpc_args['internet_gateway'] %}

ensure igw {{ igw }} exists for vpc {{ vpc }}:
  boto_vpc.internet_gateway_present:
    - require:
      - ensure VPC {{ vpc }} exists
    - name: {{ igw }}
    - region: {{ vpc_args['region'] }}
    - keyid: {{ aws_apikey }}
    - key: {{ aws_apisecret }}
    - vpc_name: {{ vpc }}

{% endif %}

# Iterate through subnets defined in pillar and create.
{% for subnet, subnet_args in vpc_args['subnets'].iteritems() %}
ensure subnet {{ subnet }} exists for vpc {{ vpc }}:
    boto_vpc.subnet_present:
    - require:
      - ensure VPC {{ vpc }} exists
    - name: {{ vpc }}-{{ subnet }}
    - region: {{ vpc_args['region'] }}
    - keyid: {{ aws_apikey }}
    - key: {{ aws_apisecret }}
    - cidr_block: {{ subnet_args['cidr_block'] }}
    - vpc_name:  {{ vpc }}
    - availability_zone: {{ subnet_args['availability_zone'] }}
{% endfor %}

# Salt boto_vpc module creates default VPC route table with format
# '${vpc_name}-default-table'; vpc-route_table-table
# format accommodates this.

# FIXME: Dry runs with test=true will trigger failure due to
# 'IndexError: list index out of range' from boto_vpc state.
# First execution and subsequent test runs succeed.

{% for route_table, route_table_args in vpc_args['route_tables'].iteritems() %}
ensure route table {{ route_table }} exists for vpc {{ vpc }}:
  boto_vpc.route_table_present:
    - require:
      - ensure VPC {{ vpc }} exists
      {% for subnet in route_table_args['subnet_associations'] -%}
            - ensure subnet {{ subnet }} exists for vpc {{ vpc }}
      {% endfor %}
    - name: {{ vpc }}-{{ route_table }}-table
    - region: {{ vpc_args['region'] }}
    - keyid: {{ aws_apikey }}
    - key: {{ aws_apisecret }}
    - vpc_name: {{ vpc }}
    # Mind the whitespace formatting
    # http://jinja.pocoo.org/docs/latest/templates/#whitespace-control
    {% if route_table_args['routes'] is defined %}
    - routes:
      {% for route, route_args in route_table_args['routes'].iteritems() %}
      - destination_cidr_block: {{ route }}
        {% for method, target in route_args.items() -%}
        {{ method }}: {{ target }}
        {% endfor -%}
      {%- endfor %}
    {% endif %}
    - subnet_names:
      {% for subnet in route_table_args['subnet_associations'] -%}
      - {{ vpc }}-{{ subnet }}
      {% endfor %}
{% endfor %}

{% endfor %}
