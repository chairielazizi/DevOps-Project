# 🚀 DevOps & Cloud Engineering Journey

> **Bridging the gap between software development and cloud-native infrastructure.**  
> A hands-on repository documenting my continuous transition from **Software Developer** to **DevOps & Cloud Engineer**.

---

## 📖 About This Journey

As a software developer, I spent years building user-facing features, frontend interfaces, and backend services. However, modern engineering doesn't stop when code compiles—true software delivery requires scalable architectures, reliable automation, rigorous security boundaries, and resilient cloud systems.

This repository serves as my living portfolio, technical knowledge base, and lab playground. Every directory represents a standalone real-world project, architecture pattern, or automated pipeline designed to master:

- **Infrastructure as Code (IaC)**: Deterministic, version-controlled cloud environments.
- **Continuous Integration & Delivery (CI/CD)**: Zero-friction, automated testing, building, and publishing.
- **Cloud Architecture & Networking**: Resilient multi-tier topologies, security perimeters, and traffic routing.
- **Containers & Orchestration**: Modular service packaging, deployment scaling, and lifecycle management.
- **Observability & DevSecOps**: Principle of least privilege, compliance, monitoring, and proactive reliability.

---

## 🗺️ Project Index & Core Concepts

| # | Project / Module | Category | Primary Tech Stack | Core Concepts & Architecture Covered | Status |
|---|---|---|---|---|:---:|
| 01 | [**Basic Multi-Tier VPC Setup**](./basic-vpc-setup/README.md) | Cloud Networking & IaC | **Terraform**, **AWS** (VPC, Subnets, NAT GW, IGW, NACL, S3 Endpoint) | • 3-Tier Enterprise Network (Public, Application, Database, Management, Platform)<br>• Multi-AZ high availability & subnet isolation<br>• Dynamic HCL (`data.aws_availability_zones`, `cidrsubnet`, `dynamic` blocks)<br>• Provider `default_tags` and lock file (`.terraform.lock.hcl`) integrity | **Completed** ✅ |
| 02 | [**DeskKlean CI/CD Pipeline**](./deskklean-ci-cd/README.md)<br>([GitHub Repo](https://github.com/chairielazizi/deskklean)) | Automation & Release Engineering | **GitHub Actions**, **Electron Builder**, **Node.js** | • Cloud-based cross-compilation on Windows runners<br>• Multi-stage CI pipeline (lint, type-check, unit tests, artifact packaging)<br>• Automated GitHub Releases, tag-triggered publishing, and auto-updater feeds | **Completed** ✅ |
| 03 | [**Prometheus Observability Stack**](./prometheus-observability-stack/learning-plan.md) | Observability & SRE | **Terraform**, **AWS EC2**, **Docker Compose**, **Prometheus**, **Grafana**, **Alertmanager**, **Node Exporter** | • EC2 provisioning via Terraform modules (EC2 + SG)<br>• Multi-container observability stack with Docker Compose<br>• Prometheus scraping, alerting rules, Alertmanager routing<br>• Grafana dashboard import (template 10180)<br>• File-based service discovery, promtool validation | **In Progress** 🚧 |
| 04 | *Containerization & Microservices (Upcoming)* | Containers | **Docker**, **Docker Compose** | • Multi-stage Docker builds, image slimming, non-root user security<br>• Container networking and local multi-service orchestration | *Planned* ⏳ |
| 05 | *Kubernetes Cluster Orchestration (Upcoming)* | Orchestration | **Kubernetes**, **Helm**, **Minikube / EKS** | • Pods, Deployments, Services, ConfigMaps, Secrets, Ingress Controllers<br>• Zero-downtime rolling updates and declarative Helm charts | *Planned* ⏳ |
| 06 | *Observability & Monitoring (Upcoming)* | SRE & Monitoring | **Prometheus**, **Grafana**, **CloudWatch** | • Infrastructure metrics collection, custom application dashboards, and alerting rules | *Planned* ⏳ |

---

## 🏗️ Repository Architecture & Standards

Each project in this repository is organized as an independent, self-contained workspace adhering to industry standards:

```text
devops-project/
├── README.md                      # Global journey roadmap and project registry (You are here)
├── .gitignore                     # Centralized ignores (state files, secrets, binaries)
├── basic-vpc-setup/               # Modular AWS Terraform VPC project
│   ├── main.tf                    # Core infrastructure resources and dynamic HCL logic
│   ├── variables.tf               # Input variables with validation & sane defaults
│   ├── outputs.tf                 # Exported resource IDs, endpoints, and IPs
│   ├── .terraform.lock.hcl        # Cryptographic dependency lock file
│   ├── topology-map.jpg           # Visual architectural diagram
│   └── README.md                  # Comprehensive module documentation and runbooks
├── deskklean-ci-cd/               # Desktop CI/CD & release automation project
│   └── README.md                  # Deep-dive study on GitHub Actions & electron-builder
└── prometheus-observability-stack/  # Observability stack project
    ├── learning-plan.md           # Step-by-step build-from-scratch plan
    ├── prometheus-stack-architecture.html  # Interactive Archify architecture diagram
    └── prometheus-stack-architecture.png       # Static screenshot (PNG, dark mode)
```

### Engineering Principles Practiced Here
1. **DRY (Don't Repeat Yourself)**: Avoid hardcoded configurations; favor dynamic discovery, functions, and maps.
2. **Principle of Least Privilege**: Strict boundary controls across Route Tables, NACLs, and IAM policies.
3. **Reproducibility**: Environment definitions must be deterministic—anyone can clone the repository, run the tooling, and reproduce identical environments.
4. **Transparent Documentation**: Every project must include architectural rationales, decision logs, and step-by-step verification commands.

---

## 📈 Roadmap & Milestones

- [x] **Phase 1: Cloud Networking Fundamentals** (AWS VPC, Subnets, Gateways, NACLs, S3 Endpoints)
- [x] **Phase 2: Modern Infrastructure as Code** (Terraform CLI, Provider locks, Dynamic HCL)
- [x] **Phase 3: CI/CD Foundations** (GitHub Actions, Release pipelines, Artifact management)
- [ ] **Phase 4: Containerization** (Docker, Multi-stage builds, Distroless images)
- [ ] **Phase 5: Orchestration & GitOps** (Kubernetes, Helm, ArgoCD)
- [ ] **Phase 6: Cloud-Native Security & Compliance** (TFLint, tfsec, Trivy, IAM least-privilege)
- [ ] **Phase 7: Site Reliability Engineering (SRE)** (SLIs/SLOs, Prometheus, Grafana, OpenTelemetry)

---

## 👤 Author

**Chairiel Azizi**  
*Software Developer transitioning to DevOps & Cloud Engineer*  
- GitHub: [@chairielazizi](https://github.com/chairielazizi)

