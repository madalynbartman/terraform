output "cluster_id" {
  description = "GKE cluster ID"
  value       = module.madalyn-gke.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = module.madalyn-gke.endpoint
  sensitive   = true
}

output "cluster_name" {
  description = "Google Kubernetes Cluster Name"
  value       = module.madalyn-gke.name
}

output "region" {
  description = "GKE region"
  value       = module.madalyn-gke.region
}

output "project_id" {
  description = "GCP Project ID"
  value       = local.project.project_id
}