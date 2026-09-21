

# resource "aws_sqs_queue" "orders" {
#   name = "orders_queue"
#   delay_seconds = 90
#   max_message_size = 2048
#   message_retention_seconds = 86400
#   receive_wait_time_seconds = 10
#   visibility_timeout_seconds = 300
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = "${aws_sqs_queue.orders_deadletter.arn}"
#     maxReceiveCount = 5
#   })
# }

# resource "aws_sqs_queue" "orders_deadletter" {
#   name = "orders-dead-letter-queue"
# }

# resource "aws_sqs_queue" "inventory" {
#   name = "inventory_queue"
#   delay_seconds = 90
#   max_message_size = 2048
#   message_retention_seconds = 86400
#   receive_wait_time_seconds = 10
#   visibility_timeout_seconds = 300
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = "${aws_sqs_queue.inventory_deadletter.arn}"
#     maxReceiveCount = 5
#   })
# }

# resource "aws_sqs_queue" "inventory_deadletter" {
#   name = "inventory-dead-letter-queue"
# }
