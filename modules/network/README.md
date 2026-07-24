# AWS Network Module

Reusable Terraform module responsible for provisioning the AWS network foundation for the **Cloud Platform Portfolio**.

The module creates a highly available, multi-AZ VPC architecture with public and private subnets, Internet connectivity for public resources, and outbound Internet access for private workloads through dedicated NAT Gateways.

---

## Architecture

The module implements the following network architecture:

```text
                              Internet
                                  |
                           Internet Gateway
                                  |
                         Public Route Table
                                  |
                 +----------------+----------------+
                 |                                 |
        Public Subnet A                    Public Subnet B
                 |                                 |
           NAT Gateway A                     NAT Gateway B
                 |                                 |
        Private Route Table A              Private Route Table B
                 |                                 |
        Private Subnet A                   Private Subnet B
```

Each Availability Zone contains its own public and private network layer.

For private outbound connectivity, each Availability Zone uses its own NAT Gateway and private route table.

---

## Design Goals

This module was designed around the following principles:

- High availability across multiple Availability Zones
- Isolation between public and private workloads
- Independent outbound connectivity per Availability Zone
- Predictable subnet allocation
- Stable Terraform resource addressing
- Reusable module design
- Consistent resource naming
- Consistent tagging
- Minimal hard-coded infrastructure configuration
- Clear separation between environment configuration and module implementation

---

## Resources Created

The module creates the following AWS resources:

| Terraform Resource | Description |
|---|---|
| `aws_vpc.this` | Main VPC |
| `aws_internet_gateway.this` | Internet Gateway attached to the VPC |
| `aws_subnet.public` | Public subnet per Availability Zone |
| `aws_subnet.private` | Private subnet per Availability Zone |
| `aws_route_table.public` | Shared route table for public subnets |
| `aws_route_table_association.public` | Associates public subnets with the public route table |
| `aws_eip.nat` | Elastic IP per NAT Gateway |
| `aws_nat_gateway.this` | NAT Gateway per Availability Zone |
| `aws_route_table.private` | Private route table per Availability Zone |
| `aws_route_table_association.private` | Associates each private subnet with its corresponding route table |

---

## Public Network Flow

Public subnets use a shared public route table.

The default route is:

```text
0.0.0.0/0 -> Internet Gateway
```

Traffic flow:

```text
Public Workload
      |
      v
Public Subnet
      |
      v
Public Route Table
      |
      v
Internet Gateway
      |
      v
Internet
```

Public subnets are configured with:

```hcl
map_public_ip_on_launch = true
```

This allows supported resources launched into those subnets to automatically receive public IPv4 addresses.

---

## Private Network Flow

Private workloads do not communicate directly with the Internet Gateway.

Instead, outbound traffic uses a NAT Gateway:

```text
Private Workload
       |
       v
Private Subnet
       |
       v
Private Route Table
       |
       | 0.0.0.0/0
       v
NAT Gateway
       |
       v
Public Subnet
       |
       v
Internet Gateway
       |
       v
Internet
```

Private subnets are explicitly configured with:

```hcl
map_public_ip_on_launch = false
```

This design allows private workloads to initiate outbound connections without exposing them directly to inbound Internet connections.

Typical workloads for these subnets include:

- EKS worker nodes
- ECS workloads
- Application servers
- Internal services
- Databases, depending on the architecture

---

## High Availability

The module requires at least two Availability Zones:

```hcl
validation {
  condition     = length(var.availability_zones) >= 2
  error_message = "At least two Availability Zones are required."
}
```

For example:

```text
Availability Zone A
├── Public Subnet A
├── Elastic IP A
├── NAT Gateway A
├── Private Route Table A
└── Private Subnet A

Availability Zone B
├── Public Subnet B
├── Elastic IP B
├── NAT Gateway B
├── Private Route Table B
└── Private Subnet B
```

Each private subnet uses the NAT Gateway from the same Availability Zone:

```text
Private Subnet A
        |
Private Route Table A
        |
NAT Gateway A
```

and:

```text
Private Subnet B
        |
Private Route Table B
        |
NAT Gateway B
```

