data "aws_route53_zone" "xen" {
  name = local.domain_name
  #private_zone = true
}

data "aws_acm_certificate" "xen" {
    domain = local.domain_name
}

resource "aws_route53_record" "self_managed" {
  zone_id = data.aws_route53_zone.xen.zone_id # Replace with your zone ID
  name    = "selfk8s.${local.domain_name}"  # Replace with your name/domain/subdomain
  type    = "A"

  alias {
    name                   = aws_lb.nlb_main.dns_name #substr(data.kubernetes_service.istio_ingress.status[0].load_balancer[0].ingress[0].hostname,0,substr(data.kubernetes_service.istio_ingress.status[0].load_balancer[0].ingress[0].hostname,31,1)=="-"?31:32) #"k8s-ingress-external-7a4ba4b859-2e928abf1840765c.elb.ap-southeast-2.amazonaws.com"
    zone_id                = aws_lb.nlb_main.zone_id
    evaluate_target_health = false
  }
  
}

# resource "aws_acm_certificate" "xen" {
#   domain_name       = local.domain_name
#   validation_method = "DNS"

#   subject_alternative_names = [
#     "*.${local.domain_name}"
#   ]

#   lifecycle {
#     create_before_destroy = true
#   }
# }


# resource "aws_route53_record" "valid" {
#   for_each = {
#     for dvo in aws_acm_certificate.xen.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#    # Skips the domain if it doesn't contain a wildcard
#     if length(regexall("\\*\\..+", dvo.domain_name)) > 0
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 30
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.xen.zone_id
# }
