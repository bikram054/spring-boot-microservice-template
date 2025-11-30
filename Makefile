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
	@echo "  make build-image        - Build single JVM image (requires SERVICE=name)"
	@echo "  make build-images       - Build all JVM images with buildah"
	@echo ""
	@echo "💻 Local Development:"
	@echo "  make run-all            - Run all services locally with Spring Boot"
	@echo ""
	@echo "🛠️ Utilities:"
	@echo "  make populate-data - Populate test data"
	@echo ""
	@echo "🚀 Deployment Targets:"
	@echo "  make deploy             - Build, load images, apply manifests, and rollout"
	@echo ""
	@echo "🔧 Cluster Management:"
	@echo "  make setup-dev-env      - Install k0s, buildah, and configure cluster"
	@echo "  make k0s-start          - Start k0s cluster"
	@echo "  make k0s-stop           - Stop k0s cluster"
	@echo ""
	@echo "📊 Monitoring & Debugging:"
	@echo "  make logs               - View logs (default: user-service, use SERVICE=name)"
	@echo "  make signoz-ui          - Access SigNoz UI (port-forward)"
	@echo "  make k8s-status         - Show detailed cluster status"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean              - Full system reset (stops services, resets k0s, cleans images)"
	@echo ""
	@echo "💡 Examples:"
	@echo "  make build-image SERVICE=user-service"
	@echo "  make logs SERVICE=product-service"
	@echo ""

setup-dev-env:
	@echo "Installing Buildah and dependencies..."
	sudo apt-get update && sudo apt-get install -y buildah slirp4netns fuse-overlayfs
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
	@echo "Development environment setup complete!"

k0s-start:
	@echo "Starting k0s..."
	sudo k0s start
	@echo "k0s started!"

k0s-stop:
	@echo "Stopping k0s..."
	sudo k0s stop
	@echo "k0s stopped!"

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

populate-data:
	@echo "Populating test data..."
	@echo "Setting up temporary port-forward to Nginx Ingress..."
	@k0s kubectl port-forward -n ms svc/nginx-ingress-controller 9090:80 > /dev/null 2>&1 & \
	PID=$$!; \
	sleep 5; \
	python3 tests/populate_data.py --url http://localhost:9090 || (kill $$PID && exit 1); \
	kill $$PID


build-image:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: SERVICE parameter is required"; \
		echo "Usage: make build-jvm SERVICE=user-service"; \
		@echo "Available services: user-service, product-service, order-service"; \
		exit 1; \
	fi
	@case $(SERVICE) in \
		user-service) PORT=8081 ;; \
		product-service) PORT=8082 ;; \
		order-service) PORT=8083 ;; \
		*) echo "Error: Unknown service $(SERVICE)"; exit 1 ;; \
	esac; \
	echo "Building JVM image for $(SERVICE) on port $$PORT..."; \
	buildah bud \
		--volume $(HOME)/.m2:/root/.m2:ro \
		--build-arg SERVICE_NAME=$(SERVICE) \
		--build-arg PORT=$$PORT \
		-t $(SERVICE):jvm \
		-f Containerfile.jvm .

build-images:
	@echo "Building JVM images for all services..."
	@for service in $(SERVICES); do \
		case $$service in \
			user-service) port=8081 ;; \
			product-service) port=8082 ;; \
			order-service) port=8083 ;; \
		esac; \
		echo "Building $$service:jvm (port $$port)..."; \
		buildah bud \
			--volume $(HOME)/.m2:/root/.m2:ro \
			--build-arg SERVICE_NAME=$$service \
			--build-arg PORT=$$port \
			-t $$service:jvm \
			-f Containerfile.jvm . || exit 1; \
	done
	@echo "All JVM images built successfully!"


deploy:
	@echo "Loading local JVM images into k0s..."
	@for service in $(SERVICES); do \
		echo "Loading $$service..."; \
		buildah push $$service:jvm oci-archive:/tmp/$$service.tar:docker.io/library/$$service:jvm && \
		sudo k0s ctr images import /tmp/$$service.tar -n k8s.io; \
		rm -f /tmp/$$service.tar; \
	done
	@echo "All JVM images loaded!"
	@echo "Deploying to k0s Kubernetes..."
	k0s kubectl apply -f k8s/
	@echo "Updating deployments with latest images..."
	k0s kubectl rollout restart deployment -n ms
	@echo "Waiting for rollout to complete..."
	k0s kubectl rollout status deployment/order-service -n ms
	k0s kubectl rollout status deployment/product-service -n ms
	k0s kubectl rollout status deployment/user-service -n ms
	@echo "✅ Deployment complete!"

logs:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Showing logs..."; \
		echo "Use: make logs SERVICE=<service-name> to view specific service"; \
		k0s kubectl logs -n ms -l app=user-service -f; \
	else \
		echo "Showing logs for $(SERVICE)..."; \
		k0s kubectl logs -n ms -l app=$(SERVICE) -f; \
	fi

k8s-status:
	@echo "=== Kubernetes Resources in ms namespace ==="
	@k0s kubectl get all -n ms
	@echo ""
	@echo "=== Pod Details ==="
	@k0s kubectl get pods -n ms -o wide

signoz-ui:
	@echo "Setting up port-forward for SigNoz UI..."
	@echo "Access SigNoz at: http://localhost:3301"
	@k0s kubectl port-forward -n ms svc/signoz 3301:8080

clean:
	@echo "FULL SYSTEM CLEANUP INITIATED..."
	@echo "1. Stopping local services..."
	@pkill -f "spring-boot:run" || echo "No local services running"
	@rm -f /tmp/user-service.log /tmp/product-service.log /tmp/order-service.log
	@echo "2. Resetting k0s cluster..."
	sudo k0s stop || true
	sudo k0s reset || true
	@echo "3. Cleaning Buildah images and containers..."
	@buildah rm --all || true
	@buildah rmi --all --force || true
	@echo "4. Removing configuration files..."
	sudo rm -rf /var/lib/k0s /etc/k0s /usr/local/bin/k0s
	rm -rf ~/.kube
	@echo "✅ Cleanup complete! Environment is fully reset."

