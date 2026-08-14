# xxgkami 安全增强版 - 部署实战指南

## 📋 目录

1. [环境要求](#环境要求)
2. [快速部署](#快速部署)
3. [手动部署](#手动部署)
4. [生产环境配置](#生产环境配置)
5. [性能调优](#性能调优)
6. [监控与告警](#监控与告警)
7. [故障排查](#故障排查)
8. [安全加固](#安全加固)

---

## 环境要求

### 最低配置（<1000 用户）

| 组件 | 配置 |
|------|------|
| CPU | 2 核 |
| 内存 | 4GB |
| 磁盘 | 50GB SSD |
| 带宽 | 5Mbps |

### 推荐配置（1000-10000 用户）

| 组件 | 配置 |
|------|------|
| CPU | 4 核 |
| 内存 | 8GB |
| 磁盘 | 100GB SSD |
| 带宽 | 20Mbps |

### 软件要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Debian 10+
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Git**: 2.0+

---

## 快速部署

### 1. 克隆项目

```bash
cd /opt
git clone https://github.com/yourusername/xxgkami-enhanced.git
cd xxgkami-enhanced
```

### 2. 配置环境变量

```bash
cp .env.example .env
vim .env
```

**必须修改的配置**:

```bash
# MySQL 配置
MYSQL_ROOT_PASSWORD=your_super_strong_password_here
MYSQL_PASSWORD=your_app_db_password_here

# Redis 配置
REDIS_PASSWORD=your_redis_password_here

# JWT 配置（生成 32 字节随机字符串）
JWT_SECRET=$(openssl rand -hex 32)

# 加密主密钥（生成 32 字节随机字符串）
ENCRYPTION_KEY=$(openssl rand -hex 32)

# 域名配置
APP_DOMAIN=your-domain.com

# CORS 配置
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
```

### 3. 一键部署

```bash
chmod +x install-enhanced.sh
sudo ./install-enhanced.sh
```

脚本会自动：
- ✅ 检测并安装 Docker
- ✅ 生成安全密钥
- ✅ 创建自签名 SSL 证书（测试用）
- ✅ 启动所有服务
- ✅ 等待服务就绪
- ✅ 导入数据库表结构

### 4. 验证部署

```bash
# 检查容器状态
docker compose ps

# 检查后端健康
curl http://localhost:8080/actuator/health

# 检查前端
curl http://localhost
```

---

## 手动部署

### 步骤 1: 准备数据库和 Redis

```bash
# 启动 MySQL 和 Redis
docker compose up -d mysql redis

# 等待 MySQL 就绪
docker compose exec mysql mysqladmin ping -h localhost -p

# 导入数据库表
docker compose exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" < databaes/schema.sql
docker compose exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" < databaes/security_tables.sql
```

### 步骤 2: 构建后端

```bash
cd backend

# 使用 Maven 构建
mvn clean package -DskipTests

# 构建 Docker 镜像
docker build -t xxgkami-backend:latest .

cd ..
```

### 步骤 3: 构建前端

```bash
# 构建前端镜像
docker build -f Dockerfile.frontend -t xxgkami-frontend:latest .
```

### 步骤 4: 启动服务

```bash
# 启动后端
docker compose up -d backend

# 等待后端就绪
sleep 10

# 启动前端
docker compose up -d frontend
```

### 步骤 5: 配置 SSL（生产环境）

```bash
# 安装 Certbot
sudo apt-get install certbot

# 获取 Let's Encrypt 证书
sudo certbot certonly --standalone -d your-domain.com

# 复制证书
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem

# 重启 Nginx
docker compose restart frontend
```

---

## 生产环境配置

### 1. SSL/TLS 优化

编辑 `deployment/nginx-enhanced.conf`:

```nginx
# 强制 HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL 证书
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # SSL 优化
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
}
```

### 2. 数据库连接池优化

编辑 `application-enhanced.properties`:

```properties
# HikariCP 连接池
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
spring.datasource.hikari.validation-timeout=5000
```

### 3. JVM 参数优化

编辑 `backend/Dockerfile`:

```dockerfile
ENV JAVA_OPTS="-Xms1g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError"
```

### 4. Redis 持久化配置

编辑 `docker-compose.yml`:

```yaml
redis:
  command: >
    redis-server 
    --requirepass ${REDIS_PASSWORD}
    --appendonly yes
    --appendfsync everysec
    --save 900 1
    --save 300 10
    --save 60 10000
```

---

## 性能调优

### 1. MySQL 索引优化

```sql
-- 检查慢查询
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;

-- 分析执行计划
EXPLAIN SELECT * FROM api_keys WHERE user_id = 1;

-- 添加索引
CREATE INDEX idx_user_id ON api_keys(user_id);
CREATE INDEX idx_status_create_time ON orders(status, create_time);
```

### 2. Redis 缓存策略

```java
// 热点数据缓存
@Cacheable(value = "users", key = "#userId", unless = "#result == null")
public User getUserById(Long userId) {
    return userRepository.findById(userId).orElse(null);
}

// 设置过期时间
@CacheEvict(value = "users", allEntries = true)
@Scheduled(fixedDelay = 3600000) // 1小时清理一次
public void clearCache() {
    // 缓存清理逻辑
}
```

### 3. Nginx 缓存配置

```nginx
# 静态资源缓存
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
    expires 7d;
    add_header Cache-Control "public, immutable";
}

# API 响应缓存（谨慎使用）
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=100m;

location /api/public/ {
    proxy_cache api_cache;
    proxy_cache_valid 200 5m;
    proxy_cache_key $request_uri;
}
```

### 4. 数据库读写分离

```yaml
# docker-compose.yml
services:
  mysql-master:
    image: mysql:8.0
    environment:
      - MYSQL_REPLICATION_MODE=master
      
  mysql-slave:
    image: mysql:8.0
    environment:
      - MYSQL_REPLICATION_MODE=slave
      - MYSQL_MASTER_HOST=mysql-master
```

```properties
# application.properties
spring.datasource.master.url=jdbc:mysql://mysql-master:3306/kami
spring.datasource.slave.url=jdbc:mysql://mysql-slave:3306/kami
```

---

## 监控与告警

### 1. Spring Boot Actuator

访问监控端点：

```bash
# 健康检查
curl http://localhost:8080/actuator/health

# 指标监控
curl http://localhost:8080/actuator/metrics

# JVM 信息
curl http://localhost:8080/actuator/metrics/jvm.memory.used
```

### 2. Prometheus + Grafana

```yaml
# docker-compose.yml 新增服务
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./deployment/prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana:latest
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

**Prometheus 配置** (`deployment/prometheus.yml`):

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'spring-boot'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['backend:8080']
```

### 3. 日志聚合（ELK Stack）

```yaml
# docker-compose.yml
elasticsearch:
  image: elasticsearch:8.10.0
  environment:
    - discovery.type=single-node
  ports:
    - "9200:9200"

logstash:
  image: logstash:8.10.0
  volumes:
    - ./deployment/logstash.conf:/usr/share/logstash/pipeline/logstash.conf

kibana:
  image: kibana:8.10.0
  ports:
    - "5601:5601"
```

### 4. 告警配置

```bash
# 创建告警脚本
cat > /opt/xxgkami-enhanced/scripts/alert.sh << 'EOF'
#!/bin/bash

WEBHOOK_URL="https://your-webhook-url"

# 检查服务状态
if ! docker compose ps | grep -q "Up"; then
    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"🔴 xxgkami 服务异常: $(docker compose ps)\"}"
fi

# 检查磁盘空间
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"⚠️ 磁盘空间不足: ${DISK_USAGE}%\"}"
fi
EOF

chmod +x /opt/xxgkami-enhanced/scripts/alert.sh

# 添加定时任务
crontab -e
*/5 * * * * /opt/xxgkami-enhanced/scripts/alert.sh
```

---

## 故障排查

### 常见问题

#### 1. 后端无法启动

**症状**: `docker compose ps` 显示 backend 状态为 `Restarting`

**排查**:
```bash
# 查看日志
docker compose logs backend

# 常见原因:
# - MySQL 未就绪 → 等待 30 秒后重试
# - Redis 连接失败 → 检查 REDIS_PASSWORD
# - 端口被占用 → netstat -tuln | grep 8080
```

**解决**:
```bash
# 重新启动
docker compose restart backend

# 如果数据库连接失败
docker compose exec mysql mysql -u root -p
# 手动创建用户和数据库
```

#### 2. 限流不生效

**症状**: 可以无限次请求登录接口

**排查**:
```bash
# 检查 Redis 连接
docker compose exec backend sh -c "redis-cli -h redis -a \$REDIS_PASSWORD ping"

# 检查限流键
docker compose exec redis redis-cli -a "$REDIS_PASSWORD" KEYS "ratelimit:*"
```

**解决**:
```bash
# 确认 Controller 添加了注解
@RateLimit(key = "login", maxRequests = 5, windowSeconds = 60)

# 确认 RateLimitAspect 已注册
@Component
@Aspect
public class RateLimitAspect { ... }
```

#### 3. 审计日志未记录

**症状**: `audit_logs` 表为空

**排查**:
```bash
# 检查表是否存在
docker compose exec mysql mysql -u kami -p -e "USE kami; SHOW TABLES LIKE 'audit_logs';"

# 检查 AOP 是否生效
docker compose logs backend | grep "AuditLogAspect"
```

**解决**:
```bash
# 确认添加了 AOP 依赖
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>

# 确认 Controller 添加了注解
@AuditLog(action = "USER_LOGIN", resource = "AUTH")
```

#### 4. SSL 证书错误

**症状**: 浏览器显示 "您的连接不是私密连接"

**解决**:
```bash
# 生产环境使用 Let's Encrypt
sudo certbot certonly --standalone -d your-domain.com

# 复制证书
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem

# 设置自动续期
sudo crontab -e
0 0 1 * * certbot renew --quiet && docker compose restart frontend
```

#### 5. 数据库备份失败

**症状**: `backup_history.log` 显示 FAILED

**排查**:
```bash
# 查看备份日志
cat /app/backups/backup_history.log

# 手动执行备份
docker compose exec backend sh /app/scripts/backup.sh
```

**解决**:
```bash
# 检查磁盘空间
df -h

# 检查 MySQL 连接
docker compose exec mysql mysqladmin ping -u kami -p
```

---

## 安全加固

### 1. 最小权限原则

```sql
-- 创建只读用户（用于备份和监控）
CREATE USER 'kami_readonly'@'%' IDENTIFIED BY 'readonly_password';
GRANT SELECT ON kami.* TO 'kami_readonly'@'%';
FLUSH PRIVILEGES;
```

### 2. 防火墙配置

```bash
# UFW（Ubuntu）
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 3306/tcp  # MySQL 不对外开放
sudo ufw deny 6379/tcp  # Redis 不对外开放
sudo ufw enable

# Firewalld（CentOS）
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 3. Fail2Ban 防暴力破解

```bash
# 安装 Fail2Ban
sudo apt-get install fail2ban

# 配置规则
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https"]
logpath = /var/log/nginx/error.log
findtime = 600
bantime = 7200
maxretry = 10
EOF

sudo systemctl restart fail2ban
```

### 4. 定期安全审计

```bash
# 创建审计脚本
cat > /opt/xxgkami-enhanced/scripts/security_audit.sh << 'EOF'
#!/bin/bash

echo "=== 安全审计报告 $(date) ==="

# 检查失败登录
echo "## 失败登录（最近 24 小时）"
docker compose exec mysql mysql -u kami -p -e "
USE kami;
SELECT username, ip, COUNT(*) as attempts 
FROM login_logs 
WHERE success = 0 AND login_time > DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY username, ip
HAVING attempts > 5;
"

# 检查 IP 黑名单
echo "## IP 黑名单"
docker compose exec mysql mysql -u kami -p -e "
USE kami;
SELECT ip, reason, expire_time FROM ip_blacklist WHERE expire_time IS NULL OR expire_time > NOW();
"

# 检查异常审计日志
echo "## 异常操作（响应码 >= 400）"
docker compose exec mysql mysql -u kami -p -e "
USE kami;
SELECT username, action, ip, response_status, create_time 
FROM audit_logs 
WHERE response_status >= 400 AND create_time > DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY create_time DESC
LIMIT 20;
"
EOF

chmod +x /opt/xxgkami-enhanced/scripts/security_audit.sh

# 定时执行（每天 6 AM）
crontab -e
0 6 * * * /opt/xxgkami-enhanced/scripts/security_audit.sh > /var/log/security_audit.log
```

### 5. 密钥轮换

```bash
# 每季度轮换 JWT 密钥
NEW_JWT_SECRET=$(openssl rand -hex 32)
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$NEW_JWT_SECRET/" .env

# 重启后端
docker compose restart backend

# 通知所有用户重新登录
```

---

## 附录

### A. 完整的 .env 配置示例

```bash
# MySQL 配置
MYSQL_ROOT_PASSWORD=SuperStrongRootPassword123!
MYSQL_DATABASE=kami
MYSQL_USER=kami
MYSQL_PASSWORD=KamiAppPassword456!

# Redis 配置
REDIS_PASSWORD=RedisSecurePassword789!

# 后端配置
BACKEND_PORT=8080

# 前端配置
FRONTEND_PORT=80
FRONTEND_SSL_PORT=443

# JWT 配置
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
JWT_ACCESS_TOKEN_EXPIRATION=3600
JWT_REFRESH_TOKEN_EXPIRATION=604800

# 加密配置
ENCRYPTION_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# 应用配置
APP_DOMAIN=example.com
APP_NAME=xxgkami
CORS_ALLOWED_ORIGINS=https://example.com,https://www.example.com

# 备份配置
BACKUP_RETENTION_DAYS=30
BACKUP_OSS_ENABLED=false
BACKUP_OSS_ENDPOINT=
BACKUP_OSS_ACCESS_KEY=
BACKUP_OSS_SECRET_KEY=
BACKUP_OSS_BUCKET=

# 邮件配置（可选）
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@example.com

# 告警配置（可选）
ALERT_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### B. 性能基准测试

```bash
# 安装 Apache Bench
sudo apt-get install apache2-utils

# 登录接口压测
ab -n 1000 -c 10 -p login.json -T application/json http://localhost:8080/api/auth/login

# API 接口压测
ab -n 10000 -c 100 -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/api/cards/verify

# 生成测试数据
cat > login.json << 'EOF'
{"username":"test","password":"Test@123456"}
EOF
```

### C. 数据库备份和恢复流程

```bash
# 手动备份
docker compose exec backend sh /app/scripts/backup.sh

# 查看备份列表
docker compose exec backend sh /app/scripts/restore.sh -l

# 恢复备份
docker compose exec backend sh /app/scripts/restore.sh -f kami_backup_20261215_120000.sql.gz
```

---

**文档版本**: v1.0.0  
**最后更新**: 2026-08-15  
**维护者**: Security Enhancement Team
