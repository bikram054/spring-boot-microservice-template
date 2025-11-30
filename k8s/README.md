# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying microservices with nginx-ingress controller.

## Prerequisites

Make sure you have a Kubernetes cluster running and `kubectl` configured.

## Deployment Order

Apply the manifests in the following order:

```bash
# 1. Create namespace
kubectl apply -f 00-namespace.yaml

# 2. Create RBAC for microservices
kubectl apply -f 01-microservices-rbac.yaml

# 3. Create RBAC for nginx-ingress
kubectl apply -f 01-nginx-ingress-rbac.yaml

# 4. Deploy nginx-ingress controller
kubectl apply -f 02-nginx-ingress.yaml

# 5. Deploy microservices
kubectl apply -f 04-user-service.yaml
kubectl apply -f 04-product-service.yaml
kubectl apply -f 04-order-service.yaml

# 6. Create ingress routes
kubectl apply -f 05-ingress.yaml
```

## Quick Deploy (All at once)

```bash
kubectl apply -f k8s/
```

## Verify Deployment

```bash
# Check all resources in the ms namespace
kubectl get all -n ms

# Check ingress
kubectl get ingress -n ms

# Get the LoadBalancer IP/hostname
kubectl get svc nginx-ingress-controller -n ms
```

## Access Services

Once deployed, you can access your services through the nginx-ingress LoadBalancer:

- User Service: `http://<LOADBALANCER-IP>/users`
- Product Service: `http://<LOADBALANCER-IP>/products`
- Order Service: `http://<LOADBALANCER-IP>/orders`

## Cleanup

```bash
kubectl delete namespace ms
kubectl delete clusterrole nginx-ingress-controller
kubectl delete clusterrolebinding nginx-ingress-controller
```

## Changes from Traefik

This configuration has been converted from Traefik to use standard Kubernetes Ingress resources with nginx-ingress controller:

- Removed Traefik CRD dependencies (Middleware, IngressRoute)
- Using standard `networking.k8s.io/v1` Ingress
- Path rewriting handled by nginx annotations instead of Traefik middlewares
- More portable across different Kubernetes environments
