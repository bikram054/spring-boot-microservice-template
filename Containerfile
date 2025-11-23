FROM ghcr.io/graalvm/native-image-community:21 AS builder
ARG SERVICE_NAME
ARG PORT
WORKDIR /app
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
COPY . .
RUN chmod +x mvnw
RUN --mount=type=cache,target=/root/.m2/repository \
    ./mvnw -Pnative native:compile -pl ${SERVICE_NAME} -DskipTests

FROM ubuntu:noble
ARG SERVICE_NAME
ARG PORT
WORKDIR /app
COPY --from=builder /app/${SERVICE_NAME}/target/${SERVICE_NAME} .
EXPOSE ${PORT}
ENTRYPOINT ["/bin/sh", "-c", "/app/${SERVICE_NAME}"]
