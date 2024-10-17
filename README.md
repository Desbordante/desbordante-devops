# Desbordante DevOps Repository

This repository is designed to facilitate the deployment and management of
applications using modern DevOps practices and tools.

## Technologies Used

- **K3s**: Lightweight Kubernetes distribution for deploying containerized applications.
- **ArgoCD**: A declarative GitOps continuous delivery tool for Kubernetes.
- **Argocd Image Updater**: Automatically updates images in Kubernetes manifests based on new versions available in
  container registries.

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/Desbordante/desbordante-devops -b k8s
cd desbordante-devops
```

### Step 2: Initialize the Environment

Before running any commands, ensure you have initialized the environment variables.

```bash
make init
```

This will create a `.env` file from `.env.example`.

### Step 3: Configure Environment Variables

Edit the `.env` file to set your environment variables. Make sure to define variables such
as `PROJECT_DIR`, `VOLUMES`, `SECRETS`, `STAGE_DOMAIN`, and `SSH_REPO_URL`.

### Step 4: Install Required Components

Run the following command to install K3s, Ingress, ArgoCD, and the ArgoCD Image Updater:

```bash
make install
```

## **IMPORTANT: GitHub Deploy Token Configuration**

During the installation process, you will be prompted to **configure the GitHub repository deploy token**.

### **Please ensure you have set up the SSH Deploy Key in your GitHub repository settings before proceeding!**

- The **public key** can be found at `/root/.ssh/id_rsa.pub`.
- Make sure to give the **Deploy Key Write access** to allow ArgoCD to interact with the repository.

This is crucial for the successful interaction between ArgoCD and your GitHub repository.


### Step 5: Start the Environment

After the installation, you can start the environment and apply the configurations defined in the `core` directory:

```bash
make start
```

### Accessing ArgoCD

To access the ArgoCD web UI, use the following URL:

```bash
https://argo.$(STAGE_DOMAIN)
```
(e.g., [https://argo.desbordemo.store](https://argo.desbordemo.store))

To retrieve the initial admin password for ArgoCD, run:

```bash
make initial_password
```

This command will provide you with the password needed to log in.

### Note on Changes in Core Directory

If you make changes to files in the `core` directory, you need to rerun the `start` command to apply the new
configurations.

## Useful Commands

- To view the logs of the ArgoCD Image Updater:

```bash
kubectl -n argocd logs --selector app.kubernetes.io/name=argocd-image-updater --follow
```

- To change the password for the ArgoCD admin account:

```bash
argocd account update-password --account admin --current-password "$(make initial_password)" --new-password 123456789
```

- To show errors for the root ApplicationSet
```bash
kubectl describe applicationset root -n argocd
```

This setup has been tested on **Ubuntu 24.04**.
