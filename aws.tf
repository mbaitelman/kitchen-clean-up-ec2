provider "aws" {
}

data "aws_caller_identity" "current" {
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}
