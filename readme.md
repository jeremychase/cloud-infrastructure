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
│       ├── azure-bastion
│       ├── azure-calico
│       ├── gcp-free-tier-bastion
│       └── gcp-gke
└── prod
    └── services
        └── www-jeremychase-io
```

## Setup

Using the VSCode dev container is the reliable way to setup your system to use this repo.

After the above, `terraform` should work as expected from the container terminal.

### AWS Provider credentials (required)

The `~/.aws/credentials` file needs to have the `jeremychase` profile.

## Directory and file structure

Uses [this](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d) format, but with modules in the same repository.

## Running

The resources are configured under the `live` directory. To use them `cd` to the correct directory then use `terraform` as normal. See readme documents in workspace directories for more detail.
