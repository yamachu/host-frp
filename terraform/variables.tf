variable "ecr_image_url" {
  description = "ECRのイメージURL:タグ"
}

# Cloudflareで管理しているものを使うため
# AWSマネジメントコンソールでACM証明書を作成し、CloudflareでDNS検証を実施
# ALB使わないなら不要だな
# variable "aws_acm_cert_arn" {
#   description = "ACM証明書ARN"  
# }

variable "host-frp_ecs_task_execution_role_arn" {
  description = "ECSタスク実行ロールのARN"
}
