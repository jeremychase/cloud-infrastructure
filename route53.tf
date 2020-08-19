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

resource "aws_route53_zone" "jeremychase_io" {
  name = "jeremychase.io"
}

# DNS Validation with Route 53
#
# Based on example from:
#
#  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
#
# 
resource "aws_route53_record" "jeremychase_io" { # TODO(jchase) rename 'validation'
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
  ttl             = 60 # TODO increase
  type            = each.value.type
  zone_id         = aws_route53_zone.jeremychase_io.zone_id
}

resource "aws_acm_certificate_validation" "jeremychase_io" {
  certificate_arn         = aws_acm_certificate.jeremychase_io.arn
  validation_record_fqdns = [for record in aws_route53_record.jeremychase_io : record.fqdn]
}


resource "aws_route53_record" "www_A" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = "www.${aws_route53_zone.jeremychase_io.name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_A" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = aws_route53_zone.jeremychase_io.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_AAAA" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = "www.${aws_route53_zone.jeremychase_io.name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_AAAA" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = aws_route53_zone.jeremychase_io.name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
