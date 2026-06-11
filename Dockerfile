FROM maven:3.9.9-eclipse-temurin-8 AS builder

WORKDIR /app

COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw -B dependency:go-offline

COPY src src
RUN ./mvnw -B clean package -DskipTests

FROM eclipse-temurin:8-jre

WORKDIR /app

ENV TZ=Asia/Shanghai \
    JAVA_OPTS=""

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
