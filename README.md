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
- **Buildah** (for native image builds)
- **k0s** (for Kubernetes deployment)
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
make build           # Build all services (Maven)
make build-native    # Build single native image (requires SERVICE=name)
make build-native-all # Build all native images
make deploy          # Deploy to k0s
make undeploy        # Remove from k0s
make logs            # View logs (default: gateway-server)
make status          # Check pod status
make k8s-status      # Detailed k8s status
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

**Build with Buildah (using Containerfile):**
```bash
# Build native image for a specific service
make build-native SERVICE=user-service

# Or manually with buildah
buildah bud \
  --build-arg SERVICE_NAME=user-service \
  --build-arg PORT=8081 \
  -t user-service:native \
  -f Containerfile .

# Build all services
make build-native-all

# Or manually
for service in eureka-server gateway-server user-service product-service order-service; do
  case $service in
    eureka-server) port=8761 ;;
    gateway-server) port=8080 ;;
    user-service) port=8081 ;;
    product-service) port=8082 ;;
    order-service) port=8083 ;;
  esac
  buildah bud \
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

## ⚡ Build Performance Improvements

- **Parallel Maven Builds**: Uses Maven's parallel build mode (`-T 1C`) for faster multi-service compilation
- **CI Pipeline Caching**: GitHub Actions caches Maven dependencies and Docker layers for faster builds
- **Buildah Support**: Rootless container builds with efficient layer caching
- **Incremental Builds**: Only rebuilds changed services in multi-module setup

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

## ☸️ Kubernetes Deployment (k0s)

### Deploy to k0s

**Using Makefile (Recommended):**
```bash
# Deploy all services
make deploy

# Check status
make status
make k8s-status

# View logs
make logs                      # gateway-server (default)
make logs SERVICE=user-service # specific service

# Remove deployment
make undeploy

# Complete cleanup
make clean
```

**Manual deployment:**
```bash
# Create namespace and deploy
sudo k0s kubectl apply -f k8s/namespace.yaml
sudo k0s kubectl apply -f k8s/

# Verify deployment
sudo k0s kubectl get all -n microservices

# Check logs
sudo k0s kubectl logs -n microservices -l app=gateway-server -f
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

### Kubernetes Monitoring (k0s)
```bash
# Quick status
make status

# Detailed status
make k8s-status

# View all services
sudo k0s kubectl get all -n microservices

# Check pod status
sudo k0s kubectl describe pod <pod-name> -n microservices

# View logs
make logs SERVICE=gateway-server

# Resource usage
sudo k0s kubectl top pods -n microservices
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
