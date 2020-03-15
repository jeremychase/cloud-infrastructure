# Terraform configuration

This repository is used to manage my personal cloud infrastructure.

## Setup

### Terraform (required)

* Download binary and put it on your path. [1](https://www.terraform.io/downloads.html)

### Google Provider credentials (required)

* Configured using service account. [2](https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials)

### Vultr Provider credentials

```
export VULTR_API_KEY="vultrkey"
```

### AWS Provider credentials 

* Pass aws credentials: [3](https://www.terraform.io/docs/providers/aws/index.html#environment-variables)

```
#####################
###   Use this    ###
#####################
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_DEFAULT_REGION="us-west-2"
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

## Running

Then:

```
$ terraform init
```
