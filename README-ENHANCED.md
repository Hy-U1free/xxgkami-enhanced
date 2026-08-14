# xxgkami 卡密验证系统 - 安全增强版

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Security](https://img.shields.io/badge/security-enhanced-green.svg)]()
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)]()

## 📋 项目简介

**xxgkami 安全增强版** 是基于原版小小怪卡密验证系统的安全加固版本，提供企业级的卡密管理和验证服务。

### 🔒 安全增强功能

相比原版，增强版新增以下安全特性：

#### 密码学增强
- ✅ **Argon2id 密码哈希** - 替代 BCrypt，防御 GPU 暴力破解
- ✅ **AES-256-GCM 数据加密** - API 密钥端到端加密存储
- ✅ **HMAC-SHA256 签名** - 防止卡密篡改和重放攻击
- ✅ **密钥派生函数** - 使用 PBKDF2 派生加密子密钥

#### 访问控制
- ✅ **Redis 分布式限流** - 防止暴力破解和 API 滥用
- ✅ **IP 黑白名单** - 动态 IP 访问控制
- ✅ **JWT 双 Token** - Access Token + Refresh Token 机制
- ✅ **会话管理** - 检测异常登录和并发会话

#### 防护措施
- ✅ **SQL 注入防护** - 参数化查询 + 输入过滤
- ✅ **XSS 防护** - 输入验证 + 输出编码
- ✅ **CSRF 防护** - 双 Token 验证
- ✅ **安全响应头** - CSP, HSTS, X-Frame-Options 等

#### 审计与监控
- ✅ **完整审计日志** - 记录所有敏感操作
- ✅ **登录日志追踪** - 记录登录尝试和失败原因
- ✅ **异步日志记录** - 不影响业务性能
- ✅ **敏感数据脱敏** - 自动过滤密码、密钥等

#### 性能优化
- ✅ **Redis 热点缓存** - 减少数据库压力
- ✅ **数据库连接池优化** - HikariCP 调优
- ✅ **Nginx 压缩** - Gzip 压缩静态资源
- ✅ **Docker 多阶段构建** - 减小镜像体积

---

## 🚀 快速开始

### 方式一：一键部署（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/yourusername/xxgkami-enhanced.git
cd xxgkami-enhanced

# 2. 执行一键部署脚本
chmod +x install-enhanced.sh
sudo ./install-enhanced.sh

# 3. 等待部署完成
# 脚本会自动安装 Docker、配置环境变量、生成密钥、启动服务
```

### 方式二：手动部署

#### 1. 环境要求

- **操作系统**: Linux (CentOS 7+, Ubuntu 20.04+, Debian 10+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 最低 2GB，推荐 4GB+
- **硬盘**: 最低 20GB

#### 2. 安装 Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | bash

# CentOS
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl start docker
systemctl enable docker
```

#### 3. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 生成安全密钥
openssl rand -base64 32  # 生成 JWT_SECRET
openssl rand -base64 32  # 生成 ENCRYPTION_KEY
openssl rand -base64 32  # 生成 MYSQL_PASSWORD
openssl rand -base64 32  # 生成 REDIS_PASSWORD

# 编辑 .env 文件，填入生成的密钥
vim .env
```

**重要：** 必须修改以下配置项：
- `MYSQL_ROOT_PASSWORD` - MySQL root 密码
- `MYSQL_PASSWORD` - 应用数据库密码
- `REDIS_PASSWORD` - Redis 密码
- `JWT_SECRET` - JWT 签名密钥（256位）
- `ENCRYPTION_KEY` - AES 加密主密钥（256位）
- `APP_DOMAIN` - 你的域名

#### 4. 生成 SSL 证书

**测试环境（自签名证书）：**

```bash
mkdir -p ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=xxgkami/CN=yourdomain.com"
```

**生产环境（Let's Encrypt）：**

```bash
# 安装 Certbot
apt-get install -y certbot

# 申请证书
certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# 复制证书
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem
```

#### 5. 启动服务

```bash
# 构建镜像
docker compose build

# 启动服务
docker compose up -d

# 查看日志
docker compose logs -f

# 查看服务状态
docker compose ps
```

#### 6. 访问系统

- **前端地址**: https://yourdomain.com
- **API 地址**: https://yourdomain.com/api
- **默认账户**: admin
- **默认密码**: Admin@123456

**首次登录后务必立即修改密码！**

---

## 🛠️ 常用命令

### 服务管理

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看日志
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f mysql

# 查看服务状态
docker compose ps

# 进入容器
docker compose exec backend bash
docker compose exec mysql bash
```

### 数据库操作

```bash
# 备份数据库
docker compose exec mysql mysqldump -u root -p kami > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker compose exec -T mysql mysql -u root -p kami < backup_20261215.sql

# 进入 MySQL
docker compose exec mysql mysql -u root -p
```

### Redis 操作

```bash
# 进入 Redis CLI
docker compose exec redis redis-cli -a your_redis_password

# 查看所有 key
KEYS *

# 清空缓存
FLUSHDB

# 查看内存使用
INFO memory
```

---

## 📊 性能调优

### MySQL 优化

编辑 `docker-compose.yml` 中的 MySQL 配置：

