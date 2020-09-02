# CloudFront for www.jeremychase.io

This creates CloudFront, CodePipeline, CodeBuild, Route53, ACM and S3 resources for hosting www.jeremychase.io.

## Setup

### AWS Provider credentials (required)

See AWS Setup instructions from the main [readme](../../../../readme.md).

## Running

### Create

1. Due to an outstanding issue in `terraform-provider-aws`[<sup>*</sup>](https://github.com/terraform-providers/terraform-provider-aws/issues/8081) the Lambda@Edge functions must be created before the CloudFront distribution. This happens with an implicit or explicit dependency.

To work around this issue, create using these steps:

```
### First - Initialize Terraform
terraform init

### Second - Create Lambda@Edge
terraform apply -target aws_lambda_function.subdomain_redirect

### Third - Create everything else
terraform apply
```

### Destroy

1. When you delete a CloudFront distribution the association to its Lambda@Edge Replicated Functions are not immediately deleted. This is [documented](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-delete-replicas.html) by AWS and the only way to resolve this is to wait a few minutes and run `terraform destroy` again.
This is the output when this issue happens:

```
Error: Error deleting Lambda Function: InvalidParameterValueException: Lambda was unable to delete arn:aws:lambda:x:x:function:x:x because it is a replicated function. Please see our documentation for Deleting Lambda@Edge Functions and Replicas.
```

2. If you toggle `force_destroy_s3_buckets` from `false` to `true`, you must run a `terraform apply` [<sup>*</sup>](https://github.com/terraform-providers/terraform-provider-aws/issues/428#issuecomment-445346454) before terraform is able to delete the buckets. This is the output when this issue happens:

```
Error: error deleting S3 Bucket (bucket-name): BucketNotEmpty: The bucket you tried to delete is not empty
```

## File structure

Related resources are grouped in files.

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
https://aws.amazon.com/premiumsupport/knowledge-center/codepipeline-artifacts-s3/