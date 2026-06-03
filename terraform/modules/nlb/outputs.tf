output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "tg_controlplane_arn" {
  value = aws_lb_target_group.controlplane_tg.arn
}

output "tg_wireguard_arn" {
  value = aws_lb_target_group.wireguard_tg.arn
}
