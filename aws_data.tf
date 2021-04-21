###########################################################################
#
# Use this data source to get datas from aws for other resources.
#
###########################################################################

data "aws_ami" "amz2" {
  most_recent = true
  owners      = ["amazon"] # Canonical

  # more filter conditions are describled in the followed web link
  # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

# get default vpc data
data "aws_vpc" "default_vpc" {
  default = true
}

# get subnetid from default vpc
data "aws_subnet_ids" "default_subnets" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# search a security group in the default vpc and it will be used in ec2 instance's security_groups
data "aws_security_groups" "default_sg" {
  filter {
    name   = "group-name"
    values = ["*SG-STRICT-ACCESS*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "aws_caller_identity" "current" {} #data.aws_caller_identity.current.account_id