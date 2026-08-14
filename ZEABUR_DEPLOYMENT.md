# Zeabur 部署指南

## 📦 在 Zeabur 上部署 xxgkami 安全增强版

本项目已针对 Zeabur 平台进行优化配置。

---

## 🚀 快速部署

### 方法一：从 GitHub 仓库部署（推荐）

#### 步骤 1: 登录 Zeabur

访问：https://zeabur.com/

使用 GitHub 账号登录

#### 步骤 2: 创建新项目

1. 点击 **"Create Project"**
2. 选择区域（推荐选择离你近的区域）

#### 步骤 3: 添加服务

**3.1 部署后端服务**

1. 点击 **"Add Service"**
2. 选择 **"Git"**
3. 选择仓库：**Hy-U1free/xxgkami-enhanced**
4. 选择分支：**main**
5. Zeabur 会自动检测到 Dockerfile 并开始构建

**3.2 添加 MySQL 数据库**

1. 点击 **"Add Service"**
2. 选择 **"Prebuilt"** → **"MySQL"**
3. 选择 MySQL 8.0 版本
4. 等待数据库启动

**3.3 添加 Redis**

1. 点击 **"Add Service"**
2. 选择 **"Prebuilt"** → **"Redis"**
3. 选择 Redis 7 版本
4. 等待 Redis 启动

#### 步骤 4: 配置环境变量

点击后端服务 → **Variables** → 添加以下环境变量：

```bash
# 数据库配置（从 MySQL 服务复制连接信息）
SPRING_DATASOURCE_URL=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/kami
SPRING_DATASOURCE_USERNAME=${MYSQL_USERNAME}
SPRING_DATASOURCE_PASSWORD=${MYSQL_PASSWORD}

# Redis 配置（从 Redis 服务复制连接信息）
SPRING_DATA_REDIS_HOST=${REDIS_HOST}
SPRING_DATA_REDIS_PORT=${REDIS_PORT}
SPRING_DATA_REDIS_PASSWORD=${REDIS_PASSWORD}

# JWT 配置（使用你的密钥）
JWT_SECRET=281419381412e64209e63f09bc04adebd291f01181a0177290dd1afa7fc6142b
JWT_ACCESS_TOKEN_EXPIRATION=3600
JWT_REFRESH_TOKEN_EXPIRATION=604800

# 加密配置（使用你的密钥）
ENCRYPTION_KEY=9c2d72a9128a022facbd0e06b5f49d8ad2727b17f1abd8c9fc02589539219704

# 应用配置
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=prod

# CORS 配置（部署后设置为你的域名）
CORS_ALLOWED_ORIGINS=https://your-domain.zeabur.app
```

**重要提示**：
- `${MYSQL_HOST}` 等变量会被 Zeabur 自动注入
- 或者在 MySQL/Redis 服务中复制 **Connection String**

#### 步骤 5: 初始化数据库

**方法 A：使用 Zeabur 控制台**

1. 点击 MySQL 服务 → **Console**
2. 执行 SQL：

```sql
CREATE DATABASE IF NOT EXISTS kami CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE kami;

-- 复制 databaes/kami.sql 的内容
-- 复制 databaes/security_tables.sql 的内容
```

**方法 B：使用本地客户端**

```bash
# 从 Zeabur 复制数据库连接信息
mysql -h <host> -u <username> -p < databaes/kami.sql
mysql -h <host> -u <username> -p < databaes/security_tables.sql
```

#### 步骤 6: 绑定域名（可选）

1. 点击后端服务 → **Networking**
2. 点击 **"Generate Domain"** 获取免费域名
3. 或绑定自定义域名

#### 步骤 7: 验证部署

访问：`https://your-service.zeabur.app/actuator/health`

应该返回：
```json
{
  "status": "UP"
}
```

---

## 📋 Zeabur 配置文件说明

### 1. Dockerfile

项目根目录的 `Dockerfile` 针对 Zeabur 优化：

- ✅ 多阶段构建，减小镜像体积
- ✅ 使用 Maven 缓存层，加速构建
- ✅ JVM 参数优化（256MB-512MB）
- ✅ 健康检查配置
- ✅ 非 root 用户运行

### 2. zbpack.json

构建配置文件，定义构建和启动命令。

---

## 💰 费用说明

### 免费额度

Zeabur 提供免费额度：
- ✅ 每月 $5 USD 额度
- ✅ 自动休眠（15分钟无请求）
- ✅ 适合开发测试环境

### 推荐配置

**开发环境**（免费额度内）：
- Backend: 0.5 CPU, 512MB RAM
- MySQL: 512MB RAM
- Redis: 256MB RAM

**生产环境**（付费）：
- Backend: 1 CPU, 1GB RAM ($10/月)
- MySQL: 1GB RAM ($5/月)
- Redis: 512MB RAM ($3/月)

总计：约 $18/月

---

## ⚙️ 环境变量完整清单