This avoids making private workloads in one Availability Zone dependent on a NAT Gateway located in another Availability Zone.

It also avoids unnecessary cross-AZ traffic for Internet-bound workloads.

### Availability vs. Cost

Using one NAT Gateway per Availability Zone improves fault isolation and availability, but increases AWS costs.

For production workloads where availability is a business requirement, this architecture provides stronger resilience.

For development or non-critical environments, a future version of the module could support a single shared NAT Gateway to reduce costs.

---

## Dynamic CIDR Allocation

Subnet CIDRs are calculated automatically using Terraform's `cidrsubnet()` function.

The module does not require every subnet CIDR to be manually configured.

The public subnet calculation is:

```hcl
cidrsubnet(var.cidr, 4, index)
```

Private subnet indexes begin after all public subnet indexes:

```hcl
cidrsubnet(
  var.cidr,
  4,
  index + length(var.availability_zones)
)
```

For example, with:

```hcl
cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]
```

the resulting layout is:

```text
VPC
10.0.0.0/16

Public Subnet A
10.0.0.0/20

Public Subnet B
10.0.16.0/20

Private Subnet A
10.0.32.0/20

Private Subnet B
10.0.48.0/20
```

With three Availability Zones, the same logic continues automatically:

```text
Public A  -> index 0
Public B  -> index 1
Public C  -> index 2

Private A -> index 3
Private B -> index 4
Private C -> index 5
```

This keeps subnet allocation deterministic and avoids CIDR overlap within the generated layout.

---

## Internal Subnet Model

The module generates an internal subnet data structure:

```hcl
locals {
  subnet_layout = {
    public = {
      for index, az in var.availability_zones :
      az => {
        cidr = cidrsubnet(var.cidr, 4, index)
      }
    }

    private = {
      for index, az in var.availability_zones :
      az => {
        cidr = cidrsubnet(
          var.cidr,
          4,
          index + length(var.availability_zones)
        )
      }
    }
  }
}
```

Conceptually, for two Availability Zones this produces:

```text
public
├── us-east-1a -> CIDR A
└── us-east-1b -> CIDR B

private
├── us-east-1a -> CIDR C
└── us-east-1b -> CIDR D
```

The Availability Zone becomes the stable key used throughout the module.

---

## Why `for_each`?

Resources that exist once per Availability Zone use `for_each`.

For example:

```hcl
resource "aws_subnet" "private" {
  for_each = local.subnet_layout.private

  availability_zone = each.key
  cidr_block        = each.value.cidr
}
```

This produces stable Terraform addresses such as:

```text
aws_subnet.private["us-east-1a"]
aws_subnet.private["us-east-1b"]
```

Instead of relying on numeric positions:

```text
aws_subnet.private[0]
aws_subnet.private[1]
```

Using stable keys makes relationships between resources easier to understand and maintain.

---

## Resource Correlation by Availability Zone

The same Availability Zone key is used to correlate related resources.

For example:

```text
aws_subnet.private["us-east-1a"]

aws_route_table.private["us-east-1a"]

aws_nat_gateway.this["us-east-1a"]

aws_eip.nat["us-east-1a"]
```

This allows Terraform expressions such as:

```hcl
nat_gateway_id = aws_nat_gateway.this[each.key].id
```

and:

```hcl
route_table_id = aws_route_table.private[each.key].id
```

For `us-east-1a`, Terraform therefore creates the relationship:

```text
Private Subnet A
       |
       v
Private Route Table A
       |
       v
NAT Gateway A
       |
       v
Elastic IP A
```

The same pattern is automatically repeated for every configured Availability Zone.

---

## Internet Gateway

The Internet Gateway is attached to the VPC:

```text
VPC
 |
 +-- Internet Gateway
```

Attaching an Internet Gateway alone does not make a subnet public.

The public route table contains:

```text
0.0.0.0/0 -> Internet Gateway
```

and is associated with the public subnets.

Together, these components provide the public routing layer.

---

## NAT Gateways

Each Availability Zone receives its own NAT Gateway.

The NAT Gateway is created inside the corresponding public subnet:

