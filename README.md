# Cosmo Router - Infrastructure Setup

## Setup
1. Initialize terraform in the root directory
```
terraform init
```

2. Apply the terraform code to create a VPC, an EKS Cluster, generate a kubconfig and install the Cosmo stack onto the Cluster
```
terraform apply
```

## Infra Architecture
This codebase consists of terraform scripts that provisions an EKS Cluster, and uses the helm provider to install the Cosmo Stack onto a Kubernetes Cluster.

- `vpc.tf`  
-- creates a vpc for which the EKS cluster resides    

- `main.tf`  
-- contains a module `eks` to provision an EKS cls=uster     
-- contains another module to generate the kubeconfig file, and then the file is stored locally using the `local_file` resource     
-- creates a helm release (using the generated kubeconfig file to authenticate to the cluster)  

Note: The helm chart used in the codebase was gotten from `https://artifacthub.io/packages/helm/cosmo-platform/cosmo`

## Future plans
1. Use a remote backend for terraform state management
2. Deploy the infrastructure in the AWS region closest to the customers
2. Follow the setup for production deployments on Cosmo docs

## Troubleshooting
- The postgres pod failed to start and was stuck in a pending state, and thus other components like the controlplane coould not connect to the database and kept crashing