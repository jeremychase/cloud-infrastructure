# GCP Free Tier Bastion

This creates a bastion instance that meets GCP's 'always-free' tier. This also creates AWS Route53 DNS entries.

## Setup

### Google Provider credentials (required)

* Configured using a [service account](https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials). The path to the credential is in the `google_provider_credentials_path` variable.

### AWS Provider credentials (required)

See AWS Setup instructions from the main [readme](../../../../readme.md).
