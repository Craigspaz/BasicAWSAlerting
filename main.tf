provider "aws" {
    region = var.region
    assume_role {
      role_arn = var.deployment_role
      session_name = "AFT"
      external_id = length(var.external_id) == 0 ? null : var.external_id
    }
}

locals {
    
}

data "aws_caller_identity" "current" {
    count = var.deploy_resources == true ? 1 : 0
}

data "aws_partition" "current" {
    count = var.deploy_resources == true ? 1 : 0
}

data "aws_region" "current" {
    count = var.deploy_resources == true ? 1 : 0
}

resource "aws_sns_topic" "critical_alert" {
  count = var.deploy_resources == true ? 1 : 0
  name = "critical_alerts"
}

resource "aws_sns_topic_subscription" "owner" {
  count = var.deploy_resources == true ? 1 : 0
  topic_arn = aws_sns_topic.critical_alert[count.index].arn
  protocol = "email"
  endpoint = var.owner_email
}

resource "aws_sns_topic_policy" "events" {
  count = var.deploy_resources == true ? 1 : 0
  arn = aws_sns_topic.critical_alert[count.index].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[count.index].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.deploy_resources == true ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.critical_alert[count.index].arn]
  }
}

resource "aws_cloudwatch_event_rule" "logins" {
  count = var.deploy_resources == true ? 1 : 0
  name = "console-sign-ins"
  description = "Alert on signins"
  event_pattern = jsonencode({
    detail-type = [
      "AWS Console Sign In via CloudTrail"
    ]
  })
}

resource "aws_cloudwatch_event_target" "login_event_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.logins[count.index].name
  target_id = "console-sign-ins"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}

resource "aws_cloudwatch_event_rule" "ec2_instances" {
  count = var.deploy_resources == true ? 1 : 0
  name = "ec2-instance-events"
  description = "Alert on ec2 events"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["pending", "running", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_instances_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.ec2_instances[count.index].name
  target_id = "ec2-instance-changes"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}

resource "aws_cloudwatch_event_rule" "s3_changes" {
  count = var.deploy_resources == true ? 1 : 0
  name = "s3-changes"
  description = "Alert on s3 events"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["s3.amazonaws.com"],
      "eventName": ["DeleteBucket", "DeleteBucketCors", "DeleteBucketLifecycle", "DeleteBucketPolicy", "DeleteBucketReplication", "DeleteBucketTagging", "DeleteBucketWebsite", "CreateBucket", "PutBucketAcl", "PutBucketCors", "PutBucketLifecycle", "PutBucketPolicy", "PutBucketLogging", "PutBucketNotification", "PutBucketReplication", "PutBucketTagging", "PutBucketRequestPayment", "PutBucketVersioning", "PutBucketWebsite", "PutBucketEncryption", "DeleteBucketEncryption", "DeleteBucketPublicAccessBlock", "PutBucketPublicAccessBlock"]
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_changes_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.s3_changes[count.index].name
  target_id = "s3-changes"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}


resource "aws_cloudwatch_event_rule" "route53_changes" {
  count = var.deploy_resources == true ? 1 : 0
  name = "route53-changes"
  description = "Alert on route53 events"
  event_pattern = jsonencode({
    "source": ["aws.route53"]
  })
}

resource "aws_cloudwatch_event_target" "route53_changes_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.route53_changes[count.index].name
  target_id = "route53-changes"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}

resource "aws_cloudwatch_event_rule" "root_changes" {
  count = var.deploy_resources == true ? 1 : 0
  name = "root-signins"
  description = "Alert on Root Signin events"
  event_pattern = jsonencode({
  "source": ["aws.signin"],
  "detail": {
    "userIdentity": {
      "arn": ["arn:${data.aws_partition.current[count.index].name}:iam::${data.aws_caller_identity.current[count.index].account_id}:root"]
    }
  }
})
}

resource "aws_cloudwatch_event_target" "root_changes_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.root_changes[count.index].name
  target_id = "root-signins"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}

resource "aws_cloudwatch_event_rule" "lambda_changes" {
  count = var.deploy_resources == true ? 1 : 0
  name = "lambda-changes"
  description = "Alert on lambda events"
  event_pattern = jsonencode({
    "source": ["aws.lambda"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_changes_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.lambda_changes[count.index].name
  target_id = "lambda-changes"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}


resource "aws_cloudwatch_event_rule" "iam_changes" {
  count = var.deploy_resources == true ? 1 : 0
  name = "iam-changes"
  description = "Alert on IAM events"
  event_pattern = jsonencode({
  "source": ["aws.iam"]
})
}

resource "aws_cloudwatch_event_target" "iam_changes_target" {
  count = var.deploy_resources == true ? 1 : 0
  rule = aws_cloudwatch_event_rule.iam_changes[count.index].name
  target_id = "iam-changes"
  arn = aws_sns_topic_subscription.owner[count.index].arn
}


