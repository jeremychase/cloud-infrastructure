# AWS CloudTrail and S3 Bucket

This creates a global, multi-region CloudTrail using Object-Lock.

# !!! Warning !!!

This creates objects in S3 using [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock-overview.html). To make this less painful in the event of accidentally creating using wrong bucket name, the default lock and expiration are 1 and 2 days, respectively.

In practice, you will want to set `object_lock_retention_days` to a larger number.

## Example

```
module "aws-cloudtrail" {
  source = "../../../../modules/governance/aws-cloudtrail"

  cloudtrail_name            = "global"
  s3_bucket_name             = "cloudtrail.aws.jeremychase.io"
  object_lock_retention_days = 365
}
```