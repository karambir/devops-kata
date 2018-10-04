output "elb_address" {
  value = "${aws_elb.edx-elb.dns_name}"
}