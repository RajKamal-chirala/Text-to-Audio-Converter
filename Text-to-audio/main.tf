terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"

    }
  }
}

provider "aws" {
  shared_credentials_files = ["/home/raj/.aws/credentials"]
  region     = "us-west-2"
  default_tags {
    tags = {
      Project = "myfirstProject"
    }
  }
}

resource "aws_dynamodb_table" "posts_dynamodb_table" {
  name           = "posts"
  read_capacity  = 25
  write_capacity = 25
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "random_id" "id" {
  byte_length = 16
}

resource "aws_s3_bucket" "audioposts_bucket" {
  bucket = "audioposts-${random_id.id.hex}"
}



