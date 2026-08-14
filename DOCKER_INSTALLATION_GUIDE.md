# Docker 安装指南

## Windows 系统安装 Docker Desktop

### 方式一：官方下载（推荐）

1. **下载 Docker Desktop**
   访问：https://www.docker.com/products/docker-desktop/
   
   或直接下载：
   https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

2. **安装步骤**
   - 双击运行 `Docker Desktop Installer.exe`
   - 勾选 "Use WSL 2 instead of Hyper-V" (推荐)
   - 点击 "OK" 开始安装
   - 安装完成后重启电脑

3. **启动 Docker Desktop**
   - 从开始菜单启动 Docker Desktop
   - 等待 Docker Engine 启动完成（托盘图标显示绿色）
   - 首次启动可能需要 2-5 分钟

4. **验证安装**
   ```powershell
   docker --version
   docker-compose --version
   ```

### 方式二：使用 Chocolatey 安装

如果你已安装 Chocolatey：

```powershell
# 以管理员身份运行 PowerShell
choco install docker-desktop -y
```

### 系统要求

- Windows 10 64-bit: Pro, Enterprise, or Education (Build 19041 or higher)
- 或 Windows 11 64-bit
- 启用 Hyper-V 和容器 Windows 功能
- 至少 4GB RAM
- BIOS 启用虚拟化

### 启用 WSL 2（推荐）

1. **启用 WSL**
   ```powershell
   # 以管理员身份运行
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **重启电脑**

3. **安装 WSL 2 Linux 内核更新包**
   下载：https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
   
   安装后运行：
   ```powershell
   wsl --set-default-version 2
   ```

---

## 安装完成后构建镜像

### 步骤 1: 启动 Docker Desktop

确保 Docker Desktop 正在运行（托盘图标为绿色）

### 步骤 2: 导航到项目目录

```powershell
cd C:\Users\Administrator\Desktop\audit_build\xxgkami-enhanced
```

### 步骤 3: 构建镜像

**方式 A：使用 Docker Compose（推荐）**
```powershell
# 构建所有镜像
docker-compose build

# 或者分别构建
docker-compose build backend
docker-compose build frontend
```

**方式 B：单独构建**
```powershell
# 构建后端镜像
docker build -t xxgkami-backend:latest ./backend

# 构建前端镜像
docker build -f Dockerfile.frontend -t xxgkami-frontend:latest .
```

### 步骤 4: 启动服务

```powershell
# 启动所有服务
docker-compose up -d

# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 步骤 5: 验证部署

```powershell
# 检查后端健康
curl http://localhost:8080/actuator/health

# 访问前端
# 浏览器打开 http://localhost
```

---

## 常见问题

### 1. WSL 2 installation is incomplete

**解决方案**:
1. 下载并安装 WSL 2 内核更新包
2. 重启 Docker Desktop

### 2. Docker Engine 启动失败

**解决方案**:
1. 检查 Hyper-V 是否启用
   ```powershell
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
   ```
2. 如果未启用，运行：
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
3. 重启电脑

### 3. 虚拟化未启用

**解决方案**:
1. 进入 BIOS 设置
2. 找到 "Virtualization Technology" 或 "Intel VT-x" / "AMD-V"
3. 设置为 Enabled
4. 保存并重启

### 4. 构建速度慢

**解决方案**:
1. 配置 Docker 镜像加速器（国内用户）
   Docker Desktop → Settings → Docker Engine
   
   添加：
   ```json
   {
     "registry-mirrors": [
       "https://docker.mirrors.ustc.edu.cn",
       "https://registry.docker-cn.com"
     ]
   }
   ```

2. 增加 Docker 资源限制
   Docker Desktop → Settings → Resources
   - CPUs: 4+ (推荐)
   - Memory: 4GB+ (推荐)
   - Disk image size: 64GB+

---

## 快速构建命令（安装 Docker 后执行）

```powershell
# 1. 进入项目目录
cd C:\Users\Administrator\Desktop\audit_build\xxgkami-enhanced

# 2. 确保 .env 文件已配置
# 已自动生成，无需手动操作

# 3. 构建并启动所有服务
docker-compose up -d --build

# 4. 查看日志
docker-compose logs -f

# 5. 停止服务
docker-compose down

# 6. 完全清理（包括数据卷）
docker-compose down -v
```

---

## 镜像信息

构建完成后的镜像：

| 镜像名称 | 标签 | 大小（预估） | 说明 |
|---------|------|-------------|------|
| xxgkami-backend | latest | ~200MB | Spring Boot 后端 |
| xxgkami-frontend | latest | ~20MB | Nginx + Vue 前端 |
| mysql | 8.0 | ~500MB | MySQL 数据库 |
| redis | 7-alpine | ~30MB | Redis 缓存 |

---

## 下一步

安装 Docker Desktop 后，可以执行：

```powershell
# 快速部署
.\install-enhanced.sh

# 或手动部署
docker-compose up -d --build
```

详细部署指南见：DEPLOYMENT_GUIDE.md
