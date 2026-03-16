# Simple Dockerfile — JAR is pre-built by Jenkins Maven, just package it
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy the pre-built JAR (built by Maven in Jenkins pipeline)
COPY Workforce-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-Xms256m", "-Xmx512m", "-jar", "app.jar"]
