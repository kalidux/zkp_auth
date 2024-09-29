output "server_instance_public_ip" {
  description = "The public IP address of the Rust server instance"
  value       = aws_instance.rust_server.public_ip
}

output "client_instance_public_ip" {
  description = "The public IP address of the Rust client instance"
  value       = aws_instance.rust_client.public_ip
}
