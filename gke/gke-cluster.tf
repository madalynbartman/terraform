
data "google_compute_zones" "available" {
  region = "us-central1"
  status = "UP"
}

resource "google_compute_network" "default" {
  project                 = local.project.project_id
  name                    = local.project.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "madalyn-gke" {
  project       = local.project.project_id
  network       = google_compute_network.default.name
  name          = local.madalyn_cluster.subnet_name
  ip_cidr_range = local.madalyn_cluster.subnet_range
  region        = local.madalyn_cluster.region

  secondary_ip_range {
    range_name    = format("%s-secondary1", local.madalyn_cluster.cluster_name)
    ip_cidr_range = local.madalyn_cluster.secondary_ip_range_pods
  }

  secondary_ip_range {
    range_name    = format("%s-secondary2", local.madalyn_cluster.cluster_name)
    ip_cidr_range = local.madalyn_cluster.secondary_ip_range_services
  }

  private_ip_google_access = true

}

resource "google_service_account" "sa-madalyn-test" {
  account_id   = "sa-madalyn-test"
  display_name = "sa-madalyn-test"
}

resource "google_project_service" "gcp_resource_manager_api" {
  project = local.project.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "gcp_container_api" {
  project = local.project.project_id
  service = "container.googleapis.com"
}

module "madalyn-gke" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "23.1.0"

  project_id = local.project.project_id
  name       = local.madalyn_cluster.cluster_name

  kubernetes_version     = local.madalyn_cluster.cluster_version
  release_channel        = local.madalyn_cluster.release_channel
  region                 = local.madalyn_cluster.region
  network                = google_compute_network.default.name
  subnetwork             = google_compute_subnetwork.madalyn-gke.name
  master_ipv4_cidr_block = "10.1.0.0/28"
  ip_range_pods          = google_compute_subnetwork.madalyn-gke.secondary_ip_range.0.range_name
  ip_range_services      = google_compute_subnetwork.madalyn-gke.secondary_ip_range.1.range_name

  service_account                 = google_service_account.sa-madalyn-test.email
  master_authorized_networks      = local.madalyn_cluster.master_authorized_networks
  master_global_access_enabled    = false
  istio                           = false
  issue_client_certificate        = false
  enable_private_endpoint         = false
  enable_private_nodes            = true
  remove_default_node_pool        = true
  enable_shielded_nodes           = false
  identity_namespace              = "enabled"
  node_metadata                   = "GKE_METADATA"
  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = false

  node_pools              = local.madalyn_cluster.node_pools
  node_pools_oauth_scopes = local.madalyn_cluster.oauth_scopes
  node_pools_labels       = local.madalyn_cluster.node_pools_labels
  node_pools_metadata     = local.madalyn_cluster.node_pools_metadata
  node_pools_taints       = local.madalyn_cluster.node_pools_taints
  node_pools_tags         = local.madalyn_cluster.node_pools_tags

  depends_on = [
    google_project_service.gcp_resource_manager_api,
    google_project_service.gcp_container_api
  ]
}