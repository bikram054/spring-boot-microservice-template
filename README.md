# Spring Boot Microservices Template

A production-ready microservices architecture built with Spring Boot 3.5, Spring Cloud 2025.0.0, and GraalVM native image support.

## 🏗️ Architecture

This project implements a microservices architecture with API gateway and multiple business services:

```
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway (8080)                      │
│                     traefik                                 │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├──────────────┬──────────────┬─────────────┐
               │              │              │             │
       ┌───────▼────────┐ ┌──▼───────────┐ ┌▼──────────┐ ┌▼────────────┐
       │ user-service   │ │product-service│ │order-service│ │   ...more   │
       │   (8081)       │ │   (8082)      │ │   (8083)   │ │  services   │
       └────────────────┘ └───────────────┘ └────────────┘ └─────────────┘
```

### Services

- **gateway-server** (8080): API Gateway with routing and load balancing
- **user-service** (8081): User management service
- **product-service** (8082): Product catalog service
- **order-service** (8083): Order processing service with circuit breaker

> [!NOTE]
> This template does not include a config-server. Services use environment variables and embedded configuration files for simplicity.

## 📦 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── native-build.yml       # CI/CD for native image builds
├── gateway-server/                # API Gateway
├── user-service/                  # User management
├── product-service/               # Product catalog
├── order-service/                 # Order processing
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml
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

# Start all services
cd user-service && mvn spring-boot:run &
cd product-service && mvn spring-boot:run &
cd order-service && mvn spring-boot:run &
cd gateway-server && mvn spring-boot:run &
```

**Option 3: Using Makefile**
```bash
make build          # Build all services (Maven)
make deploy         # Deploy to k0s (local images)
make deploy-remote  # Deploy to k0s (remote images from ghcr.io)
make pull-images    # Pre-pull remote images
make update-images  # Update running deployments
make undeploy       # Remove from k0s
make logs           # View logs (default: gateway-server)
make status         # Check pod status
make k8s-status     # Detailed k8s status
```

### Access Services

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

### Deploy Using Prebuilt Images (Recommended)

The easiest way to deploy is using prebuilt native images from GitHub Container Registry:

```bash
# Deploy using remote images from ghcr.io/bikram054/ms
make deploy-remote
```

This will:
- Pull native images from `ghcr.io/bikram054/ms`
- Deploy all microservices to k0s
- Wait for all pods to be ready
- Display service endpoints

**Available commands:**
```bash
make deploy-remote    # Deploy using remote images
make pull-images      # Pre-pull all images to k0s nodes
make update-images    # Update deployments with latest images
make status           # Check pod status
make logs             # View logs (default: gateway-server)
make undeploy         # Remove all services
```

### Deploy Using Local Images

If you've built images locally:

```bash
# Deploy to k0s
make deploy
```

**Manual deployment:**
```bash
# Create namespace and deploy
sudo k0s kubectl apply -f k8s/namespace.yaml
sudo k0s kubectl apply -f k8s/

# Verify deployment
sudo k0s kubectl logs -n ms -l app=gateway-server -f
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
# Spring profiles
SPRING_PROFILES_ACTIVE=prod
```

## 📊 Monitoring

### Health Checks
```bash
# Check service health
curl http://localhost:8080/actuator/health
```

### Kubernetes Monitoring (k0s)
```bash
# Quick status
make status

# Detailed status
make k8s-status

# View all services
sudo k0s kubectl get all -n ms

# Check pod status
sudo k0s kubectl describe pod <pod-name> -n ms

# View logs
make logs SERVICE=gateway-server

# Resource usage
sudo k0s kubectl get pods -n ms
```

## 🐛 Troubleshooting

### Image Pull Errors

**Issue**: `ImagePullBackOff` or `ErrImagePull`
```bash
# Check pod events
sudo k0s kubectl describe pod <pod-name> -n ms

# Verify image exists
docker pull ghcr.io/bikram054/ms/gateway-server:latest

# For private registries, ensure image pull secret is created
./setup-image-pull-secret.sh
```

**Issue**: Images not updating
```bash
# Force pull latest images
make update-images

# Or manually restart deployments
sudo k0s kubectl rollout restart deployment --all -n ms
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
sudo k0s kubectl describe pod <pod-name> -n ms

# View logs
sudo k0s kubectl logs <pod-name> -n ms --previous

# Common fixes:
# 1. Increase initialDelaySeconds in liveness probe
# 2. Verify image pull secrets (if using private registry)
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
