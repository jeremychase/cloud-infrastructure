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
$ zip subdomain_redirect subdomain_redirect.py && time terraform apply -auto-approve
```

## References

https://aws.amazon.com/blogs/networking-and-content-delivery/lambdaedge-design-best-practices/
https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html
https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html
https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-s3deploy.html
https://medium.com/@jeffreyrussom/react-continuous-deployments-with-aws-codepipeline-f5034129ff0e
https://medium.com/swlh/create-deploy-a-serverless-react-app-to-s3-cloudfront-on-aws-4f83fa605ff0
https://github.com/aws-samples/aws-codebuild-samples/blob/master/cloudformation/continuous-deployment.yml
https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec.artifacts
https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-GitHub.html
https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-examples.html#lambda-examples-http-redirect

## Directory structure

BUG(high) it is a mess. Don't think about it.