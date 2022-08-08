resource "aws_spot_instance_request" "instance" {
  count         = var.INSTANCE_COUNT
  ami           = data.aws_ami.main.id
  spot_price    = data.aws_ec2_spot_price.spot_price.spot_price
  instance_type = var.INSTANCE_TYPE
  wait_for_fulfillment    = true
  vpc_security_group_ids  = [aws_security_group.main.id]
  subnet_id               = var.PRIVATE_SUBNET_ID[0]
  iam_instance_profile    = aws_iam_instance_profile.allow-secretmanager-readaccess.name

  tags   = {
    Name = local.TAG_PREFIX
  }
}

resource "aws_ec2_tag" "example" {
  count = var.INSTANCE_COUNT
  resource_id = aws_spot_instance_request.instance.*.spot_instance_id[count.index]
  key         = "Name"
  value       = local.TAG_PREFIX
}

resource "null_resource" "ansible" {
  triggers = {
    abc = timestamp()
  }
  count = var.INSTANCE_COUNT
  provisioner "remote-exec" {
    connection {
      user     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host     = aws_spot_instance_request.instance.*.private_ip[count.index]
    }
    inline = [
      "ansible-pull -U https://github.com/devopsravi9/roboshop-ansible.git roboshop.yml -e HOST=localhost -e ROLE=${var.COMPONENT} -e ENV=${var.ENV} -e DOCDB_ENDPOINT=${var.DOCDB_ENDPOINT} -e REDDIS_ENDPOINT=${var.REDDIS_ENDPOINT} -e MYSQL_ENDPOINT=${var.MYSQL_ENDPOINT}"
    ]

  }
}