# aws-infra
Basic formula to manage AWS infrastructure. Relies heavily on boto states.
Tested with Salt 2016.11.5.

Created on 2017-06-04 by Mike Roach <mroach@got.net>.

- vpc.sls - Instantiate VPC and related basic AWS network infrastructure
- pubkey.sls - Manage SSH keypairs across AWS regions

TODO:
- Comply with Salt formula best practices
- Idempotently manage supported resources; change and/or delete objects
  manipulated out of band from Salt
- Security groups
- IPv6
- NAT gateways
