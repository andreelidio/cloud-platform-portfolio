# Terraform AWS VPC Module

## Overview

This module provisions an Amazon VPC that serves as the networking foundation for the Cloud Platform Portfolio.

## Features

- Creates a reusable VPC
- DNS Hostnames enabled
- DNS Support enabled
- Custom tagging
- Reusable outputs

## Inputs

| Name | Type | Required |
|------|------|----------|
| name | string | Yes |
| cidr_block | string | Yes |

## Outputs

- id
- arn
- cidr_block
- default_route_table_id