```text
Public Subnet A -> NAT Gateway A
Public Subnet B -> NAT Gateway B
```

Each private route table then sends Internet-bound traffic to the NAT Gateway from the same Availability Zone.

The default private route is:

```text
0.0.0.0/0 -> NAT Gateway
```

---

## Elastic IPs

Each NAT Gateway receives its own Elastic IP.

This provides a stable public source IP for outbound connections.

This is particularly useful when integrating with external systems that require IP allowlisting.

Example:

```text
Private Application
        |
        v
NAT Gateway
        |
        | Elastic IP
        v
External System
```

The external system can allow traffic originating from the NAT Gateway Elastic IP.

---

## Terraform Dependency Management

The module primarily relies on Terraform's implicit dependency graph.

For example:

```hcl
vpc_id = aws_vpc.this.id
```

creates a dependency on the VPC.

Similarly:

```hcl
allocation_id = aws_eip.nat[each.key].id
```

creates a dependency between the NAT Gateway and its Elastic IP.

And:

```hcl
nat_gateway_id = aws_nat_gateway.this[each.key].id
```

creates a dependency between the private route table and the NAT Gateway.

Explicit `depends_on` declarations are therefore unnecessary for the current implementation.

---

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `name` | `string` | — | Yes | Network name used as a resource naming prefix |
| `cidr` | `string` | — | Yes | CIDR block assigned to the VPC |
| `availability_zones` | `list(string)` | — | Yes | Availability Zones used to distribute network resources |
| `enable_dns_support` | `bool` | `true` | No | Enables DNS resolution inside the VPC |
| `enable_dns_hostnames` | `bool` | `true` | No | Enables DNS hostnames inside the VPC |
| `tags` | `map(string)` | `{}` | No | Additional tags applied to network resources |

### CIDR Validation

The VPC CIDR is validated with:

```hcl
validation {
  condition     = can(cidrhost(var.cidr, 0))
  error_message = "Invalid CIDR."
}
```

### Availability Zone Validation

At least two Availability Zones must be provided:

```hcl
validation {
  condition     = length(var.availability_zones) >= 2
  error_message = "At least two Availability Zones are required."
}
```

---

## Example Usage

Example from `environments/dev/main.tf`:

```hcl
module "network" {
  source = "../../modules/network"

  name               = var.network_name
  cidr               = var.network_cidr
  availability_zones = var.availability_zones

  tags = local.common_tags
}
```

Example environment configuration:

```hcl
network_name = "platform-dev"
network_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]
```

---

## Outputs

