variable "sns_topic_type" {
  type = string
  default = "standard"

  validation { 
    condition = var.sns_topic_type == "fifo" || var.sns_topic_type == "standard"
    error_message = "Var.sns_topic_type must be fifo or standard."
  }
}

variable "sns_topic_name" {
  type = string
  default = "tf-sns-topic"
}

variable "sns_sub_email_endpoint" {
  type = string
}

variable "sns_sub_sqs" {
  type = object({
    name = string
  })
  default = {
    name = "tf-sns-subs-sqs"
  }
}