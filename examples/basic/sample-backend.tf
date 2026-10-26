# terraform {
#   backend "s3" {
#     bucket         = "my-account-tfstate"
#     key            = "example-tf-ec2-basic/example-tf-ec2-basic.tfstate"
#     dynamodb_table = "example-tf-ec2-basic-lock"
#     region         = "us-east-1"
#     profile        = "my-profile"
#     encrypt        = true
#   }
# }
