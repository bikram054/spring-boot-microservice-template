# Microservices Deployment for Homelab

Run your Java microservices as an application in the Kubernetes cluster.

## 🏗️ Architecture

```
microservices namespace
├── eureka-server (port 8761)
├── gateway-server (port 9090) ← Entry point
├── user-service (port 8081)
├── product-service (port 8082)
└── order-service (port 8083)
```

## 📦 Directory Structure

```
microservices/
├── deployment.yaml          # All microservices manifests
├── service.yaml             # Service definitions
├── config-map.yaml          # Application configuration
├── docker-compose.yaml      # Local development (optional)
└── README.md
```

## 🚀 Deployment Steps

### Step 1: Build Docker Images

**Locally (on your machine):**
```bash
cd /home/samanta/ms

# Build all service images

docker build -t eureka-server:latest ./eureka-server
docker build -t gateway-server:latest ./gateway-server
docker build -t user-service:latest ./user-service
docker build -t product-service:latest ./product-service
docker build -t order-service:latest ./order-service
```

**Or on Raspberry Pi directly (for ARM):**
```bash
# Ensure images are ARM-compatible
# Use buildx for multi-platform builds

```

### Step 2: Push Images to Registry

**Option A: Local Registry (Recommended for Homelab)**
```bash
# Start local registry on Raspberry Pi
docker run -d -p 5000:5000 --restart always --name registry registry:2

# Tag images for local registry

docker tag eureka-server:latest localhost:5000/eureka-server:latest
# ... tag all services

# Push to local registry

docker push localhost:5000/eureka-server:latest
# ... push all services
```

**Option B: Docker Hub**
```bash
# Tag for Docker Hub

docker tag eureka-server:latest <username>/eureka-server:latest
# ... tag all services

# Login and push
docker login

docker push <username>/eureka-server:latest
# ... push all services
```

### Step 3: Create Kubernetes Manifests

Create `homelab/microservices/deployment.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: microservices-config
  namespace: microservices
data:

  
  # Eureka Server
  eureka.instance.hostname: "eureka-server"
  eureka.port: "8761"
  
  # Services
  spring.application.name: "microservices"



---
# Eureka Server
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eureka-server
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: eureka-server
  template:
    metadata:
      labels:
        app: eureka-server
    spec:
      containers:
      - name: eureka-server
        image: localhost:5000/eureka-server:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8761
        env:
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8761
          initialDelaySeconds: 60
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: eureka-server
  namespace: microservices
spec:
  selector:
    app: eureka-server
  ports:
  - port: 8761
    targetPort: 8761
  type: ClusterIP

---
# Gateway Server
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-server
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gateway-server
  template:
    metadata:
      labels:
        app: gateway-server
    spec:
      containers:
      - name: gateway-server
        image: localhost:5000/gateway-server:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 9090
        env:
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 9090
          initialDelaySeconds: 60
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: gateway-server
  namespace: microservices
spec:
  selector:
    app: gateway-server
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP

---
# User Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: localhost:5000/user-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8081
        env:
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "256Mi"
            cpu: "150m"
          limits:
            memory: "512Mi"
            cpu: "400m"

---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: microservices
spec:
  selector:
    app: user-service
  ports:
  - port: 8081
    targetPort: 8081
  type: ClusterIP

---
# Product Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: localhost:5000/product-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8082
        env:
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "256Mi"
            cpu: "150m"
          limits:
            memory: "512Mi"
            cpu: "400m"

---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: microservices
spec:
  selector:
    app: product-service
  ports:
  - port: 8082
    targetPort: 8082
  type: ClusterIP

---
# Order Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: localhost:5000/order-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8083
        env:
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "256Mi"
            cpu: "150m"
          limits:
            memory: "512Mi"
            cpu: "400m"

---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: microservices
spec:
  selector:
    app: order-service
  ports:
  - port: 8083
    targetPort: 8083
  type: ClusterIP
```

### Step 4: Create Ingress

Create `homelab/microservices/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  namespace: microservices
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.yourdomain.com
    - yourdomain.com
    secretName: microservices-tls
  rules:
  - host: api.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gateway-server
            port:
              number: 9090
  - host: yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gateway-server
            port:
              number: 9090
```

### Step 5: Deploy to Kubernetes

```bash
cd /home/samanta/ms/homelab

# Generate certificates
./generate-tls-cert.sh api.yourdomain.com microservices microservices

# Deploy microservices
sudo k0s kubectl apply -f microservices/deployment.yaml
sudo k0s kubectl apply -f microservices/ingress.yaml

# Verify deployment
sudo k0s kubectl get all -n microservices
sudo k0s kubectl logs -n microservices -f deployment/gateway-server
```

### Step 6: Access Services

**Locally:**
```bash
# Set port forwarding
sudo ./setup-ingress-portforward.sh &

# Add to /etc/hosts
echo "127.0.0.1 microservices.local" | sudo tee -a /etc/hosts

# Access
https://microservices.local
```

**From Internet (after domain setup):**
```
https://api.yourdomain.com
https://yourdomain.com

# Access individual services (via gateway)
https://api.yourdomain.com/user-service
https://api.yourdomain.com/product-service
https://api.yourdomain.com/order-service
```

---

## 📊 Monitoring

```bash
# View all microservices
sudo k0s kubectl get all -n microservices

# Check specific service
sudo k0s kubectl describe deployment gateway-server -n microservices

# View logs
sudo k0s kubectl logs -n microservices -f deployment/gateway-server

# Resource usage
sudo k0s kubectl top pods -n microservices

# Service endpoints
sudo k0s kubectl get svc -n microservices -o wide
```

---

## 🔧 Troubleshooting

### Pod not starting?
```bash
# Check events
sudo k0s kubectl describe pod <pod-name> -n microservices

# Check logs
sudo k0s kubectl logs <pod-name> -n microservices
```

### Out of memory?
```bash
# Reduce JAVA_OPTS in deployment
JAVA_OPTS="-Xmx128m -Xms64m"

# Or increase Raspberry Pi swap:
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=2048/g' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### Services not communicating?
```bash
# Test service-to-service communication
sudo k0s kubectl exec -it <pod-name> -n microservices -- bash
curl http://eureka-server:8761/actuator/health
```

---

**Your microservices are now part of your homelab! 🚀**
