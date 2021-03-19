# Terraform configuration

This repository is used to manage my personal cloud infrastructure:

```
live/
├── mgmt
│   ├── dns-zones
│   │   └── jeremychase-io
│   ├── governance
│   │   └── aws-cloudtrail
│   └── services
│       ├── aws-bastion
│       └── azure-calico
│       └── gcp-free-tier-bastion
└── prod
    └── services
        └── www-jeremychase-io
```

## Setup

### Terraform (required)

* Download binary and put it on your path.[<sup>*</sup>](https://www.terraform.io/downloads.html)

### AWS Provider credentials (required)

* Pass aws credentials:[<sup>*</sup>](https://www.terraform.io/docs/providers/aws/index.html#environment-variables)

```
#####################
###   Use this    ###
#####################
export AWS_ACCESS_KEY_ID="an_access_key"
export AWS_SECRET_ACCESS_KEY="a_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

```
#####################
### DOES NOT WORK ###
#####################
$ terraform version
Terraform v0.12.20
+ provider.aws v2.48.0
$ export AWS_PROFILE=<profilename>
```

## Directory and file structure

Uses [this](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d) format, but with modules in the same repository.

## Running

The resources are configured under the `live` directory. To use them `cd` to the correct directory then use `terraform` as normal. See readme documents in workspace directories for more detail.
