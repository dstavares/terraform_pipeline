terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.69.0"
    }
  }
  backend "pg" {}
}

# Provider DigitalOcean
provider "digitalocean" {
  token = var.digitalocean_token
}

# VPC
resource "digitalocean_vpc" "vpc" {
  name   = "live-vpc"
  region = var.region
}

# Cluster Kubernetes
resource "digitalocean_kubernetes_cluster" "k8s" {
  name    = "live-k8s"
  region  = var.region
  version = "latest"
  vpc_uuid = digitalocean_vpc.vpc.id

  node_pool {
    name       = "default"
    size       = "s-2vcpu-4gb"
    node_count = 3
  }
}

# Database Postgres Homolog
resource "digitalocean_database_cluster" "postgres-homolog" {
  name                 = "pg-homolog"
  engine               = "pg"
  version              = "17"
  size                 = "db-s-1vcpu-1gb"
  region               = var.region
  node_count           = 1
  private_network_uuid = digitalocean_vpc.vpc.id
}

# Database Postgres Production
resource "digitalocean_database_cluster" "postgres-production" {
  name                 = "pg-production"
  engine               = "pg"
  version              = "17"
  size                 = "db-s-1vcpu-1gb"
  region               = var.region
  node_count           = 1
  private_network_uuid = digitalocean_vpc.vpc.id
}

# Arquivo de configuração Kubeconfig
resource "local_file" "kubeconfig" {
  content  = digitalocean_kubernetes_cluster.k8s.kube_config[0].raw_config
  filename = "kubeconfig.yaml"
}

# Variáveis
variable "digitalocean_token" {
  type      = string
  sensitive = true
}

variable "region" {
  default = "nyc1"
}