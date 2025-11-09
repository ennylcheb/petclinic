# =========================
# Build Stage
# =========================
FROM eclipse-temurin:25-jdk-alpine AS builder

# Set work directory
WORKDIR /app

# Copy Maven wrapper and project files
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
COPY src ./src

# Ensure mvnw has execute permission
RUN chmod +x mvnw

# Build the project (skip tests for faster build)
RUN ./mvnw clean package

# =========================
# Runtime Stage
# =========================
FROM eclipse-temurin:25-jdk-alpine

WORKDIR /app

# Copy the packaged jar from the builder stage
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

