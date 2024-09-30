# Zero Knowledge Proof Authentication (ZKP Auth)

This project demonstrates a Zero Knowledge Proof (ZKP) authentication system implemented in Rust. The system consists of a client and server communicating over gRPC using Docker Compose for container orchestration, deployed on AWS using Terraform and Terragrunt for Infrastructure as Code (IaC).

## Project Structure

```bash
.
├── client                    # Rust client code
│   ├── build.rs
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── docker-compose-client.yml
│   ├── Dockerfile
│   └── src
│       ├── client.rs
│       ├── lib.rs
│       └── zkp_auth.rs
├── docker-compose.yml         # Main Docker Compose configuration
├── infrastructure             # Infrastructure code for deploying on AWS
│   ├── dev
│   │   └── terragrunt.hcl
│   └── modules
│       └── chaum-pederson-zkp
│           ├── main.tf
│           ├── outputs.tf
│           └── variables.tf
├── proto                      # gRPC protobuf definitions
│   └── zkp_auth.proto
└── server                     # Rust server code
    ├── build.rs
    ├── Cargo.lock
    ├── Cargo.toml
    ├── docker-compose-server.yml
    ├── Dockerfile
    └── src
        ├── lib.rs
        ├── server.rs
        └── zkp_auth.rs
```

## Features

- **Rust-based Client and Server**: The client and server are written in Rust and communicate using gRPC over Docker Compose.
- **Dockerized Deployment**: The client and server are containerized and orchestrated using Docker Compose. Separate `docker-compose.yml` files are provided for both.
- **Infrastructure-as-Code (IaC)**: The infrastructure is provisioned on AWS using Terraform and Terragrunt, creating a VPC, subnets, security groups, and EC2 instances.
- **Automated CI/CD**: GitHub Actions pipeline automates building, testing, and deploying the Docker images and Terraform infrastructure.
- **ZKP Authentication Protocol**: Implements Chaum-Pedersen Zero Knowledge Proof authentication.

## Infrastructure Overview

The infrastructure is deployed on AWS using the following components:

- **VPC**: A Virtual Private Cloud with a main subnet and internet gateway.
- **EC2 Instances**: One instance each for the ZKP server and client.
- **Security Groups**: Configured to allow communication over gRPC (`50051`) and SSH (`22`) for EC2 Instance Connect.
- **Terraform & Terragrunt**: Manages AWS resources.

## CI/CD Pipeline (GitHub Actions)

The project uses GitHub Actions to automate the following steps:

### Build, Test, and Deploy Workflow

1. **Build Server Image**: Builds the ZKP server Docker image using Rust and pushes it to DockerHub.
2. **Build Client Image**: Builds the ZKP client Docker image and pushes it to DockerHub.
3. **Test Server and Client**: Docker Compose is used to test the interaction between the client and server.
4. **Deploy on AWS**: The tested server and client are deployed on EC2 instances using Terraform and Terragrunt.
5. **Destroy Infrastructure**: After deployment and testing, the infrastructure is destroyed to save costs.

## Required Secrets

To ensure the GitHub Actions workflow can interact with AWS and DockerHub, create the following secrets in your repository:

- `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID.
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.
- `DOCKER_USERNAME`: Your DockerHub username.
- `DOCKER_PASSWORD`: Your DockerHub password.

You can create these secrets using GitHub CLI:

```bash
gh secret set AWS_ACCESS_KEY_ID --body "your-access-key-id"
gh secret set AWS_SECRET_ACCESS_KEY --body "your-secret-access-key"
gh secret set DOCKER_USERNAME --body "your-docker-username"
gh secret set DOCKER_PASSWORD --body "your-docker-password"
```

### Steps

### Run Tests:

Clone the repository, create the secret and run the gh action, everything is automated.

### Terraform and AWS Resources created

- **VPC**: A Virtual Private Cloud (CIDR: `10.0.0.0/16`).
- **Subnets**: Public subnet for the EC2 instances.
- **Security Groups**: Rules allowing SSH access (`22`) and gRPC communication (`50051`).
- **EC2 Instances**: One for the server and one for the client.

The AWS infrastructure is defined using the following Terraform files:

- `main.tf`: Defines the VPC, subnets, security groups, and EC2 instances.
- `outputs.tf`: Outputs the server's public IP.
- `variables.tf`: Defines variables used in the Terraform configuration.

## License

This project is licensed under the MIT License.

