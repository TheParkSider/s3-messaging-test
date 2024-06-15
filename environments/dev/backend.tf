terraform {
  backend "s3" {
    bucket = "terraform-backend-s3bucket-v5t6pzt3vbpk"
    key    = "s3-messaging-test/dev/terraform.tfstate"
    region = "ap-northeast-1"
    dynamodb_table = "terraform-backend-DynamodbTable-GCNZ4R4J24WM"
  }
}