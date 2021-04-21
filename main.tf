provider "aws" {
  region = "ca-central-1"
}

####################################################################################
#
# create a sns topic
#
####################################################################################

resource "aws_sns_topic" "this" {

  # Details
  fifo_topic                  = var.sns_topic_type == "fifo" ? true : false
  name                        = var.sns_topic_type == "fifo" ? "${var.sns_topic_name}.fifo" : var.sns_topic_name
  display_name = var.sns_topic_name
  content_based_deduplication = false

  # Encryption
  kms_master_key_id = "alias/aws/sns"

  # Access policy 
  # define policy by using aws_sns_topic_policy

  # Delivery status logging, if queue type is fifo, just amazon sqs is supported
  # <endpoint>_success_feedback_role_arn, <endpoint>_failure_feedback_role_arn, <endpoint>_success_feedback_sample_rate
 
  #sqs_success_feedback_role_arn = 
  #sqs_failure_feedback_role_arn = 
  #sqs_success_feedback_sample_rate = 

  tags = {
    type = var.sns_topic_type == "fifo" ? "fifo" : "standard"
  }

  # Delivery retry policy (HTTP/S)
/*
  delivery_policy = <<-EOF
  {
    "http": {
      "defaultHealthyRetryPolicy": {
        "minDelayTarget": 20,
        "maxDelayTarget": 20,
        "numRetries": 3,
        "numMaxDelayRetries": 0,
        "numNoDelayRetries": 0,
        "numMinDelayRetries": 0,
        "backoffFunction": "linear"
      },
      "disableSubscriptionOverrides": false,
      "defaultThrottlePolicy": {
        "maxReceivesPerSecond": 1
      }
    }
  }
EOF
*/

}

####################################################################################
#
# create a topic access policy
#
####################################################################################

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:Receive",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.this.arn,
    ]

    sid = "__default_statement_ID"
  }
}

####################################################################################
#
# create a topic subcription by email
# when topic is fifo, just sqs subscription is supported
#
####################################################################################

resource "aws_sns_topic_subscription" "sns_subs_email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.sns_sub_email_endpoint
}

####################################################################################
#
# create a topic subcription by sqs
# when topic is fifo, just sqs subscription is supported
#
####################################################################################

resource "aws_sqs_queue" "sns_subs_sqs" {

  # Details
  fifo_queue = false
  name = var.sns_sub_sqs.name

  # Configuration
  visibility_timeout_seconds = 3600
  message_retention_seconds = 345600
  delay_seconds = 0
  max_message_size = 262144
  receive_wait_time_seconds = 0

  # Access policy via policy = or resource aws_sqs_queue_policy

  # Encryption
  #kms_master_key_id = "alias/aws/sqs"
  #kms_data_key_reuse_period_seconds = 300

  # Dead-letter queue
/*  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = 4
  })
*/

  tags = {
      type = "receive messages from sns"
    }

}

####################################################################################
#
# create a sqs access policy
#
####################################################################################

resource "aws_sqs_queue_policy" "sns_subs_sqs" {
  queue_url = aws_sqs_queue.sns_subs_sqs.id

  policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "__owner_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_caller_identity.current.account_id}"
      },
      "Action": [
        "SQS:*"
      ],
      "Resource": "${aws_sqs_queue.sns_subs_sqs.arn}"
    },
    {
      "Sid": "SNS_statement",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.sns_subs_sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.this.arn}"
        }
      }
    }
  ]
}
POLICY
}


resource "aws_sns_topic_subscription" "sns_subs_sqs" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sns_subs_sqs.arn
}