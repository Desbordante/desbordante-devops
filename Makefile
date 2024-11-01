.PHONY: env up pull update init down

ifeq ($(shell test -e '.env' && echo -n yes), yes)
	include .env
endif

args := $(wordlist 2, 100, $(MAKECMDGOALS))

## Create .env file from .env.example
env:
	@cp .env.example .env
	@echo >> .env
	@echo "SECRET_KEY=$$(openssl rand -hex 32)" >> .env

## Create folders for volumes
volumes:
	@for volume in postgres rabbitmq uploads; do \
    	mkdir -p ./volumes/$$volume; \
    	chmod 777 ./volumes/$$volume; \
    done

## Initiate repository
init:
	make env volumes

## Pull docker containers
pull:
	docker compose pull

## Up docker containers
up:
	docker compose up --force-recreate --remove-orphans -d

## Down docker containers
down:
	docker compose down

## Pull & up containers
update:
	make pull up

## Up docker containers in dev mode
dev:
	(trap 'docker compose down' INT; \
	docker compose up --force-recreate --remove-orphans)

.DEFAULT_GOAL := help
# See <https://gist.github.com/klmr/575726c7e05d8780505a> for explanation.
help:
	@echo "$$(tput setaf 2)Available rules:$$(tput sgr0)";sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## /---/;td" -e"s/:.*//;G;s/\\n## /===/;s/\\n//g;p;}" ${MAKEFILE_LIST}|awk -F === -v n=$$(tput cols) -v i=4 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"- %s%s%s\n",a,$$1,z;m=split($$2,w,"---");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;}printf"%*s%s\n",-i," ",w[j];}}'