```bash
# 必须配置
SPRING_DATASOURCE_URL=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/kami
SPRING_DATASOURCE_USERNAME=${MYSQL_USERNAME}
SPRING_DATASOURCE_PASSWORD=${MYSQL_PASSWORD}
SPRING_DATA_REDIS_HOST=${REDIS_HOST}
SPRING_DATA_REDIS_PORT=${REDIS_PORT}
SPRING_DATA_REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_SECRET=你的JWT密钥
ENCRYPTION_KEY=你的加密密钥

# 可选配置
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=prod
CORS_ALLOWED_ORIGINS=https://your-domain.zeabur.app
APP_DOMAIN=your-domain.zeabur.app

# 数据库连接池
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=10
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=2

# 限流配置
RATELIMIT_LOGIN_MAX_REQUESTS=5
RATELIMIT_API_MAX_REQUESTS=100

# 邮件配置（可选）
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

---

## 🔧 常见问题

### 1. 构建失败

**错误**: `maven build failed`

**解决方案**:
1. 检查 `backend/pom.xml` 是否完整
2. 确保所有依赖都能访问
3. 查看构建日志定位具体错误

### 2. 数据库连接失败

**错误**: `Could not connect to MySQL`

**解决方案**:
1. 检查环境变量是否正确配置
2. 确保 MySQL 服务已启动
3. 使用 Zeabur 自动注入的变量：`${MYSQL_HOST}`

### 3. Redis 连接失败

**解决方案**:
1. 检查 Redis 服务状态
2. 确认 Redis 密码配置正确
3. 使用内部连接地址

### 4. 服务自动休眠

**现象**: 15分钟无请求后服务休眠

**解决方案**:
- 开发环境：可以接受
- 生产环境：升级到付费计划

### 5. 内存不足

**错误**: `OutOfMemoryError`

**解决方案**:
1. 增加服务内存配置
2. 调整 JVM 参数：
   ```bash
   JAVA_OPTS=-Xms128m -Xmx256m -XX:+UseG1GC
   ```

---

## 📊 监控与日志

### 查看日志

1. 点击服务 → **Logs**
2. 实时查看应用日志

### 查看指标

1. 点击服务 → **Metrics**
2. 查看 CPU、内存、网络使用情况

### 健康检查

Zeabur 自动使用 Dockerfile 中的 HEALTHCHECK 配置

---

## 🔐 安全建议

### 1. 使用环境变量管理密钥

❌ 不要将密钥硬编码在代码中
✅ 使用 Zeabur 环境变量

### 2. 限制 CORS

```bash
CORS_ALLOWED_ORIGINS=https://your-domain.zeabur.app
```

### 3. 启用 HTTPS

Zeabur 自动为所有服务提供 HTTPS

### 4. 定期更新依赖

```bash
mvn versions:display-dependency-updates
```

---

## 🚀 CI/CD 自动部署

Zeabur 支持自动部署：

1. **推送到 GitHub** → 自动触发构建
2. **构建成功** → 自动部署
3. **健康检查通过** → 切换流量

**配置方法**:
1. 服务设置 → **Git**
2. 启用 **"Auto Deploy"**
3. 选择分支（默认 main）

---

## 📱 前端部署（可选）

### 部署前端服务

1. 点击 **"Add Service"** → **"Git"**
2. 选择同一仓库
3. 在 **Service Settings** 中：
   - Build Command: `npm install && npm run build`
   - Output Directory: `dist`
   - Framework: `static`

4. 配置环境变量：
   ```bash
   VITE_API_URL=https://your-backend.zeabur.app/api
   ```

---

## 📝 部署检查清单

部署前确认：

- [x] GitHub 仓库已创建并推送代码
- [ ] Zeabur 账号已注册
- [ ] 项目已创建
- [ ] 后端服务已添加
- [ ] MySQL 服务已添加
- [ ] Redis 服务已添加
- [ ] 环境变量已配置
- [ ] 数据库已初始化
- [ ] 健康检查通过
- [ ] 域名已绑定（可选）

---

## 🎯 下一步

部署成功后：

1. 访问 API 文档：`https://your-domain.zeabur.app/swagger-ui.html`
2. 测试限流功能
3. 查看审计日志
4. 配置监控告警

---

## 💡 小技巧

### 1. 快速重启服务

服务页面 → **...** → **Restart**

### 2. 查看实时日志

```bash
# 使用 Zeabur CLI
zeabur logs <service-id> -f
```

### 3. 回滚到上一版本

服务页面 → **Deployments** → 选择历史版本 → **Redeploy**

---

## 📞 获取帮助

- Zeabur 文档：https://zeabur.com/docs
- Zeabur Discord：https://discord.gg/zeabur
- 项目 Issues：https://github.com/Hy-U1free/xxgkami-enhanced/issues

---

**祝部署顺利！** 🎉

如遇问题，请查看日志或联系支持。
