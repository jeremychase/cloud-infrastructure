resource "aws_acm_certificate" "jeremychase_io" {
  domain_name               = "jeremychase.io"
  subject_alternative_names = ["www.jeremychase.io"]
  validation_method         = "DNS"

  tags = {
    Project = "www.jeremychase.io"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation with Route 53
#
# Based on example from:
#
#  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
#
# 
resource "aws_route53_record" "jeremychase_io" { # BUG(medium) rename 'validation'
  for_each = {
    for dvo in aws_acm_certificate.jeremychase_io.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300 # BUG(low) increase
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

resource "aws_acm_certificate_validation" "jeremychase_io" {
  certificate_arn         = aws_acm_certificate.jeremychase_io.arn
  validation_record_fqdns = [for record in aws_route53_record.jeremychase_io : record.fqdn]
}


resource "aws_route53_record" "www_A" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3.domain_name
    zone_id                = aws_cloudfront_distribution.s3.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_A" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3.domain_name
    zone_id                = aws_cloudfront_distribution.s3.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_AAAA" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3.domain_name
    zone_id                = aws_cloudfront_distribution.s3.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_AAAA" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3.domain_name
    zone_id                = aws_cloudfront_distribution.s3.hosted_zone_id
    evaluate_target_health = false
  }
}
