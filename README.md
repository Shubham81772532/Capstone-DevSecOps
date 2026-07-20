# Hotstar Clone — DevSecOps CI/CD on AWS EKS

## Architecture

```
Your Local Machine
  │
  ├─ terraform apply      →  VPC + EC2 (Jenkins server) + EKS cluster
  └─ ansible deploy.sh    →  EC2 gets: Java 21, Jenkins, Docker,
                                       SonarQube, AWS CLI, kubectl, Helm
                                           │
                                    GitHub push
                                    (webhook trigger)
                                           │
                                  Jenkins pipeline
                                           │
              ┌────────────┬──────────────┼──────────────┬────────────┐
              │            │              │              │            │
           Checkout   npm install    SonarQube       Docker       OWASP ZAP
                      npm build     (static scan)    Scout        (dynamic)
                                           │
                                    Docker push
                                    (DockerHub)
                                           │
                                    EKS deploy
                                    (Helm + kubectl)
                                           │
                               Prometheus + Grafana
                               (monitoring namespace)
```

## Prerequisites (your local machine)

- [Terraform](https://terraform.io) >= 1.6
- [Ansible](https://ansible.com) (`pip install ansible`)
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- SSH key pair — place `nov-2025-ssh.pem` in the project root

## Step 1 — Provision AWS Infrastructure

```bash
cd Terraform
terraform init
terraform plan
terraform apply
```

Creates: VPC (2 AZs), EC2 (Jenkins server, t3.large, 30GB), EKS cluster (2 × t3.medium nodes)

## Step 2 — Install all tools on EC2 via Ansible

```bash
cd Ansible
./deploy.sh
```

Installs on EC2 via SSH automatically:
- Java 21 (Amazon Corretto)
- Jenkins (port 8080)
- Docker + Docker Scout
- SonarQube (Docker container, port 9000)
- AWS CLI v2
- kubectl v1.33
- Helm 3

## Step 3 — Configure Jenkins (browser, one-time)

1. Open `http://<EC2_PUBLIC_IP>:8080`
2. Use the initial password printed by Ansible
3. Install suggested plugins + these additional ones:
   - **NodeJS Plugin**
   - **SonarQube Scanner**
   - **HTML Publisher**
   - **GitHub Integration Plugin**

4. **Add DockerHub credential:**
   Manage Jenkins → Credentials → Global → Add Credentials
   - Kind: `Username with password`
   - Username: your Docker Hub username
   - Password: Docker Hub **Access Token** (not your login password)
   - ID: `dockerhub-creds`

5. **Configure SonarQube:**
   Manage Jenkins → Configure System → SonarQube servers
   - Name: `sonarqube`
   - URL: `http://localhost:9000`
   - Add a SonarQube token (generate at http://<EC2_IP>:9000 → My Account → Security)

6. **Configure NodeJS:**
   Manage Jenkins → Tools → NodeJS installations → Add
   - Name: `node18`
   - Version: 18.x

## Step 4 — Add GitHub Webhook (enables automatic CI/CD)

In your GitHub repo → Settings → Webhooks → Add webhook:
- Payload URL: `http://<EC2_PUBLIC_IP>:8080/github-webhook/`
- Content type: `application/json`
- Event: Just the push event

In Jenkins job → Configure → Build Triggers:
- Check: **GitHub hook trigger for GITScm polling**

Now every `git push` automatically triggers the full pipeline.

## Step 5 — Create Jenkins Pipeline

1. New Item → Pipeline → name it `hotstar`
2. Pipeline Definition: **Pipeline script from SCM**
3. SCM: Git
4. Repository URL: your GitHub repo URL
5. Branch: `*/main`
6. Script Path: `hotstar-clone/Jenkinsfile`
7. Save → Build Now (first manual run)

## Pipeline Stages

| Stage | What it does |
|---|---|
| Checkout | Clones repo from GitHub |
| Install Dependencies | `npm install` inside hotstar-clone/ |
| Build React App | `npm run build` → produces build/ folder |
| SonarQube Scan | Static analysis on src/ code |
| Docker Build | Multi-stage build: Node → nginx:alpine |
| Docker Scout Scan | CVE scan on the built image |
| OWASP ZAP Scan | Dynamic scan on running container at localhost:8090 |
| Docker Push | Push image:BUILD_NUMBER + image:latest to DockerHub |
| Configure EKS | `aws eks update-kubeconfig` using EC2 IAM role |
| Install Monitoring | Prometheus + Grafana via Helm |
| Deploy Hotstar | `helm upgrade --install` with new image tag |
| Verify Deployment | `kubectl get pods/svc/ingress/hpa` |

## Access the Application

```bash
# Get the Load Balancer URL
kubectl get ingress hotstar
```

## Project Structure

```
.
├── Terraform/
│   ├── main.tf                      # Root: provider + all modules
│   ├── variable.tf
│   ├── terraform.tfvars             # Your values go here
│   ├── output.tf
│   └── modules/
│       ├── VPC/                     # VPC, subnets, IGW, NAT, routes
│       ├── Security-Group/          # Ports 22, 80, 443, 8080, 9000
│       ├── EC2/                     # Jenkins server + IAM role
│       └── EKS/                     # Kubernetes cluster (v1.33)
├── Ansible/
│   ├── deploy.sh                    # Run this to set up EC2
│   ├── inventory.sh                 # Auto-generates inventory from Terraform
│   ├── playbook.yml
│   └── roles/
│       ├── java/                    # Java 21 (Jenkins dependency)
│       ├── jenkins/                 # Jenkins LTS
│       ├── docker/                  # Docker + Docker Scout
│       ├── sonarqube/               # SonarQube as Docker container
│       ├── awscli/                  # AWS CLI v2
│       ├── kubectl/                 # kubectl v1.33
│       └── helm/                    # Helm 3
├── hotstar-clone/
│   ├── Jenkinsfile                  # Full CI/CD pipeline with webhook trigger
│   ├── Dockerfile                   # Multi-stage: Node build → nginx serve
│   ├── nginx.conf                   # React Router support + security headers
│   ├── .dockerignore
│   ├── package.json
│   ├── src/                         # React source code
│   ├── public/
│   └── helm/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml      # With liveness + readiness probes
│           ├── service.yaml
│           ├── ingress.yaml
│           └── hpa.yaml             # Auto-scaling (1-4 pods, 70% CPU)
└── monitoring/
    └── values-monitoring.yaml       # Prometheus + Grafana config
```
