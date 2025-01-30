# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/directory_service_directory
resource "aws_directory_service_directory" "example" {
  name     = "corp.borgnis.org"
  password = var.ad_password
  size     = "Small"

  vpc_settings {
    vpc_id     = aws_vpc.main.id
    subnet_ids = [aws_subnet.first.id, aws_subnet.second.id]
  }

  tags = {
    Project = "example"
  }
}
