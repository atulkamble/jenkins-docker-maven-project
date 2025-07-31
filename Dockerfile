FROM maven:3.8.5-openjdk-11 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package

FROM openjdk:11
WORKDIR /app
COPY --from=builder /app/target/jenkins-docker-maven-1.0-SNAPSHOT.jar app.jar
CMD ["java", "-jar", "app.jar"]
