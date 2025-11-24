# Stage 1: Download dependencies (cached separately)
FROM ghcr.io/graalvm/native-image-community:21 AS deps
WORKDIR /app
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
COPY pom.xml mvnw ./
COPY .mvn .mvn
# Download parent POM and all module POMs
COPY eureka-server/pom.xml eureka-server/
COPY gateway-server/pom.xml gateway-server/
COPY user-service/pom.xml user-service/
COPY product-service/pom.xml product-service/
COPY order-service/pom.xml order-service/
RUN chmod +x mvnw
# Download all dependencies (this layer will be cached)
RUN --mount=type=cache,target=/root/.m2/repository \
    ./mvnw dependency:go-offline -DskipTests || true

# Stage 2: Build native image with cached dependencies
FROM ghcr.io/graalvm/native-image-community:21 AS builder
ARG SERVICE_NAME
ARG PORT
WORKDIR /app
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# Copy Maven dependencies from deps stage
COPY --from=deps /root/.m2 /root/.m2
# Copy source code
COPY . .
RUN chmod +x mvnw
# Build native image (dependencies already cached)
RUN --mount=type=cache,target=/root/.m2/repository \
    ./mvnw -Pnative native:compile -pl ${SERVICE_NAME} -DskipTests

# Stage 3: Runtime image
FROM ubuntu:noble
ARG SERVICE_NAME
ARG PORT
WORKDIR /app
COPY --from=builder /app/${SERVICE_NAME}/target/${SERVICE_NAME} .
EXPOSE ${PORT}
ENV SERVICE_NAME=${SERVICE_NAME}
ENTRYPOINT ["/bin/sh", "-c", "/app/$SERVICE_NAME"]
