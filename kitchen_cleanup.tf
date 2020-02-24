resource "aws_iam_role" "kitchen_cleanup_role" {
  path                 = "/"
  name                 = "KitchenCleanupRole"
  assume_role_policy   = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  max_session_duration = 3600
}

resource "aws_iam_policy" "kitchen_cleanup_policy" {
  name        = "kitchen_cleanup_policy"
  path        = "/"
  description = "Kitchen Cleanup Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeKeyPairs",
                "ec2:DeleteKeyPair",
                "ec2:DescribeInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_policy_attachment" "kitchen_cleanup_policy_attachment" {
  name       = "kitchen_cleanup_policy_attachment"
  roles      = [aws_iam_role.kitchen_cleanup_role.name]
  policy_arn = aws_iam_policy.kitchen_cleanup_policy.arn
}

resource "aws_lambda_function" "kitchen_cleanup_lambda" {
  description   = ""
  function_name = "KitchenCleanUp"
  handler       = "KitchenCleanUp.lambda_handler"
  filename      = data.archive_file.kitchen_cleanup_lambda_file.output_path
  memory_size   = 128
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KitchenCleanupRole"
  runtime       = "python3.6"
  timeout       = 30
  tracing_config {
    mode = "PassThrough"
  }
}

data "archive_file" "kitchen_cleanup_lambda_file" {
  type        = "zip"
  source_file = "${path.module}/KitchenCleanUp.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_cloudwatch_event_rule" "kitchen_cleanup_cloudwatch_event_rule" {
  name                = "KitchenCleanUpRule"
  schedule_expression = "cron(0 0 ? * SAT *)"
}

resource "aws_cloudwatch_event_target" "kitchen_cleanup_cloudwatch_event_target" {
  rule = aws_cloudwatch_event_rule.kitchen_cleanup_cloudwatch_event_rule.name
  arn  = aws_lambda_function.kitchen_cleanup_lambda.arn
}

resource "aws_lambda_permission" "kitchen_cleanup_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-west-2:${data.aws_caller_identity.current.account_id}:function:KitchenCleanUp"
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:us-west-2:${data.aws_caller_identity.current.account_id}:rule/KitchenCleanUpRule"
}

