FROM --platform=$BUILDPLATFORM maven:3.8.3-openjdk-17-slim AS build

WORKDIR /app

COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline

COPY src src

RUN --mount=type=cache,target=/root/.m2 mvn package -Dquarkus.package.type=uber-jar -Dquarkus.profile=local

## Stage 2 : create the docker final image
FROM eclipse-temurin:17
WORKDIR /work/
COPY --from=build /app/target/*-runner.jar /work/application
COPY docker-entrypoint.sh /usr/local/bin/order-api-entrypoint
RUN chmod 755 /usr/local/bin/order-api-entrypoint

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/order-api-entrypoint"]