The module exposes the following outputs:

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_arn` | VPC ARN |
| `vpc_cidr_block` | VPC CIDR block |
| `internet_gateway_id` | Internet Gateway ID |
| `public_subnet_ids` | Map of public subnet IDs indexed by Availability Zone |
| `private_subnet_ids` | Map of private subnet IDs indexed by Availability Zone |
| `nat_gateway_ids` | Map of NAT Gateway IDs indexed by Availability Zone |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Map of private route table IDs indexed by Availability Zone |

Example:

```text
private_subnet_ids = {
  "us-east-1a" = "subnet-xxxxxxxx"
  "us-east-1b" = "subnet-yyyyyyyy"
}
```

Returning subnet IDs as a map preserves the relationship between the subnet and its Availability Zone.

Downstream modules can convert the map to a list when required:

```hcl
values(module.network.private_subnet_ids)
```

This will be useful for services such as Amazon EKS.

---

## Tagging Strategy

Environment-level tags are passed to the module:

```hcl
tags = local.common_tags
```

The module adds its own tags:

```hcl
locals {
  common_tags = merge(
    {
      Module    = "network"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}
```

A typical resource can therefore contain:

```text
Project     = cloud-platform-portfolio
Environment = dev
Owner       = <owner>
ManagedBy   = Terraform
Module      = network
Type        = private
```

This provides consistent identification for operations, governance, filtering, and cost analysis.

---

## Naming Convention

Resources use predictable names.

Examples:

```text
platform-dev-vpc

platform-dev-igw

platform-dev-public-us-east-1a
platform-dev-public-us-east-1b

platform-dev-private-us-east-1a
platform-dev-private-us-east-1b

platform-dev-public-rtb

platform-dev-private-rtb-us-east-1a
platform-dev-private-rtb-us-east-1b

platform-dev-nat-eip-us-east-1a
platform-dev-nat-eip-us-east-1b

platform-dev-nat-gateway-us-east-1a
platform-dev-nat-gateway-us-east-1b
```

The naming convention makes resources easier to identify through the AWS Console, AWS CLI, logs, and billing tools.

---

## Validation Workflow

After changing the module, run:

```bash
terraform fmt -recursive
terraform validate
```

When valid AWS credentials are available:

```bash
terraform plan
```

Recommended workflow:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

`terraform validate` checks the Terraform configuration without requiring active AWS credentials after initialization.

`terraform plan` requires valid AWS credentials because the AWS provider must communicate with AWS APIs.

---

## Repository Security

This project is stored in a public repository.

Sensitive Terraform files must never be committed.

The repository `.gitignore` excludes:

```text
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.auto.tfvars
*.tfplan
```

A sanitized example variable file can be committed instead:

```text
terraform.tfvars.example
```

Never commit:

- AWS Access Keys
- AWS Secret Access Keys
- Passwords
- API tokens
- Private keys
- Terraform state files
- Sensitive variable files

The Terraform provider lock file:

```text
.terraform.lock.hcl
```

should normally be version controlled to provide deterministic provider dependency selection.

---

## Cost Considerations

The architecture prioritizes availability over minimum cost.

The primary cost consideration is the NAT Gateway architecture:

```text
1 Availability Zone = 1 NAT Gateway
```

Therefore, two Availability Zones result in two NAT Gateways.

This provides better fault isolation but costs more than a single shared NAT Gateway.

The appropriate strategy should always be selected based on:

- Business criticality
- Availability requirements
- Failure tolerance
- Traffic patterns
- Cross-AZ traffic
- Budget

---

## Current Limitations

The current version intentionally focuses on the core IPv4 VPC architecture.

It does not currently implement:

- IPv6
- VPC Flow Logs
- VPC Endpoints
- Network ACL customization
- Configurable single-NAT mode
- Transit Gateway connectivity
- VPN connectivity
- Direct Connect
- IPAM integration

These capabilities can be introduced incrementally as the platform evolves.

---

## Future Improvements

Potential improvements include:

- VPC Flow Logs
- Gateway and Interface VPC Endpoints
- IPv6 support
- Configurable NAT Gateway strategy
- AWS VPC IPAM integration
- Automated Terraform documentation
- TFLint
- Security scanning
- Pre-commit hooks
- CI/CD validation

Quality and security automation will be addressed in a dedicated project sprint.

---

## Module Integration

This module acts as the network foundation for other platform components.

The expected dependency flow is:

```text
Network
   |
   v
EKS
   |
   v
GitOps
   |
   v
Observability
```

For example, the future EKS module can consume:

```hcl
module.network.vpc_id
```

and:

```hcl
values(module.network.private_subnet_ids)
```

The EKS module therefore does not need to know how the underlying VPC, NAT Gateways, routing, or subnet allocation were implemented.

This provides clear separation of responsibilities between Terraform modules.

---

## Project Philosophy

This module was intentionally implemented from individual AWS resources rather than relying entirely on a pre-built community VPC module.

The objective is both to provision infrastructure and demonstrate understanding of:

- AWS networking fundamentals
- Terraform module design
- Dynamic resource creation
- Terraform dependency management
- Multi-AZ architectures
- Network isolation
- NAT and routing
- High availability
- Infrastructure as Code
- Architecture trade-offs

The implementation prioritizes clarity, maintainability, and architectural understanding.

---

## Status

**Network Module v1: Complete**

Implemented capabilities:

- Multi-AZ VPC
- Public and private subnet layers
- Internet Gateway
- Public routing
- NAT Gateway per Availability Zone
- Elastic IP per NAT Gateway
- Private routing per Availability Zone
- Dynamic CIDR allocation
- Input validation
- Consistent tagging
- Consistent naming
- Reusable outputs
- Module documentation