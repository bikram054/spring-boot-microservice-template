SHELL := /bin/bash

.PHONY: test build up down

build:
	mvn -f product-service/pom.xml clean package -DskipTests
	mvn -f user-service/pom.xml clean package -DskipTests
	mvn -f order-service/pom.xml clean package -DskipTests
	mvn -f eureka-server/pom.xml clean package -DskipTests

up:
	docker-compose -f docker-compose.yml down --remove-orphans
	docker-compose -f docker-compose.yml up --build -d

down:
	docker-compose -f docker-compose.yml down --remove-orphans

test: build
	@echo "Running tests (build + docker-compose + wait + newman)"
	./scripts/run-tests.sh
