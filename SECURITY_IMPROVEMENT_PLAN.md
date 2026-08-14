# 🔒 安全改进实施计划

## Phase 1: 后端核心安全改进 (优先级: 🔴 高)

### 1.1 密码学升级
- [ ] 添加 Argon2id 密码哈希工具类
- [ ] 迁移现有 BCrypt 到 Argon2id
- [ ] 实现 API 密钥 AES-256-GCM 加密
- [ ] JWT 密钥轮换机制
- [ ] ECC 签名验证工具

**文件涉及:**
- `backend/src/main/java/org/xxg/backend/backend/security/Argon2idPasswordEncoder.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/security/EncryptionUtil.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/config/SecurityConfig.java` (修改)

**估计时间:** 4 小时

---

### 1.2 SQL 注入防护
- [ ] 审查所有 JdbcTemplate 查询
- [ ] 将字符串拼接改为 PreparedStatement
- [ ] 添加参数验证拦截器
- [ ] 危险字符过滤

**文件涉及:**
- 所有 `*Repository.java` 文件
- `backend/src/main/java/org/xxg/backend/backend/filter/SqlInjectionFilter.java` (新增)

**估计时间:** 6 小时

---

### 1.3 XSS 防护
- [ ] 输入验证器 (Bean Validation)
- [ ] 输出 HTML 编码
- [ ] Content-Security-Policy 头
- [ ] 禁用危险的 Jackson 特性

**文件涉及:**
- `backend/src/main/java/org/xxg/backend/backend/validator/InputValidator.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/filter/XssFilter.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/config/WebConfig.java` (修改)

**估计时间:** 3 小时

---

### 1.4 限流防护
- [ ] Redis 分布式限流器
- [ ] 令牌桶算法实现
- [ ] 限流注解
- [ ] 不同接口不同策略

**文件涉及:**
- `backend/src/main/java/org/xxg/backend/backend/ratelimit/RateLimiter.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/ratelimit/RateLimitAspect.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/annotation/RateLimit.java` (新增)

**估计时间:** 4 小时

---

### 1.5 审计日志
- [ ] 操作日志表
- [ ] 审计日志 AOP
- [ ] 敏感操作记录
- [ ] 日志查询接口

**文件涉及:**
- `databaes/audit_log.sql` (新增)
- `backend/src/main/java/org/xxg/backend/backend/audit/AuditLogAspect.java` (新增)
- `backend/src/main/java/org/xxg/backend/backend/controller/AuditLogController.java` (新增)

**估计时间:** 3 小时

---

## Phase 2: 性能优化 (优先级: 🟡 中)

### 2.1 Redis 缓存
- [ ] Redis 配置优化
- [ ] 缓存注解
- [ ] 缓存预热
- [ ] 布隆过滤器防穿透

**估计时间:** 4 小时

---

### 2.2 数据库优化
- [ ] 添加复合索引
- [ ] 查询优化
- [ ] 慢查询监控
- [ ] 连接池调优

**估计时间:** 3 小时

---

## Phase 3: 功能完善 (优先级: 🟢 低)

### 3.1 WebHook 增强
- [ ] 重试机制
- [ ] HMAC 签名
- [ ] 超时控制
- [ ] 失败告警

**估计时间:** 3 小时

---

### 3.2 双因素认证
- [ ] TOTP 生成器
- [ ] 二维码生成
- [ ] 备用码
- [ ] 强制启用

**估计时间:** 4 小时

---

### 3.3 自动备份
- [ ] Cron 任务
- [ ] 增量备份
- [ ] 异地存储
- [ ] 一键恢复

**估计时间:** 3 小时

---

## 总估计时间: 37 小时

---

## 实施优先级

### 第一批 (必须)
1. SQL 注入防护
2. Argon2id 密码哈希
3. API 密钥加密
4. 限流防护

### 第二批 (重要)
5. XSS 防护
6. 审计日志
7. Redis 缓存
8. 数据库索引优化

### 第三批 (增强)
9. WebHook 重试
10. 2FA 认证
11. 自动备份

---

## 测试计划

### 安全测试
- [ ] SQL 注入测试 (sqlmap)
- [ ] XSS 测试
- [ ] CSRF 测试
- [ ] 暴力破解测试
- [ ] 限流测试

### 性能测试
- [ ] 压力测试 (JMeter)
- [ ] 并发测试
- [ ] 缓存命中率
- [ ] 数据库慢查询

### 功能测试
- [ ] 单元测试
- [ ] 集成测试
- [ ] E2E 测试

---

## 部署检查清单

- [ ] 修改默认密码
- [ ] 生成新的 JWT 密钥
- [ ] 配置 Redis 密码
- [ ] 配置数据库 SSL
- [ ] 启用 HTTPS
- [ ] 配置防火墙
- [ ] 限制数据库远程访问
- [ ] 配置自动备份
- [ ] 配置监控告警

---

## 现在开始实施...
