# Nomad Cluster in Azure

This project implements a highly available HashiCorp Nomad cluster in Azure using Terraform and Ansible. The cluster is automatically provisioned through GitHub Actions and can be used for orchestrating various workloads.

## Overview

### What is Nomad?

[HashiCorp Nomad](https://www.nomadproject.io/) is a flexible workload orchestrator that simplifies the deployment and management of containerized and non-containerized applications. Compared to Kubernetes, Nomad offers a leaner approach with reduced complexity.

### Key Features

- **Highly Available Cluster**: 3-server setup for consensus and fault tolerance
- **Auto-Scaling**: Automatic scaling of client nodes based on utilization
- **Infrastructure as Code**: Fully automated provisioning with Terraform
- **CI/CD Integration**: GitHub Actions workflows for infrastructure and applications
- **Container Registry**: Azure Container Registry (ACR) integration with Managed Identity
- **Secrets Management**: Azure Key Vault for secure storage of secrets

### Technology Stack

- **Infrastructure**: Azure (VMSS, Load Balancer, Key Vault, ACR)
- **IaC**: Terraform for Azure resources
- **Configuration**: Ansible for servers, Cloud-Init for clients
- **CI/CD**: GitHub Actions with OIDC authentication
- **Orchestration**: HashiCorp Nomad + Consul

## Project Structure

```
nomad-cluster/
├── .github/workflows/       # GitHub Actions Workflows
├── ansible/                 # Ansible for server configuration
├── terraform/               # Terraform IaC for Azure
├── jobs/                    # Nomad job definitions
└── docs/                    # Detailed documentation
```

## Getting Started

For detailed instructions on setting up and using the cluster, see the [Setup Documentation](docs/setup.md).

## Documentation

This project contains extensive documentation in the `docs/` directory:

- [**Architecture**](docs/architecture.md): Complete cluster architecture
- [**Simplified Architecture**](docs/architecture-simple.md): Simplified version for quick deployment
- [**Setup Guide**](docs/setup.md): Detailed setup instructions
- [**Security**](docs/security.md): Security notes and best practices
- [**ACR Integration**](docs/acr-integration.md): Azure Container Registry integration
- [**Nomad vs. Kubernetes**](docs/nomad-vs-kubernetes-praesentation.md): Comparison of orchestration platforms

## Technologies Used

- [HashiCorp Nomad](https://www.nomadproject.io/)
- [HashiCorp Consul](https://www.consul.io/)
- [Terraform](https://www.terraform.io/)
- [Ansible](https://www.ansible.com/)
- [Azure Cloud](https://azure.microsoft.com/)
- [GitHub Actions](https://github.com/features/actions)

## License

This project is licensed under the MIT License.
