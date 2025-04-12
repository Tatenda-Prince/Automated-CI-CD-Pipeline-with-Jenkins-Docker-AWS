output "public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_instance.public_ip
}

output "jenkins_url" {
  description = "Access Jenkins in your browser using this URL"
  value       = "http://${aws_instance.jenkins_instance.public_ip}:8080"
}
