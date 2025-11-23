# Spring Boot Microservices Template

A production-ready microservices architecture built with Spring Boot 3.5, Spring Cloud 2025.0.0, and GraalVM native image support.

## 🏗️ Architecture

This project implements a microservices architecture with service discovery, API gateway, and multiple business services:

```
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway (8080)                      │
│                     gateway-server                           │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├─────────────────────────────────────────┐
               │                                         │
       ┌───────▼────────┐                       ┌────────▼────────┐
       │ Service Registry│                       │ Business Services│
       │ eureka-server   │                       ├─────────────────┤
       │   (8761)        │◄──────────────────────┤ user-service    │
       └─────────────────┘                       │   (8081)        │
                                                 │ product-service │
                                                 │   (8082)        │
                                                 │ order-service   │
                                                 │   (8083)        │
                                                 └─────────────────┘
```

### Services

- **eureka-server** (8761): Service discovery and registration
- **gateway-server** (8080): API Gateway with routing and load balancing
- **user-service** (8081): User management service
- **product-service** (8082): Product catalog service
- **order-service** (8083): Order processing service with circuit breaker

## 📦 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── native-build.yml       # CI/CD for native image builds
├── eureka-server/                 # Service discovery
├── gateway-server/                # API Gateway
├── user-service/                  # User management
├── product-service/               # Product catalog
├── order-service/                 # Order processing
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml
│   ├── eureka-server.yaml
│   ├── gateway-server.yaml
│   ├── user-service.yaml
│   ├── product-service.yaml
│   └── order-service.yaml
├── tests/                        # Test suites
│   ├── functional-tests/         # Postman collections
│   └── performance-tests/        # JMeter tests
├── Containerfile                 # Generic native image build
├── pom.xml                       # Parent POM with native profile
├── Makefile                      # Build automation
├── run-all.sh                    # Start all services locally
├── stop-all.sh                   # Stop all services
└── populate_data.py              # Test data population
```

## 🚀 Quick Start

### Prerequisites

- **Java 21** (Temurin or similar)
- **Maven 3.9+**
- **Docker** (for containerized builds)
- **GraalVM** (optional, for local native builds)

### Local Development

**Option 1: Run all services with Maven**
```bash
# Start all services with local profile
./run-all.sh

# Stop all services
./stop-all.sh
```

**Option 2: Run individual services**
```bash
# Build all services
mvn clean package -DskipTests

# Start Eureka first
cd eureka-server && mvn spring-boot:run &

# Wait for Eureka, then start other services
cd user-service && mvn spring-boot:run &
cd product-service && mvn spring-boot:run &
cd order-service && mvn spring-boot:run &
cd gateway-server && mvn spring-boot:run &
```

**Option 3: Using Makefile**
```bash
make build      # Build all services
make up         # Start with Docker Compose
make down       # Stop services
make logs       # View logs
make status     # Check status
```

### Access Services

- **Eureka Dashboard**: http://localhost:8761
- **API Gateway**: http://localhost:8080
- **Users API**: http://localhost:8080/users
- **Products API**: http://localhost:8080/products
- **Orders API**: http://localhost:8080/orders

## 🔨 Building Native Images

This project supports GraalVM native image compilation for faster startup and lower memory footprint.

### Using GitHub Actions (Recommended)

The project includes automated CI/CD for native image builds:

- **Workflow**: `.github/workflows/native-build.yml`
- **Triggers**: Push to `main` or pull requests
- **Output**: Native images pushed to `ghcr.io`
- **Build time**: ~5-10 minutes per service

### Local Native Build

**Build with Maven native profile:**
```bash
# Build native executable for a specific service
mvn -Pnative native:compile -pl user-service -DskipTests

# Run the native executable
./user-service/target/user-service
```

**Build with Docker (using Containerfile):**
```bash
# Build native image for a specific service
docker build \
  --build-arg SERVICE_NAME=user-service \
  --build-arg PORT=8081 \
  -t user-service:native \
  -f Containerfile .

# Build all services
for service in eureka-server gateway-server user-service product-service order-service; do
  case $service in
    eureka-server) port=8761 ;;
    gateway-server) port=8080 ;;
    user-service) port=8081 ;;
    product-service) port=8082 ;;
    order-service) port=8083 ;;
  esac
  docker build \
    --build-arg SERVICE_NAME=$service \
    --build-arg PORT=$port \
    -t $service:native \
    -f Containerfile .
done
```

### Native Image Benefits

- **Startup Time**: ~0.1s vs ~3-5s (JVM)
- **Memory Usage**: ~50-100MB vs ~200-400MB (JVM)
- **Image Size**: ~100-150MB vs ~300-500MB (JVM)

## 🧪 Testing

### Populate Test Data
```bash
python3 populate_data.py
```

### Run Functional Tests (Postman)
```bash
make postman-test
```

### Run Performance Tests (JMeter)
```bash
make perf-test
```

## ☸️ Kubernetes Deployment

### Deploy to Kubernetes

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy all services
kubectl apply -f k8s/

# Verify deployment
kubectl get all -n microservices

# Check logs
kubectl logs -n microservices -l app=gateway-server -f
```

### Using Native Images from GitHub Container Registry

Update image references in `k8s/*.yaml`:
```yaml
image: ghcr.io/<your-username>/<repo>/user-service:latest
```

### Resource Requirements

**Native Images (Recommended):**
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "300m"
```

**JVM Images:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🔧 Configuration

### Profiles

- **default**: Local development with H2 database
- **prod**: Production configuration (used in native builds)

### Environment Variables

```bash
# Eureka connection
EUREKA_URI=http://eureka-server:8761/eureka/

# Spring profiles
SPRING_PROFILES_ACTIVE=prod
```

## 📊 Monitoring

### Health Checks
```bash
# Check service health
curl http://localhost:8080/actuator/health

# Eureka dashboard
open http://localhost:8761
```

### Kubernetes Monitoring
```bash
# View all services
kubectl get all -n microservices

# Check pod status
kubectl describe pod <pod-name> -n microservices

# View logs
kubectl logs -n microservices -f deployment/gateway-server

# Resource usage
kubectl top pods -n microservices
```

## 🐛 Troubleshooting

### Service Discovery Issues
```bash
# Check Eureka registration
curl http://localhost:8761/eureka/apps

# Verify service can reach Eureka
kubectl exec -it <pod-name> -n microservices -- curl http://eureka-server:8761/actuator/health
```

### Native Image Build Failures

**Issue**: Missing reflection configuration
```bash
# Add to native-image.properties or use @RegisterReflectionForBinding
```

**Issue**: Out of memory during build
```bash
# Increase Docker memory limit to 8GB+
```

### Pod CrashLoopBackOff
```bash
# Check events
kubectl describe pod <pod-name> -n microservices

# View logs
kubectl logs <pod-name> -n microservices --previous

# Common fixes:
# 1. Increase initialDelaySeconds in liveness probe
# 2. Check EUREKA_URI environment variable
# 3. Verify image pull secrets
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🔗 Related Resources

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [GraalVM Native Image](https://www.graalvm.org/latest/reference-manual/native-image/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Built with ❤️ using Spring Boot and GraalVM**
