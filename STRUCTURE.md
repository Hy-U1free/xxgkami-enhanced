# xxgkami 安全增强版 - 完整项目结构

```
xxgkami-enhanced/
│
├── 📁 backend/                                 # 后端服务（Spring Boot）
│   ├── src/
│   │   └── main/
│   │       ├── java/org/xxg/backend/backend/
│   │       │   │
│   │       │   ├── 🔐 crypto/                  # 密码学模块
│   │       │   │   ├── PasswordEncoder.java    # Argon2id 密码哈希
│   │       │   │   └── EncryptionUtil.java     # AES-256-GCM 加密
│   │       │   │
│   │       │   ├── 🚦 ratelimit/               # 限流模块
│   │       │   │   ├── RateLimiter.java        # Redis 分布式限流器
│   │       │   │   └── RateLimitAspect.java    # 限流切面
│   │       │   │
│   │       │   ├── 📊 audit/                   # 审计模块
│   │       │   │   └── AuditLogAspect.java     # 审计日志切面
│   │       │   │
│   │       │   ├── 🛡️ filter/                  # 安全过滤器
│   │       │   │   ├── SqlInjectionFilter.java # SQL 注入防护
│   │       │   │   └── XssFilter.java          # XSS 防护
│   │       │   │
│   │       │   ├── 📝 annotation/              # 注解定义
│   │       │   │   ├── RateLimit.java          # 限流注解
│   │       │   │   └── AuditLog.java           # 审计注解
│   │       │   │
│   │       │   └── [原项目其他代码...]
│   │       │       ├── controller/
│   │       │       ├── service/
│   │       │       ├── repository/
│   │       │       ├── entity/
│   │       │       └── config/
│   │       │
│   │       └── resources/
│   │           ├── application.properties
│   │           └── application-enhanced.properties  # 安全增强配置
│   │
│   ├── Dockerfile                              # 后端 Docker 镜像
│   └── pom.xml                                 # Maven 依赖配置
│
├── 📁 frontend/                                # 前端服务（Vue 3 + Vite）
│   ├── src/
│   │   ├── views/                              # 页面组件
│   │   ├── components/                         # 通用组件
│   │   ├── api/                                # API 接口
│   │   ├── router/                             # 路由配置
│   │   ├── store/                              # 状态管理
│   │   └── utils/                              # 工具函数
│   │
│   ├── package.json                            # NPM 依赖
│   └── vite.config.js                          # Vite 配置
│
├── 📁 databaes/                                # 数据库脚本
│   ├── schema.sql                              # 原项目表结构
│   └── security_tables.sql                     # 安全增强表
│       ├── audit_logs                          # 审计日志表
│       ├── login_logs                          # 登录记录表
│       ├── ip_blacklist                        # IP 黑名单表
│       └── ip_whitelist                        # IP 白名单表
│
├── 📁 deployment/                              # 部署配置
│   └── nginx-enhanced.conf                     # Nginx 安全配置
│
├── 📁 scripts/                                 # 运维脚本
│   ├── backup.sh                               # 数据库备份（支持 OSS）
│   └── restore.sh                              # 数据库恢复
│
├── 📁 ssl/                                     # SSL 证书目录
│   ├── cert.pem                                # 证书文件
│   └── key.pem                                 # 私钥文件
│
├── 📄 docker-compose.yml                       # Docker Compose 编排
├── 📄 Dockerfile.frontend                      # 前端 Nginx 镜像
├── 📄 .env.example                             # 环境变量模板
├── 📄 .gitignore                               # Git 忽略规则
│
├── 📄 install-enhanced.sh                      # 一键部署脚本
│
├── 📚 README-ENHANCED.md                       # 使用文档
├── 📚 SECURITY.md                              # 安全配置指南
├── 📚 IMPROVEMENTS.md                          # 改进总结
├── 📚 PROJECT_STATUS.md                        # 项目状态报告
└── 📚 STRUCTURE.md                             # 本文件
```

---

## 📊 模块说明

### 🔐 密码学模块 (crypto/)

**PasswordEncoder.java**
```java
// Argon2id 密码哈希
public static String hash(String password)
public static boolean verify(String password, String hash)
```

**功能**: 
- 替代 BCrypt，提供更强的密码保护
- 抗 GPU/ASIC 暴力破解
- 内存密集型算法

