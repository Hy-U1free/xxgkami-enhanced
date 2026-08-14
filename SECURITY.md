# 安全配置指南

本文档详细说明 xxgkami 安全增强版的安全特性和配置方法。

---

## 🔐 密码学增强

### 1. Argon2id 密码哈希

**为什么使用 Argon2id？**

- **抗 GPU 破解**: 内存密集型算法，GPU 优势降低
- **抗 ASIC 破解**: 比 BCrypt 更强的硬件抗性
- **PHC 获奖算法**: 2015 年密码哈希竞赛冠军

**配置参数** (`PasswordEncoder.java`):

```java
Argon2Parameters params = new Argon2Parameters.Builder(Argon2Parameters.ARGON2_id)
    .withVersion(Argon2Parameters.ARGON2_VERSION_13)
    .withIterations(3)        // 迭代次数
    .withMemoryAsKB(65536)    // 内存使用 64MB
    .withParallelism(4)       // 并行度
    .withSalt(salt)
    .build();
```

**调优建议**:
- **开发环境**: iterations=2, memory=32MB (快速测试)
- **生产环境**: iterations=3, memory=64MB (推荐)
- **高安全**: iterations=4, memory=128MB (银行级)

**性能测试**:
```bash
# 测试哈希速度
curl -X POST http://localhost:8080/api/test/hash-benchmark
```

---

### 2. AES-256-GCM 数据加密

**用途**: 加密存储 API 密钥、WebHook URL 等敏感数据

**特性**:
- **认证加密**: GCM 模式提供加密 + 完整性验证
- **随机 IV**: 每次加密使用不同的初始化向量
- **密钥派生**: 使用 PBKDF2 从主密钥派生加密子密钥

**配置** (`application-enhanced.properties`):

```properties
# AES 主密钥（必须修改！）
security.encryption.master-key=CHANGE_THIS_TO_A_SECURE_RANDOM_AES_256_KEY
```

**生成安全密钥**:

```bash
# 生成 256 位随机密钥（Base64 编码）
openssl rand -base64 32
```

**密钥轮换**:

```java
// 1. 生成新密钥
String newKey = Base64.getEncoder().encodeToString(new byte[32]);

// 2. 重新加密所有数据
UPDATE api_keys SET api_key = ENCRYPT(DECRYPT(api_key, old_key), new_key);

// 3. 更新配置
security.encryption.master-key=NEW_KEY

// 4. 重启服务
```

---

### 3. HMAC-SHA256 签名

**用途**: 防止卡密篡改和重放攻击

**工作流程**:

```
1. 生成卡密
   key = random_string()
   signature = HMAC-SHA256(key + expire_time + type, secret)
   stored_key = key + "|" + signature

2. 验证卡密
   [key, signature] = stored_key.split("|")
   expected = HMAC-SHA256(key + expire_time + type, secret)
   if signature != expected:
       reject("卡密已被篡改")
```

---

## 🚦 访问控制

### 1. Redis 分布式限流

**限流策略** (`application-enhanced.properties`):

```properties
# 登录接口：5 次/分钟
ratelimit.login.max-requests=5
ratelimit.login.window-seconds=60

# 普通 API：100 次/分钟
ratelimit.api.max-requests=100
ratelimit.api.window-seconds=60

# 管理接口：60 次/分钟
ratelimit.admin.max-requests=60
ratelimit.admin.window-seconds=60
```

**使用方法**:

```java
@RestController
public class AuthController {

    @PostMapping("/login")
    @RateLimit(key = "login", maxRequests = 5, windowSeconds = 60)
    public Result login(@RequestBody LoginRequest req) {
        // ...
    }
}
```

**自定义限流规则**:

```java
// 按 IP 限流
@RateLimit(key = "api", maxRequests = 100, windowSeconds = 60, keyType = KeyType.IP)

// 按用户 ID 限流
@RateLimit(key = "api", maxRequests = 1000, windowSeconds = 60, keyType = KeyType.USER)

// 按 API Key 限流
@RateLimit(key = "api", maxRequests = 500, windowSeconds = 60, keyType = KeyType.API_KEY)
```

---

### 2. IP 黑白名单

**黑名单管理**:

```sql
-- 添加黑名单（永久封禁）
INSERT INTO ip_blacklist (ip, reason) VALUES ('192.168.1.100', '恶意攻击');

-- 添加黑名单（临时封禁 24 小时）
INSERT INTO ip_blacklist (ip, reason, expire_time) 
VALUES ('192.168.1.101', '暴力破解', DATE_ADD(NOW(), INTERVAL 24 HOUR));

-- 查看黑名单
SELECT * FROM ip_blacklist WHERE expire_time IS NULL OR expire_time > NOW();

-- 解封
DELETE FROM ip_blacklist WHERE ip = '192.168.1.100';
```

