terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.52.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
  }
}

provider "aws" {
  # Configuration options
  region  = "us-east-1"
  profile = "tga"
}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}

