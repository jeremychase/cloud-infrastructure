output "zone_name" {
  value = aws_route53_zone.self.name
}

output "zone_id" {
  value = aws_route53_zone.self.zone_id
}

output "zone_name_servers" {
  value = aws_route53_zone.self.name_servers
}
