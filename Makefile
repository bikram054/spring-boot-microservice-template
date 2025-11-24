SHELL := /bin/bash

# Service configuration
SERVICES := user-service product-service order-service
PORT_user-service := 8081
PORT_product-service := 8082
PORT_order-service := 8083

.PHONY: help build build-image build-images run-all stop-all load-images deploy deploy-remote pull-images update-images undeploy logs clean k8s-status setup-cluster k0s-start k0s-stop k0s-reset populate-data deploy-traefik

# Default target
.DEFAULT_GOAL := help

help:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║           Microservices Makefile - Available Targets          ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "📦 Build Targets:"
	@echo "  make build              - Build all services with Maven (parallel)"
	@echo "  make build-image        - Build single service image (requires SERVICE=name)"
	@echo "  make build-images       - Build all service images with buildah"
	@echo ""
	@echo "💻 Local Development:"
	@echo "  make run-all            - Run all services locally with Spring Boot"
	@echo "  make stop-all           - Stop all locally running services"
	@echo ""
	@echo "🛠️ Utilities:"
	@echo "  make populate-data - Populate test data"
	@echo "  make deploy-traefik - Deploy Traefik gateway"
	@echo ""
	@echo "🚀 Deployment Targets:"
	@echo "  make deploy             - Deploy using local images"
	@echo "  make deploy-remote      - Deploy using remote images from ghcr.io"
	@echo "  make load-images        - Load local images into k0s"
	@echo "  make pull-images        - Pull remote images into k0s"
	@echo "  make update-images      - Restart deployments with latest images"
	@echo "  make undeploy           - Remove all deployments"
	@echo ""
	@echo "🔧 Cluster Management:"
	@echo "  make setup-cluster      - Install and configure k0s cluster"
	@echo "  make k0s-start          - Start k0s cluster"
	@echo "  make k0s-stop           - Stop k0s cluster"
	@echo "  make k0s-reset          - Uninstall k0s cluster"
	@echo ""
	@echo "📊 Monitoring & Debugging:"
	@echo "  make logs               - View logs (default: user-service, use SERVICE=name)"
	@echo "  make k8s-status         - Show detailed cluster status"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean              - Delete ms namespace and all resources"
	@echo ""
	@echo "💡 Examples:"
	@echo "  make build-image SERVICE=user-service"
	@echo "  make logs SERVICE=product-service"
	@echo ""

setup-cluster:
	@echo "Setting up single-node k0s cluster..."
	curl -sSLf https://get.k0s.sh | sudo sh
	sudo k0s install controller --single
	sudo k0s start
	@echo "Waiting for k0s to start..."
	@sleep 10
	@echo "Exporting kubeconfig..."
	mkdir -p ~/.kube
	sudo k0s kubeconfig admin > ~/.kube/config
	chmod 600 ~/.kube/config
	@echo "Cluster setup complete!"

k0s-start:
	@echo "Starting k0s..."
	sudo k0s start
	@echo "k0s started!"

k0s-stop:
	@echo "Stopping k0s..."
	sudo k0s stop
	@echo "k0s stopped!"

k0s-reset:
	@echo "Resetting k0s (uninstalling)..."
	sudo k0s stop || true
	sudo k0s reset
	@echo "k0s reset complete!"

build:
	@echo "Building all services with Maven parallel build (1 thread per CPU core)..."
	mvn -T 1C clean package -DskipTests

run-all:
	@echo "Starting all services locally..."
	@echo "Services will run on:"

	@echo "  - user-service:    http://localhost:8081"
	@echo "  - product-service: http://localhost:8082"
	@echo "  - order-service:   http://localhost:8083"
	@echo ""
	@echo "Press Ctrl+C to stop all services"
	@echo ""
	@trap 'echo "\nStopping all services..."; pkill -f "spring-boot:run"; exit' INT; \
	for service in $(SERVICES); do \
		case $$service in \
			gateway-server) port=8080 ;; \
			user-service) port=8081 ;; \
			product-service) port=8082 ;; \
			order-service) port=8083 ;; \
		esac; \
		echo "Starting $$service on port $$port..."; \
		(cd $$service && mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=$$port" > /tmp/$$service.log 2>&1 &); \
	done; \
	echo ""; \
	echo "All services started! Logs are in /tmp/<service>.log"; \
	echo "Waiting for services to initialize..."; \
	sleep 5; \
	echo "Services are running. Press Ctrl+C to stop."; \
	while true; do sleep 1; done

stop-all:
	@echo "Stopping all locally running services..."
	@pkill -f "spring-boot:run" || echo "No services running"
	@rm -f /tmp/gateway-server.log /tmp/user-service.log /tmp/product-service.log /tmp/order-service.log
	@echo "All services stopped and logs cleaned up!"
populate-data:
	@echo "Populating test data..."
	@python3 tests/populate_data.py
deploy-traefik:
	@echo "Deploying Traefik gateway..."
	@sudo k0s kubectl apply -f k8s/traefik.yaml


build-image:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: SERVICE parameter is required"; \
		echo "Usage: make build-image SERVICE=user-service"; \
		@echo "Available services: user-service, product-service, order-service"; \
		exit 1; \
	fi
	@case $(SERVICE) in \
		gateway-server) PORT=8080 ;; \
		user-service) PORT=8081 ;; \
		product-service) PORT=8082 ;; \
		order-service) PORT=8083 ;; \
		*) echo "Error: Unknown service $(SERVICE)"; exit 1 ;; \
	esac; \
	echo "Building JVM image for $(SERVICE) on port $$PORT..."; \
	buildah bud \
		--target jvm-runtime \
		--build-arg SERVICE_NAME=$(SERVICE) \
		--build-arg PORT=$$PORT \
		-t $(SERVICE):latest \
		-f Containerfile .

