# 多阶段构建 - 后端
FROM maven:3.8.5-openjdk-17 AS backend-build

WORKDIR /app

# 复制 Maven 配置
COPY backend/pom.xml .
COPY backend/mvnw .
COPY backend/mvnw.cmd .
COPY backend/.mvn .mvn

# 下载依赖（利用 Docker 缓存）
RUN mvn dependency:go-offline -B

# 复制源码
COPY backend/src ./src

# 构建应用
RUN mvn clean package -DskipTests

# 运行时镜像 - 使用 Eclipse Temurin
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 安装必要工具（Alpine 使用 apk）
RUN apk add --no-cache curl

# 复制构建产物
COPY --from=backend-build /app/target/*.jar app.jar

# 创建非 root 用户（Alpine 使用 adduser）
RUN adduser -D -u 1001 appuser && chown -R appuser:appuser /app
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# JVM 参数优化
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
