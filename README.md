# Cosmo Router - Infrastructure Setup

## Setup

1. Login to the Wundergraph UI and generate an API key. Once done, set it as an environment variable
    ```sh
    export COSMO_API_KEY="cosmo_da6f1b9f3e9cf4e4123f57b39dcfba53"
    ```

2. Create a federated graph
    ```sh
    npx wgc federated-graph create my-graph --namespace default --label-matcher team=A --routing-url http://localhost:3002/graphql
    ```

3. Create a subgraph
    ```sh
    npx wgc subgraph publish my-subgraph --namespace default --schema schema.graphql --label team=A --routing-url http://localhost:3002/graphql
    ```

4. Then generate the graph api auth token
    ```sh
    npx wgc router token create my-token -n default -g my-graph
    ```

    `Note`: A token will be displayed to stdout. Store it somewhere!

5. Create a `helm/values.yaml` file from the `helm/values.yaml.example` file. Then set the auth token here
    ```yaml
    configuration:
      # -- The router token is used to authenticate the router against the controlplane (required)
      graphApiToken: "<replace-me>"
    ```

6. Clone the repo and initialize terraform in the root directory
    ```sh
    terraform init
    ```

7. Apply the terraform code to create a VPC, an EKS Cluster, generate a kubconfig and install the Cosmo stack onto the Cluster
    ```
    terraform apply
    ```

    After running the above, a `kubeconfig` file will be created at the root of the repo with an ephemeral (short-lived) token. Thus, you might run into the issue where `terraform apply` fails because of an expired token. You can fix this by replacing the `token` field

    ```
    - "name": "terraform"
      "user":
        "token": "k8s-aws-v1.aHR0cHM6Ly9zdHMudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20vP0FjdGlvbj1HZXRDYWxsZXJJZGVudGl0eSZWZXJzaW9uPTIwMTEtMDYtMTUmWC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBNk9EVTNVVkpJNUlPUVBGUSUyRjIwMjQwNjA2JTJGdXMtZWFzdC0xJTJGc3RzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDA2MDZUMDgyNzQwWiZYLUFtei1FeHBpcmVzPTAmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JTNCeC1rOHMtYXdzLWlkJlgtQW16LVNpZ25hdHVyZT1iOWE2NDQ3NTdhYmUwODEzOGI2ODg4NjIwYzU4YmRiNjQ2N2ZmZThiYWNjYjRmZTUxNGYxZDYzNGJiMDIzYThk"
    ```

    with an `exec` block for example:
    ```
    - "name": "terraform"
      "user":
        exec:
            apiVersion: client.authentication.k8s.io/v1beta1
            args:
              - '--region'
              - us-east-1
              - eks
              - get-token
              - '--cluster-name'
              - cosmos-router
              - '--output'
              - json
            command: aws
            env:
              - name: AWS_PROFILE
                value: tga
    ```
    This `exec` block can be retrieved from your local kubeconfig (kubectl config view), after having updated it using:
    ```
    aws eks update-kubeconfig --region us-east-1 --name cosmos-router --profile tga
    ```

8. You can access the router using the K8s Node IP and NodePort:
    ```
    http://<Node-IP>:<NodePort>
    ```

## Infra Architecture
This codebase consists of terraform scripts that provisions an EKS Cluster, and uses the helm provider to install the Cosmo Stack onto a Kubernetes Cluster.

- `vpc.tf`  
-- creates a vpc for which the EKS cluster resides    

- `main.tf`  
-- contains a module `eks` to provision an EKS cls=uster     
-- contains another module to generate the kubeconfig file, and then the file is stored locally using the `local_file` resource     
-- creates a helm release (using the generated kubeconfig file to authenticate to the cluster)  


## Future plans
1. Use a remote backend for terraform state management
2. Find a better solution to manage the ephemeral kubeconfig token
3. Deploy the infrastructure in the AWS region closest to the customers
4. Follow the setup for production deployments on Cosmo docs