build-images:
	@echo "Building JVM images for all services..."
	@for service in $(SERVICES); do \
		case $$service in \
			gateway-server) port=8080 ;; \
			user-service) port=8081 ;; \
			product-service) port=8082 ;; \
			order-service) port=8083 ;; \
		esac; \
		echo "Building $$service:latest (port $$port)..."; \
		buildah bud \
			--target jvm-runtime \
			--build-arg SERVICE_NAME=$$service \
			--build-arg PORT=$$port \
			-t $$service:latest \
			-f Containerfile . || exit 1; \
	done
	@echo "All JVM images built successfully!"


load-images:
	@echo "Loading local images into k0s..."
	@for service in $(SERVICES); do \
		echo "Loading $$service..."; \
		buildah push $$service:latest oci-archive:/tmp/$$service.tar && \
		sudo k0s ctr images import /tmp/$$service.tar; \
		rm -f /tmp/$$service.tar; \
	done
	@echo "All images loaded!"


deploy:
	@echo "Deploying to k0s Kubernetes (using local images)..."
	sudo k0s kubectl apply -f k8s/namespace.yaml
	sudo k0s kubectl apply -f k8s/

deploy-remote:
	@echo "Deploying to k0s using remote images from ghcr.io/bikram054/ms..."
	@echo "Checking k0s status..."
	@if ! sudo k0s status > /dev/null 2>&1; then \
		echo "Error: k0s is not running"; \
		echo "Please start k0s first with: sudo k0s start"; \
		exit 1; \
	fi
	@echo "Creating namespace..."
	@sudo k0s kubectl apply -f k8s/namespace.yaml
	@echo "Pre-pulling images..."
	@for service in $(SERVICES); do \
		echo "Pulling $$service..."; \
		sudo k0s ctr images pull ghcr.io/bikram054/ms/$$service:latest > /dev/null 2>&1 || true; \
		sudo k0s ctr images tag ghcr.io/bikram054/ms/$$service:latest $$service:latest > /dev/null 2>&1 || true; \
	done
	@echo "Deploying microservices..."

	@sudo k0s kubectl apply -f k8s/user-service.yaml
	@sudo k0s kubectl apply -f k8s/product-service.yaml
	@sudo k0s kubectl apply -f k8s/order-service.yaml
	@echo "Waiting for deployments to be ready..."
	@if sudo k0s kubectl wait --for=condition=available --timeout=300s deployment --all -n ms; then \
		echo "All deployments are ready!"; \
	else \
		echo "Warning: Some deployments may not be ready yet"; \
	fi
	@echo "Deployment complete!"

pull-images:
	@echo "Pre-pulling images from ghcr.io/bikram054/ms to k0s nodes..."
	@for service in $(SERVICES); do \
		echo "Pulling $$service..."; \
		sudo k0s ctr images pull ghcr.io/bikram054/ms/$$service:latest || true; \
	done
	@echo "All images pulled!"


update-images:
	@echo "Updating deployments with latest images..."
	sudo k0s kubectl rollout restart deployment --all -n ms
	@echo "Waiting for rollout to complete..."
	sudo k0s kubectl rollout status deployment --all -n ms
	@echo "Update complete!"

undeploy:
	@echo "Removing microservices from k0s..."
	sudo k0s kubectl delete -f k8s/ --ignore-not-found=true
	@echo "Microservices removed!"

logs:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Showing logs for gateway-server (default)..."; \
		echo "Use: make logs SERVICE=<service-name> to view specific service"; \
		sudo k0s kubectl logs -n ms -l app=gateway-server -f; \
	else \
		echo "Showing logs for $(SERVICE)..."; \
		sudo k0s kubectl logs -n ms -l app=$(SERVICE) -f; \
	fi

k8s-status:
	@echo "=== Kubernetes Resources in ms namespace ==="
	@sudo k0s kubectl get all -n ms
	@echo ""
	@echo "=== Pod Details ==="
	@sudo k0s kubectl get pods -n ms -o wide

clean:
	@echo "Cleaning up ms namespace..."
	sudo k0s kubectl delete namespace ms --ignore-not-found=true
	@echo "Cleanup complete!"
