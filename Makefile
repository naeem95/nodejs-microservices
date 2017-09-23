#.SILENT:
help:
	echo
	echo "NodeSource Metrics Server Make commands"
	echo
	echo "  Commands: "
	echo
	echo "    help - show this message"
	echo "    build - Build the Docker images that power local dev (docker)"
	echo "    clean - Remove docker containers"
	echo "    run - Start this service, and all of its deps, locally (docker)"
	echo "    deploy - Deploy this app to Google Cloud (kubernetes)"
	echo "    provision-cluster - Provision a remote kubernetes cluster"
	echo "    delete-cluster - Remove a remote kubernetes cluster"
	echo "    dashboard - Start the kubectl dashboard"
	echo "    test-integration - Run integration tests for this project"
	echo "    test-all - Run all tests for this project"
	echo "    deps - Check for all dependencies"

build: clean
	docker-compose -f ./run.yml build
	docker tag consumer gcr.io/nodejs-microservices/consumer:latest
	docker tag producer gcr.io/nodejs-microservices/producer:latest
	docker tag nginx gcr.io/nodejs-microservices/nginx:latest

run: build
	docker-compose -f ./run.yml up

clean:
	docker-compose -f ./run.yml rm -f
	docker-compose -f ./test.yml rm -f

clean-deploy: clean
	gcloud config set project nodejs-microservices
	gcloud container clusters get-credentials microservices
	kubectl delete -f kube.yml || true

deploy: clean-deploy build
	gcloud config set project nodejs-microservices
	gcloud docker -- push gcr.io/nodejs-microservices/consumer:latest
	gcloud docker -- push gcr.io/nodejs-microservices/producer:latest
	gcloud docker -- push gcr.io/nodejs-microservices/nginx:latest
	gcloud container clusters get-credentials microservices
	kubectl create -f kube.yml
	kubectl get services
	echo "Run `kubectl get services` to fetch NGinx's ip address"

provision-cluster:
	gcloud config set project nodejs-microservices
	gcloud container clusters create microservices

delete-cluster:
	gcloud config set project nodejs-microservices
	gcloud container clusters delete microservices -q

dashboard:
	gcloud config set project nodejs-microservices
	gcloud container clusters get-credentials microservices
	echo "Navigate to 127.0.0.1:8001/ui in your browser"
	kubectl proxy

build-test-integration: build
	docker-compose -f ./test.yml build

test-integration: clean
	docker-compose -f ./test.yml up

test-all: test-integration

deps:
	echo "  Dependencies: "
	echo
	echo "    * docker $(shell which docker > /dev/null || echo '- \033[31mNOT INSTALLED\033[37m')"
	echo "    * docker-compose $(shell which docker-compose > /dev/null || echo '- \033[31mNOT INSTALLED\033[37m')"
	echo "    * gcloud $(shell which gcloud > /dev/null || echo '- \033[31mNOT INSTALLED\033[37m')"
	echo "    * kubectl $(shell which kubectl > /dev/null || echo '- \033[31mNOT INSTALLED\033[37m')"
	echo
