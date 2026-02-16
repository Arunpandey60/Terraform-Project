output "sg_alb" {
  value = aws_security_group.alb.id
}

output "sg_ec2" {
  value = aws_security_group.ec2.id
}
