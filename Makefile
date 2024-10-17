.PHONY: init volumes secrets start install_k3s install_argocd initial_password install_image_updater install namespaces

ENVS = stage prod
BLUE  := "\033[0;36m"
NC    := "\033[0m" # No Color

ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

args := $(wordlist 2, 100, $(MAKECMDGOALS))

## Create .env file from .env.example
init:
	@echo $(BLUE)"Creating .env file from .env.example..."$(NC)
	@cp .env.example .env
	@echo >> .env
	@echo $(BLUE)".env file created successfully."$(NC)

## Create folders for volumes
volumes:
	@echo $(BLUE)"Creating folders for volumes..."$(NC)
	@for env in $(ENVS); do \
    	for volume in $(VOLUMES); do \
    		echo $(BLUE)"Creating volume folder for $$env/$$volume..."$(NC); \
    		mkdir -p $(PROJECT_DIR)/volumes/$$env/$$volume; \
    		chmod 777 $(PROJECT_DIR)/volumes/$$env/$$volume; \
    	done \
    done
	@echo $(BLUE)"Volume folders created successfully."$(NC)

## Create secrets
secrets:
	@echo $(BLUE)"Creating Kubernetes secrets..."$(NC)
	@for env in $(ENVS); do \
    	for secret in $(SECRETS); do \
    		echo $(BLUE)"Creating secret $$secret-secret in namespace $$env..."$(NC); \
    		kubectl -n $$env create secret generic $$secret-secret --from-literal password=$$(openssl rand -hex 32); \
    	done \
    done
	@echo $(BLUE)"Secrets created successfully."$(NC)

## Install k3s with nginx ingress
install_k3s:
	@echo $(BLUE)"Installing k3s with nginx ingress..."$(NC)
	@curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable traefik --node-name node
	@echo $(BLUE)"Configuring kubectl..."$(NC)
	-@mkdir ~/.kube
	@sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
	@echo $(BLUE)"Applying nginx ingress controller..."$(NC)
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
	@echo $(BLUE)"Patching nginx ingress controller for host network..."$(NC)
	@kubectl patch deployment ingress-nginx-controller -n ingress-nginx --patch '{ "spec": { "template": { "spec": { "hostNetwork": true } } } }'
	@echo $(BLUE)"k3s and nginx ingress installed successfully."$(NC)

## Create namespaces for stage and prod
namespaces:
	@echo $(BLUE)"Creating namespaces for stage and prod..."$(NC)
	@for env in $(ENVS); do \
		echo $(BLUE)"Creating namespace $$env..."$(NC); \
		kubectl create namespace $$env; \
	done
	@echo $(BLUE)"Namespaces created successfully."$(NC)

## Install ArgoCD
install_argocd:
	@echo $(BLUE)"Installing ArgoCD..."$(NC)
	-@kubectl create namespace argocd
	@echo $(BLUE)"Applying ArgoCD manifests..."$(NC)
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo $(BLUE)"Applying ArgoCD ingress..."$(NC)
	@echo $(BLUE)"Waiting for ingress-nginx-controller-admission to be created... If you encounter an error, it will retry automatically."$(NC)
	@until envsubst < ./core/argocd-server-ingress.yaml | kubectl apply -f -; do \
    	echo $(BLUE)"Waiting 15 seconds..."$(NC); \
    	sleep 5; \
    done
	@echo $(BLUE)"Downloading ArgoCD CLI..."$(NC)
	@curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	@sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
	@rm argocd-linux-amd64
	@echo $(BLUE)"Logging into ArgoCD..."$(NC)
	@PASSWORD=$$(argocd admin initial-password -n argocd | head -n 1); \
    argocd login argo.$(STAGE_DOMAIN) --grpc-web --password "$$PASSWORD" --username admin
	@echo $(BLUE)"ArgoCD login successful."$(NC)

	@echo $(BLUE)"Generating SSH key for ArgoCD..."$(NC)
	@ssh-keygen -t rsa -b 4096 -C "test@example.com" -f ~/.ssh/id_rsa -N ""
	@echo $(BLUE)"SSH key generated successfully."$(NC)

	@echo $(BLUE)"Please configure the SSH Deploy Key in the GitHub repository settings for ArgoCD to access your repository."$(NC)
	@echo $(BLUE)"The public key can be found at /root/.ssh/id_rsa.pub. Make sure to give the Deploy Key Write access!"$(NC)
	@bash -c 'read -p "Press any key after you have configured the Deploy Key in GitHub... " -n1 -s'
	@echo "\nContinuing after SSH Deploy Key setup..."

	@echo $(BLUE)"Adding repository to ArgoCD with SSH key..."$(NC)
	@argocd repo add $(SSH_REPO_URL) --ssh-private-key-path ~/.ssh/id_rsa
	@echo $(BLUE)"Repository added to ArgoCD successfully."$(NC)

## Install ArgoCD Image Updater
install_image_updater:
	@echo $(BLUE)"Installing ArgoCD Image Updater..."$(NC)
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
	@echo $(BLUE)"Applying ArgoCD Image Updater configuration..."$(NC)
	@envsubst < ./core/argocd-image-updater-config.yaml | kubectl apply -f -
	@echo $(BLUE)"Restarting ArgoCD Image Updater deployment..."$(NC)
	@kubectl -n argocd rollout restart deployment argocd-image-updater
	@echo $(BLUE)"ArgoCD Image Updater installed and configured successfully."$(NC)

## Get ArgoCD initial admin password
initial_password:
	@echo $(BLUE)"Retrieving initial ArgoCD admin password..."$(NC)
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo $(BLUE)"Initial ArgoCD admin password retrieved."$(NC)

## Install all components
install:
	@echo $(BLUE)"Installing k3s and nginx ingress..."$(NC)
	make install_k3s
	@echo $(BLUE)"Creating namespaces for stage and prod..."$(NC)
	-make namespaces
	@echo $(BLUE)"Installing ArgoCD..."$(NC)
	make install_argocd
	@echo $(BLUE)"Installing ArgoCD Image Updater..."$(NC)
	make install_image_updater
	@echo $(BLUE)"All components installed successfully."$(NC)

## Start all
start:
	@echo $(BLUE)"Running volumes and secrets setup..."$(NC)
	-make volumes secrets
	@echo $(BLUE)"Applying configurations from ./core directory..."$(NC)
	@for file in ./core/*; do envsubst < "$$file" | kubectl apply -f -; done
	@echo $(BLUE)"Setup completed."$(NC)

.DEFAULT_GOAL := help
# See <https://gist.github.com/klmr/575726c7e05d8780505a> for explanation.
help:
	@echo "$$(tput setaf 2)Available rules:$$(tput sgr0)";sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## /---/;td" -e"s/:.*//;G;s/\\n## /===/;s/\\n//g;p;}" ${MAKEFILE_LIST}|awk -F === -v n=$$(tput cols) -v i=4 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"- %s%s%s\n",a,$$1,z;m=split($$2,w,"---");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;}printf"%*s%s\n",-i," ",w[j];}}'
