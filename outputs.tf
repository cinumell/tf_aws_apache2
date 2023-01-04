output "server_public_ip" {
    description = "The public IP address of the instance."
    value = aws_instance.server.public_ip
}

output "server_private_ip" {
    description = "The private IP address of the instance."
    value = aws_instance.server.private_ip
}