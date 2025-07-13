output "cluster_id" {
  value = aws_eks_cluster.giri.id
}

output "node_group_id" {
  value = aws_eks_node_group.giri.id
}

output "vpc_id" {
  value = aws_vpc.giri_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.giri_subnet[*].id
}