**使用场景**:
- 用户注册时哈希密码
- 用户登录时验证密码
- 管理员密码管理

---

**EncryptionUtil.java**
```java
// AES-256-GCM 加密/解密
public static String encrypt(String plaintext)
public static String decrypt(String ciphertext)
```

**功能**:
- 加密存储敏感数据
- 认证加密模式（防篡改）
- 随机 IV（防重放攻击）

**使用场景**:
- API 密钥加密存储
- WebHook URL 加密
- 第三方凭证加密

---

### 🚦 限流模块 (ratelimit/)

**RateLimiter.java**
```java
// Redis 分布式限流
public boolean tryAcquire(String key, int maxRequests, int windowSeconds)
```

**功能**:
- 基于 Redis 的滑动窗口限流
- 支持按 IP/用户/API Key 限流
- 分布式环境下一致性保证

**使用场景**:
- 登录接口防暴力破解
- API 接口防滥用
- 短信/邮件发送频率限制

---

**RateLimitAspect.java**
```java
// 限流切面
@Around("@annotation(org.xxg.backend.backend.annotation.RateLimit)")
public Object around(ProceedingJoinPoint joinPoint)
```

**功能**:
- 自动拦截带 @RateLimit 注解的方法
- 超限自动返回 429 Too Many Requests
- 记录超限日志

---

### 📊 审计模块 (audit/)

**AuditLogAspect.java**
```java
// 审计日志切面
@Around("@annotation(org.xxg.backend.backend.annotation.AuditLog)")
public Object around(ProceedingJoinPoint joinPoint)
```

**功能**:
- 自动记录操作日志
- 敏感数据脱敏（密码、密钥）
- 异步记录（不影响性能）

**记录内容**:
- 操作用户
- 操作类型
- 请求参数（脱敏）
- IP 地址
- User-Agent
- 执行时间
- 响应状态

---

### 🛡️ 安全过滤器 (filter/)

**SqlInjectionFilter.java**
```java
// SQL 注入防护
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
```

**防护内容**:
- `' OR '1'='1`
- `UNION SELECT`
- `DROP TABLE`
- `--` 注释
- `sleep()` 时间盲注

---

**XssFilter.java**
```java
// XSS 防护
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
```

**防护内容**:
- `<script>` 标签
- `javascript:` 协议
- `onerror=`、`onload=` 事件
- `<iframe>`、`<embed>` 嵌入

---

### 📝 注解定义 (annotation/)

**@RateLimit**
```java
@RateLimit(key = "login", maxRequests = 5, windowSeconds = 60)
public Result login(...)
```

**参数**:
- `key`: 限流标识
- `maxRequests`: 最大请求数
- `windowSeconds`: 时间窗口（秒）
- `keyType`: 限流维度（IP/USER/API_KEY）

---

**@AuditLog**
```java
@AuditLog(action = "CREATE_USER", resource = "USER", logParams = true)
public Result createUser(...)
```

**参数**:
- `action`: 操作类型
- `resource`: 资源类型
- `logParams`: 是否记录参数
- `logResult`: 是否记录响应

---

## 🗄️ 数据库表结构

### audit_logs（审计日志表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| user_id | int | 操作用户 ID |
| username | varchar(50) | 操作用户名 |
| action | varchar(100) | 操作类型 |
| resource | varchar(255) | 操作资源 |
| method | varchar(10) | HTTP 方法 |
| path | varchar(255) | 请求路径 |
| ip | varchar(50) | 客户端 IP |
| user_agent | varchar(500) | 用户代理 |
| request_params | text | 请求参数（脱敏） |
| response_status | int | 响应状态码 |
| error_message | text | 错误信息 |
| execution_time | int | 执行时间（ms） |
| create_time | datetime | 操作时间 |

**索引**:
- `idx_username` (username)
- `idx_action` (action)
- `idx_create_time` (create_time)
- `idx_ip` (ip)

---

### login_logs（登录记录表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| username | varchar(50) | 用户名 |
| ip | varchar(50) | IP 地址 |
| user_agent | varchar(500) | 用户代理 |
| success | tinyint(1) | 是否成功 |
| fail_reason | varchar(255) | 失败原因 |
| login_time | datetime | 登录时间 |

**索引**:
- `idx_username` (username)
- `idx_ip` (ip)
- `idx_login_time` (login_time)

