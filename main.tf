module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "cosmos-router"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  node_security_group_additional_rules = {
    ingress_to_nodeport = {
      description = "From the internet to the cluster NodePort range"
      protocol    = "tcp"
      from_port   = 30000
      to_port     = 32767
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  eks_managed_node_groups = {
    example = {
      min_size     = 1
      max_size     = 5
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  enable_cluster_creator_admin_permissions = true

  depends_on = [module.vpc]

  tags = {
    Terraform = "true"
  }
}

module "eks-kubeconfig" {
  source       = "hyperbadger/eks-kubeconfig/aws"
  version      = "2.0.0"
  cluster_name = module.eks.cluster_name
  depends_on   = [module.eks]
}

resource "local_file" "kubeconfig" {
  content  = module.eks-kubeconfig.kubeconfig
  filename = "${path.module}/kubeconfig"
}

resource "helm_release" "cosmo" {
  name       = "cosmo-router"
  chart      = "router"
  version    = "0.4.0"
  repository = "oci://ghcr.io/wundergraph/cosmo/helm-charts"

  values = [
    "${file("helm/values.yaml")}"
  ]

  depends_on = [local_file.kubeconfig]
}