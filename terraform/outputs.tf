output "edx_app_private_ip" {
  value = "${aws_instance.edx-app-server.private_ip}"
}
