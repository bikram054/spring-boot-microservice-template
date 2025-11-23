SHELL := /bin/bash

.PHONY: build up down logs clean status perf-test postman-test

build:
	@echo "Building all services..."
	mvn clean package -DskipTests

up:
	docker-compose up --build -d

down:
	docker-compose down --remove-orphans

logs:
	docker-compose logs -f

status:
	docker-compose ps

clean:
	docker-compose down --remove-orphans --volumes
	docker system prune -f

perf-test:
	@echo "Running JMeter performance tests..."
	docker run --rm --network ms_microservices-network \
		-v $(PWD)/tests/performance-tests:/tests \
		-v $(PWD)/tests/performance-tests/results:/results \
		alpine/jmeter:latest \
		-n -t /tests/test-plan.jmx \
		-l /results/results-$(shell date +%Y%m%d-%H%M%S).jtl \
		-Jgateway.host=gateway-server \
		-Jgateway.port=8080 \
		-Jauth.username=${AUTH_USERNAME} \
		-Jauth.password=${AUTH_PASSWORD}

postman-test:
	@echo "Running Postman tests via gateway..."
	docker run --rm --network ms_microservices-network \
		-v $(PWD)/tests/functional-tests:/etc/newman \
		postman/newman:alpine \
		run api-tests.postman_collection.json \
		-e api-environment.postman_environment.json \
		--env-var gatewayBaseUrl=http://gateway-server:8080
