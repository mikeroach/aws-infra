# pubkey.sls
#
# Manage SSH keypairs based on Salt pillar contents.
# For defined regions, ensure active keypairs exist and revoked ones don't.
#
# Created on 2017-06-04 by Mike Roach <mroach@got.net>.

# FIXME:
# - Check for existence of pillar keys before using them.

# Set AWS credentials from pillar.
{% set aws_apikey = pillar['aws_api_key'] %}
{% set aws_apisecret = pillar['aws_api_secret'] %}

# Iterate through the list of active keypairs defined in pillar.
{% for name, key in pillar['pubkey']['active'].iteritems() %}

# For each active keypair, loop through the list of regions defined in pillar to
# ensure it exists there via the boto_ec2 module.
{% for region in pillar['pubkey']['regions'] %}

ensure {{ name }} is present in {{ region }}:
  boto_ec2.key_present:
    - name: {{ name }}
    - upload_public: {{ key }}
    - region: {{ region }}
    - keyid: {{ aws_apikey }}
    - key: {{ aws_apisecret }}

{% endfor %}
{% endfor %}

# Iterate through the list of revoked keypairs defined in pillar.
{% for name, pubkey in pillar['pubkey']['revoked'].iteritems() %}

# For each revoked keypair, loop through the list of regions defined in pillar
# to ensure it's absent there via the boto_ec2 module.
{% for region in pillar['pubkey']['regions'] %}

ensure {{ name }} is revoked in {{ region }}:
  boto_ec2.key_absent:
    - name: {{ name }}
    - region: {{ region }}
    - keyid: {{ aws_apikey }}
    - key: {{ aws_apisecret }}

{% endfor %}
{% endfor %}
