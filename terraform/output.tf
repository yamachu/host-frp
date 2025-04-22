# CloudflareでCNAMEこれに向ける
output "nlb_dns_name" {
  value = aws_lb.main.dns_name
}