```yaml
command:
  - --max_connections=500
  - --innodb_buffer_pool_size=1G
  - --innodb_log_file_size=256M
  - --max_allowed_packet=64M
```

### Redis 优化

```yaml
command: redis-server 
  --maxmemory 512mb 
  --maxmemory-policy allkeys-lru
  --save 900 1
  --save 300 10
```

### Nginx 优化

编辑 `deployment/nginx-enhanced.conf`：

```nginx
worker_processes auto;
worker_connections 4096;
keepalive_timeout 120;
```

---

## 🔐 安全最佳实践

### 1. 密钥管理

- ✅ 使用高强度随机密钥（至少 256 位）
- ✅ 定期轮换密钥（建议每 90 天）
- ✅ 永远不要将密钥提交到版本控制
- ✅ 使用环境变量或密钥管理服务

### 2. 访问控制

- ✅ 使用强密码（至少 16 位，包含大小写、数字、特殊字符）
- ✅ 启用 IP 白名单限制管理后台
- ✅ 定期审查用户权限
- ✅ 禁用不必要的账户

### 3. 网络安全

- ✅ 强制使用 HTTPS
- ✅ 配置防火墙规则
- ✅ 限制数据库和 Redis 只允许本地访问
- ✅ 启用 DDoS 防护（使用 Cloudflare 等）

### 4. 监控告警

- ✅ 监控登录失败次数
- ✅ 监控异常 API 调用
- ✅ 配置日志分析和告警
- ✅ 定期审计日志

### 5. 数据备份

- ✅ 每天自动备份数据库
- ✅ 异地备份（OSS/S3）
- ✅ 定期测试恢复流程
- ✅ 保留至少 30 天备份

---

## 📁 项目结构

```
xxgkami-enhanced/
├── backend/                    # 后端服务
│   ├── src/
│   │   └── main/
│   │       ├── java/
│   │       │   └── org/xxg/backend/
│   │       │       ├── crypto/       # 加密工具
│   │       │       ├── ratelimit/    # 限流器
│   │       │       ├── audit/        # 审计日志
│   │       │       ├── filter/       # 安全过滤器
│   │       │       └── annotation/   # 注解定义
│   │       └── resources/
│   │           └── application-enhanced.properties
│   ├── Dockerfile
│   └── pom.xml
├── frontend/                   # 前端服务
│   ├── src/
│   ├── Dockerfile.frontend
│   └── package.json
├── databaes/                   # 数据库脚本
│   ├── schema.sql
│   └── security_tables.sql
├── deployment/                 # 部署配置
│   └── nginx-enhanced.conf
├── ssl/                        # SSL 证书
│   ├── cert.pem
│   └── key.pem
├── docker-compose.yml          # Docker Compose 配置
├── .env.example                # 环境变量模板
├── install-enhanced.sh         # 一键部署脚本
├── SECURITY.md                 # 安全指南
└── README-ENHANCED.md          # 本文档
```

---

## 🐛 故障排查

### 服务启动失败

```bash
# 查看详细日志
docker compose logs backend

# 常见问题：
# 1. 端口被占用 - 修改 docker-compose.yml 中的端口
# 2. 数据库连接失败 - 检查 .env 中的数据库密码
# 3. Redis 连接失败 - 检查 Redis 密码配置
```

### 数据库连接错误

```bash
# 检查 MySQL 是否正常运行
docker compose ps mysql

# 查看 MySQL 日志
docker compose logs mysql

# 测试连接
docker compose exec mysql mysql -u root -p
```

### 性能问题

```bash
# 查看容器资源使用
docker stats

# 查看 MySQL 慢查询
docker compose exec mysql mysql -u root -p -e "SHOW FULL PROCESSLIST;"

# 查看 Redis 内存
docker compose exec redis redis-cli -a password INFO memory
```

---

## 📈 监控指标

推荐监控以下关键指标：

- **应用指标**: QPS、响应时间、错误率
- **数据库**: 连接数、慢查询、缓存命中率
- **Redis**: 内存使用、命令执行时间、键数量
- **系统**: CPU、内存、磁盘、网络

推荐工具：
- Prometheus + Grafana
- ELK Stack（日志分析）
- Alertmanager（告警）

---

## 🔄 版本升级

```bash
# 1. 备份数据
docker compose exec mysql mysqldump -u root -p kami > backup_before_upgrade.sql

# 2. 拉取最新代码
git pull origin main

# 3. 重新构建
docker compose build --no-cache

# 4. 停止旧服务
docker compose down

# 5. 启动新服务
docker compose up -d

# 6. 验证升级
docker compose logs -f
```

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 贡献流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📄 许可证

本项目基于 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- 原项目：[xiaoxiaoguai-yyds/xxgkami-pro](https://github.com/xiaoxiaoguai-yyds/xxgkami-pro)
- 安全增强：基于 OWASP 安全最佳实践

---

## 📞 联系方式

- **问题反馈**: [GitHub Issues](https://github.com/yourusername/xxgkami-enhanced/issues)
- **安全漏洞**: security@example.com

---

## ⚠️ 免责声明

本软件仅供学习和研究使用，请勿用于非法用途。使用本软件造成的任何后果由使用者自行承担。