**白名单管理**:

```sql
-- 添加白名单（单个 IP）
INSERT INTO ip_whitelist (ip, description) VALUES ('10.0.0.1', '管理员');

-- 添加白名单（CIDR）
INSERT INTO ip_whitelist (ip, description) VALUES ('10.0.0.0/24', '内网');

-- 查看白名单
SELECT * FROM ip_whitelist;
```

**API 接口**:

```bash
# 添加黑名单
curl -X POST http://localhost:8080/api/admin/blacklist \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"ip": "192.168.1.100", "reason": "恶意攻击"}'

# 移除黑名单
curl -X DELETE http://localhost:8080/api/admin/blacklist/192.168.1.100 \
  -H "Authorization: Bearer $TOKEN"
```

---

### 3. JWT 双 Token 机制

**Token 类型**:

1. **Access Token**: 短期有效（1 小时），用于 API 调用
2. **Refresh Token**: 长期有效（7 天），用于刷新 Access Token

**配置** (`application-enhanced.properties`):

```properties
# Access Token 有效期（毫秒）
jwt.access-token-expiration=3600000   # 1 小时

# Refresh Token 有效期（毫秒）
jwt.refresh-token-expiration=604800000  # 7 天

# JWT 签名密钥（必须修改！）
jwt.secret=CHANGE_THIS_TO_A_SECURE_RANDOM_256_BIT_KEY
```

**使用流程**:

```bash
# 1. 登录获取双 Token
curl -X POST http://localhost:8080/api/auth/login \
  -d '{"username": "admin", "password": "password"}'

# 响应:
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": 3600
}

# 2. 使用 Access Token 调用 API
curl -X GET http://localhost:8080/api/user/profile \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 3. Access Token 过期后，使用 Refresh Token 刷新
curl -X POST http://localhost:8080/api/auth/refresh \
  -d '{"refreshToken": "$REFRESH_TOKEN"}'

# 4. 登出（使 Refresh Token 失效）
curl -X POST http://localhost:8080/api/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

---

## 🛡️ 防护措施

### 1. SQL 注入防护

**多层防护**:

1. **参数化查询** (首要防护):
```java
// ✅ 安全
String sql = "SELECT * FROM users WHERE username = ?";
jdbcTemplate.query(sql, new Object[]{username}, rowMapper);

// ❌ 危险
String sql = "SELECT * FROM users WHERE username = '" + username + "'";
```

2. **输入过滤** (`SqlInjectionFilter.java`):
- 检测常见 SQL 注入模式
- 自动清理危险字符
- 记录可疑请求

3. **数据库权限最小化**:
```sql
-- 应用账户只授予必要权限
GRANT SELECT, INSERT, UPDATE ON kami.* TO 'kami'@'localhost';
REVOKE DROP, CREATE, ALTER ON kami.* FROM 'kami'@'localhost';
```

---

### 2. XSS 防护

**多层防护**:

1. **输入验证** (`XssFilter.java`):
- 检测脚本标签
- 检测事件处理器
- HTML 实体编码

2. **输出编码**:
```java
// 前端渲染时自动转义
<div>{{ userInput }}</div>  // Vue 自动转义
```

3. **Content Security Policy**:
```nginx
# nginx-enhanced.conf
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";
```

---

### 3. CSRF 防护

**双 Token 验证**:

1. **Cookie Token**: HttpOnly, Secure, SameSite
2. **Header Token**: 每次请求携带

```javascript
// 前端配置
axios.defaults.headers.common['X-CSRF-Token'] = getCsrfToken();
```

---

## 📊 审计与监控

### 1. 审计日志

**自动记录的操作**:

```java
@PostMapping("/admin/user/create")
@AuditLog(action = "CREATE_USER", resource = "USER", logParams = true)
public Result createUser(@RequestBody CreateUserRequest req) {
    // 自动记录：用户名、操作、IP、时间、参数（脱敏）
}
```

**日志查询**:

```sql
-- 查看最近 100 条操作
SELECT * FROM audit_logs ORDER BY create_time DESC LIMIT 100;

-- 查看特定用户的操作
SELECT * FROM audit_logs WHERE username = 'admin';

-- 查看失败的操作
SELECT * FROM audit_logs WHERE response_status >= 400;

-- 按操作类型统计
SELECT action, COUNT(*) as count FROM audit_logs 
GROUP BY action ORDER BY count DESC;
```

**敏感数据脱敏**:

```java
// 自动脱敏以下字段:
- password / oldPassword / newPassword
- apiKey / api_key
- token / accessToken / refreshToken
```

---

### 2. 登录日志

**记录内容**:
- 登录时间
- 用户名
- IP 地址
- User-Agent
- 成功/失败
- 失败原因

**异常检测**:

```sql
-- 检测暴力破解（5 分钟内失败 10 次）
SELECT username, ip, COUNT(*) as fail_count
FROM login_logs
WHERE success = 0 AND login_time > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
GROUP BY username, ip
HAVING fail_count >= 10;

-- 检测异常登录（不同地区）
SELECT username, ip, user_agent, login_time
FROM login_logs
WHERE username = 'admin' AND success = 1
ORDER BY login_time DESC LIMIT 10;
```

---

## 🔧 高级配置

### 1. 数据库连接池优化

```properties
# HikariCP 配置
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.maximum-pool-size=50
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
```

### 2. Redis 优化

```properties
# Redis 连接池
spring.data.redis.lettuce.pool.max-active=50
spring.data.redis.lettuce.pool.max-idle=20
spring.data.redis.lettuce.pool.min-idle=10
spring.data.redis.lettuce.pool.max-wait=5000
```

### 3. 安全响应头

```nginx
# nginx-enhanced.conf
add_header X-Frame-Options "DENY";
add_header X-Content-Type-Options "nosniff";
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

---

## ⚡ 性能监控

### 1. 关键指标

**应用指标**:
- QPS (每秒请求数)
- 响应时间 (P50, P90, P99)
- 错误率

**数据库指标**:
- 连接数
- 慢查询数量
- 缓存命中率

**Redis 指标**:
- 内存使用
- 键数量
- 命令执行时间

### 2. 监控工具集成

**Prometheus**:

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info
  metrics:
    export:
      prometheus:
        enabled: true
```

**Grafana Dashboard**:
- JVM 监控
- HTTP 请求监控
- 数据库连接池监控
- Redis 监控

---

## 🚨 应急响应

### 1. 发现暴力破解

```bash
# 1. 立即封禁攻击 IP
docker compose exec mysql mysql -u root -p -e \
  "INSERT INTO kami.ip_blacklist (ip, reason) VALUES ('攻击IP', '暴力破解');"

# 2. 查看攻击详情
docker compose logs backend | grep "攻击IP"

# 3. 重置限流计数器
docker compose exec redis redis-cli -a password DEL ratelimit:login:攻击IP
```

### 2. 发现数据泄露

```bash
# 1. 立即轮换所有密钥
# 生成新密钥
NEW_JWT_SECRET=$(openssl rand -base64 32)
NEW_ENCRYPTION_KEY=$(openssl rand -base64 32)

# 2. 更新 .env
sed -i "s|JWT_SECRET=.*|JWT_SECRET=$NEW_JWT_SECRET|" .env
sed -i "s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$NEW_ENCRYPTION_KEY|" .env

# 3. 重新加密敏感数据（需要自定义脚本）
# 4. 强制所有用户重新登录
docker compose exec redis redis-cli -a password FLUSHDB

# 5. 通知用户修改密码
```

### 3. 服务异常

```bash
# 1. 查看错误日志
docker compose logs backend --tail=100 | grep ERROR

# 2. 检查资源使用
docker stats

# 3. 重启服务
docker compose restart backend

# 4. 如果数据库损坏，从备份恢复
docker compose exec mysql mysql -u root -p < backup_latest.sql
```

---

## 📚 安全检查清单

### 部署前检查

- [ ] 所有默认密码已修改
- [ ] JWT_SECRET 已设置为随机值
- [ ] ENCRYPTION_KEY 已设置为随机值
- [ ] 数据库密码已设置为强密码
- [ ] Redis 密码已设置
- [ ] SSL 证书已配置（生产环境使用 Let's Encrypt）
- [ ] CORS 配置正确
- [ ] 防火墙规则已配置
- [ ] 备份策略已建立

### 运行中检查

- [ ] 定期审计日志
- [ ] 监控异常登录
- [ ] 检查限流规则是否生效
- [ ] 数据库备份正常
- [ ] SSL 证书未过期
- [ ] 依赖包无已知漏洞
- [ ] 系统补丁已更新

---

## 📞 安全事件报告

如发现安全漏洞，请发送邮件至：security@example.com

**包含信息**:
- 漏洞描述
- 复现步骤
- 影响范围
- 建议修复方案

我们承诺在 48 小时内响应，7 天内发布补丁。

---

**最后更新**: 2026-08-15
