# なんか動かんし今度見る

# ECSタスク実行ロール
# resource "aws_iam_role" "host-frp_ecs_task_execution_role" {
#   name = "host-frp_ecs_task_execution_role"
#   assume_role_policy = data.aws_iam_policy_document.host-frp_ecs_task_assume_role_policy.json
# }

# data "aws_iam_policy_document" "host-frp_ecs_task_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role_policy_attachment" "host-frp_ecs_task_execution_role_policy" {
#   role       = aws_iam_role.host-frp_ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }
