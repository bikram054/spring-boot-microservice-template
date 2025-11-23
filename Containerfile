ARG SERVICE_NAME
ARG PORT

FROM ghcr.io/graalvm/native-image-community:21 AS builder
WORKDIR /app
COPY . .
RUN chmod +x mvnw
RUN ./mvnw -Pnative native:compile -pl ${SERVICE_NAME} -DskipTests

FROM ubuntu:noble
ARG SERVICE_NAME
ARG PORT
WORKDIR /app
COPY --from=builder /app/${SERVICE_NAME}/target/${SERVICE_NAME} .
EXPOSE ${PORT}
ENTRYPOINT ["/bin/sh", "-c", "/app/${SERVICE_NAME}"]
