# Terraform configuration

This repository is used to manage my personal cloud infrastructure.

## Setup

### Terraform (required)

* Download binary and put it on your path.[<sup>*</sup>](https://www.terraform.io/downloads.html)

### Google Provider credentials (required)

* Configured using service account.[<sup>*</sup>](https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials)

### AWS Provider credentials (required)

* Pass aws credentials:[<sup>*</sup>](https://www.terraform.io/docs/providers/aws/index.html#environment-variables)

```
#####################
###   Use this    ###
#####################
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
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

## Running

### Create

1. This creates the Route53 zone, which requires updating the domain's DNS servers at its registrar. The ACM certificate can not be validated until this is done.
1. Due to an outstanding issue in `terraform-provider-aws`[<sup>*</sup>](https://github.com/terraform-providers/terraform-provider-aws/issues/8081) the Lambda@Edge functions must be created before the CloudFront distribution. This happens with an implicit or explicit dependency.

To work around these issues, create using these steps:

```
### First - Initialize Terraform
terraform init

### Second - Create Route53 Zone
terraform apply -target aws_route53_zone.jeremychase_io # BUG(high) rename terraform resource

### Third - Update DNS servers at registrar
echo "Manually update domain's DNS servers at its registrar to match new zone"
sleep 10

### Fourth - Create Lambda@Edge
terraform apply -target aws_lambda_function.subdomain_redirect

### Fifth - Create everything else
terraform apply
```

### Destroy

1. When you delete a CloudFront distribution the association to its Lambda@Edge Replicated Functions are not immediately deleted. This is [documented](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-delete-replicas.html) by AWS and the only way to resolve this is to wait a few minutes and run `terrafrom destroy` again.
This is the output when this issue happens:

```
Error: Error deleting Lambda Function: InvalidParameterValueException: Lambda was unable to delete arn:aws:lambda:x:x:function:x:x because it is a replicated function. Please see our documentation for Deleting Lambda@Edge Functions and Replicas.
```

2. If you toggle `force_destroy_s3_buckets` from `false` to `true`, you must run a `terraform apply` [<sup>*</sup>](https://github.com/terraform-providers/terraform-provider-aws/issues/428#issuecomment-445346454) before terraform is able to delete the buckets. This is the output when this issue happens:

```
Error: error deleting S3 Bucket (bucket-name): BucketNotEmpty: The bucket you tried to delete is not empty
```

## Directory and file structure

<!-- BUG(high) fix -->
It is a mess. Don't think about it.

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