---

### ip_blacklist（IP 黑名单表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| ip | varchar(50) | IP 地址 |
| reason | varchar(255) | 封禁原因 |
| expire_time | datetime | 过期时间（NULL=永久） |
| create_time | datetime | 创建时间 |

**索引**:
- `uk_ip` (ip) UNIQUE

---

### ip_whitelist（IP 白名单表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| ip | varchar(50) | IP 地址或 CIDR |
| description | varchar(255) | 说明 |
| create_time | datetime | 创建时间 |

**索引**:
- `uk_ip` (ip) UNIQUE

---

## 🚀 部署架构

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Nginx (Frontend)   │  ← HTTPS, Gzip, 限流
              │   Port: 80, 443      │
              └──────────┬───────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
        ▼                                 ▼
┌───────────────┐              ┌──────────────────┐
│ Static Files  │              │  API Proxy       │
│ (Vue Build)   │              │  /api → backend  │
└───────────────┘              └─────────┬────────┘
                                         │
                                         ▼
                              ┌──────────────────────┐
                              │  Spring Boot Backend │
                              │  Port: 8080          │
                              └─────────┬────────────┘
                                        │
                    ┌───────────────────┴───────────────────┐
                    │                                       │
                    ▼                                       ▼
          ┌─────────────────┐                    ┌─────────────────┐
          │  MySQL 8.0      │                    │  Redis 7        │
          │  Port: 3306     │                    │  Port: 6379     │
          │  - 业务数据      │                    │  - 限流计数      │
          │  - 审计日志      │                    │  - 缓存         │
          └─────────────────┘                    └─────────────────┘
```

---

## 📦 Docker 容器编排

```yaml
services:
  mysql:       # 数据库
  redis:       # 缓存 + 限流
  backend:     # Spring Boot API
  frontend:    # Nginx + Vue

volumes:
  mysql_data:      # 数据库持久化
  redis_data:      # Redis 持久化
  backend_logs:    # 后端日志
  backend_backups: # 数据库备份
  nginx_logs:      # Nginx 日志

networks:
  xxgkami-network: # 内部网络
```

---

## 🔧 配置文件说明

### .env（环境变量）

```bash
# 必须修改
MYSQL_ROOT_PASSWORD=     # MySQL root 密码
MYSQL_PASSWORD=          # 应用数据库密码
REDIS_PASSWORD=          # Redis 密码
JWT_SECRET=              # JWT 签名密钥
ENCRYPTION_KEY=          # AES 加密主密钥

# 可选修改
APP_DOMAIN=              # 域名
CORS_ALLOWED_ORIGINS=    # CORS 允许源
```

### application-enhanced.properties

```properties
# 数据库连接池
spring.datasource.hikari.*

# Redis 配置
spring.data.redis.*

# JWT 配置
jwt.*

# 限流配置
ratelimit.*

# 安全配置
security.encryption.*
```

### nginx-enhanced.conf

```nginx
# 安全响应头
add_header X-Frame-Options "DENY";
add_header X-Content-Type-Options "nosniff";
add_header Strict-Transport-Security "max-age=31536000";

# 限流配置
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;

# SSL 配置
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-...';
```

---

## 📚 文档索引

| 文档 | 用途 |
|------|------|
| [README-ENHANCED.md](README-ENHANCED.md) | 快速开始指南 |
| [SECURITY.md](SECURITY.md) | 详细安全配置 |
| [IMPROVEMENTS.md](IMPROVEMENTS.md) | 改进对比总结 |
| [PROJECT_STATUS.md](PROJECT_STATUS.md) | 项目完成状态 |
| [STRUCTURE.md](STRUCTURE.md) | 项目结构说明（本文件） |

---

## 🎯 下一步操作

1. **克隆原项目源码** 到 `backend/` 和 `frontend/` 目录
2. **添加 Maven 依赖** 到 `pom.xml`
3. **合并配置文件** 到 `application.properties`
4. **修改 Controller** 添加 `@RateLimit` 和 `@AuditLog` 注解
5. **导入数据库表** 执行 `security_tables.sql`
6. **配置环境变量** 修改 `.env`
7. **一键部署** 运行 `./install-enhanced.sh`

---

**最后更新**: 2026-08-15  
**项目版本**: v2.0.0-enhanced
