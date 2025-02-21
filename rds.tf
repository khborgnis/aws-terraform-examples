resource "aws_db_subnet_group" "database" {
    name = "database"

    subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "database" {
    name = "database"
    vpc_id = aws_vpc.demo.id
}



resource "aws_db_instance" "db" {
    allocated_storage = 10

    auto_minor_version_upgrade = true
    backup_retention_period  = 1

    copy_tags_to_snapshot = true
    db_name = "demo"
    db_subnet_group_name = aws_db_subnet_group.database.name

    instance_class = "db.t3.micro"
    engine = "mysql"
    engine_version = "8.0"
    username = "admin"
    manage_master_user_password = true
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot = true
}