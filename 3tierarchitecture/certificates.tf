resource "aws_acm_certificate" "test_cloudlearner_crt" {
  domain_name       = "cloudlearner.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-cert"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-cert"
    "ANC" = "Test"
  })
}

data "aws_route53_zone" "cloudlearner" {
  name = "cloudlearner.click"
}


resource "aws_route53_record" "web_cert_validation" {
  name = "${tolist(aws_acm_certificate.test_cloudlearner_crt.domain_validation_options).0.resource_record_name}"
  type = "${tolist(aws_acm_certificate.test_cloudlearner_crt.domain_validation_options).0.resource_record_type}"
  records = ["${tolist(aws_acm_certificate.test_cloudlearner_crt.domain_validation_options).0.resource_record_value}"]
  zone_id = data.aws_route53_zone.cloudlearner.id
  ttl     = 60
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "test_cloudlearn_validate" {
  certificate_arn         = aws_acm_certificate.test_cloudlearner_crt.arn
  validation_record_fqdns = [aws_route53_record.web_cert_validation.fqdn]

  lifecycle {
    create_before_destroy = true
  }  
}

