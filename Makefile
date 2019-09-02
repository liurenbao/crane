SHELL := /bin/bash

DockerHubRepoName := "slzcc"
ProjectName := "crane"
VERSION := "v1.15.3.3"
CRANE_ENTRANCE := "main.yml"

build:
	@docker build -t ${DockerHubRepoName}/${ProjectName}:$(VERSION) . --no-cache
		
push:
	@docker push ${DockerHubRepoName}/${ProjectName}:$(VERSION)

run_main:
	@docker rm -f crane || true
	@docker run --name crane --rm -i -v ~/.ssh:/root/.ssh -v ${PWD}:/crane ${DockerHubRepoName}/${ProjectName}:$(VERSION) -i nodes ${CRANE_ENTRANCE}

local_save_image:
	@docker pull slzcc/kubernetes:`awk '/^k8s_version/{print}' ./group_vars/all.yml | awk -F': ' '{print $2}' | sed -r "s/'//g"`
	@docker save -o roles/downloads-packages/files/kubernetes.tar.gz slzcc/kubernetes:`awk '/^k8s_version/{print}' ./group_vars/all.yml | awk -F': ' '{print $2}' | sed -r "s/'//g"`

local_load_image:
	@docker run --name import-kubernetes-temporary -d -v /var/run/docker.sock:/var/run/docker.sock:ro slzcc/kubernetes:`awk '/^k8s_version/{print}' ./group_vars/all.yml | awk -F': ' '{print $2}' | sed -r "s/'//g"` sleep 1234567
	@until docker exec -i import-kubernetes-temporary bash /docker-image-import.sh ; do >&2 echo "Starting..." && sleep 1 ; done
	@docker rm -f import-kubernetes-temporary