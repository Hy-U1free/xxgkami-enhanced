#!/bin/bash

# xxgkami 安全增强版 - 一键部署脚本
# 支持 CentOS 7+, Ubuntu 20.04+, Debian 10+

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检测系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi

    log_info "检测到系统: $OS $OS_VERSION"
}

# 安装 Docker
install_docker() {
    log_info "开始安装 Docker..."

    if command -v docker &> /dev/null; then
        log_warn "Docker 已安装，跳过"
        return
    fi

    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y ca-certificates curl gnupg
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg

            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              tee /etc/apt/sources.list.d/docker.list > /dev/null

            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel)
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            systemctl start docker
            systemctl enable docker
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    log_info "Docker 安装完成"
}

# 生成随机密钥
generate_key() {
    openssl rand -base64 32
}

# 配置环境变量
setup_env() {
    log_info "配置环境变量..."

    if [ -f .env ]; then
        log_warn ".env 文件已存在，是否覆盖？(y/n)"
        read -r answer
        if [ "$answer" != "y" ]; then
            return
        fi
    fi

    cp .env.example .env

    # 生成随机密钥
    MYSQL_ROOT_PASS=$(generate_key)
    MYSQL_PASS=$(generate_key)
    REDIS_PASS=$(generate_key)
    JWT_SECRET=$(generate_key)
    ENCRYPTION_KEY=$(generate_key)

    # 替换密钥
    sed -i "s|MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS|" .env
    sed -i "s|MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$MYSQL_PASS|" .env
    sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$REDIS_PASS|" .env
    sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    sed -i "s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env

    # 询问域名
    echo -ne "${BLUE}请输入您的域名（留空使用 localhost）: ${NC}"
    read -r domain
    if [ -z "$domain" ]; then
        domain="localhost"
    fi

    sed -i "s|APP_DOMAIN=.*|APP_DOMAIN=$domain|" .env
    sed -i "s|APP_BASE_URL=.*|APP_BASE_URL=https://$domain|" .env
    sed -i "s|CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://$domain,https://www.$domain|" .env

    log_info "环境变量配置完成"
    log_warn "重要信息已保存到 .env 文件，请妥善保管！"
}

# 生成自签名证书（仅供测试）
generate_ssl_cert() {
    log_info "生成 SSL 证书..."

    mkdir -p ssl

    if [ -f ssl/cert.pem ]; then
        log_warn "SSL 证书已存在，跳过"
        return
    fi

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=xxgkami/CN=localhost"

    log_warn "已生成自签名证书（仅供测试），生产环境请使用 Let's Encrypt"
}

# 构建并启动服务
start_services() {
    log_info "构建并启动服务..."

    docker compose down
    docker compose build --no-cache
    docker compose up -d

    log_info "服务启动中，请稍候..."
    sleep 10

    # 检查服务状态
    if docker compose ps | grep -q "Up"; then
        log_info "服务启动成功！"
    else
        log_error "服务启动失败，请检查日志"
        docker compose logs
        exit 1
    fi
}

# 显示访问信息
show_access_info() {
    echo ""
    echo -e "${GREEN}==================== 部署完成 ====================${NC}"
    echo -e "${BLUE}访问地址:${NC} http://localhost (或 https://localhost)"
    echo -e "${BLUE}管理员账户:${NC} admin"
    echo -e "${BLUE}初始密码:${NC} Admin@123456"
    echo ""
    echo -e "${YELLOW}重要提示:${NC}"
    echo -e "1. 首次登录后请立即修改密码"
    echo -e "2. 生产环境请配置真实的 SSL 证书"
    echo -e "3. 定期备份数据库"
    echo -e "4. 查看日志: docker compose logs -f"
    echo -e "5. 停止服务: docker compose down"
    echo -e "${GREEN}=================================================${NC}"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║   xxgkami 卡密验证系统 - 安全增强版             ║"
    echo "║   一键部署脚本                                   ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_root
    detect_os
    install_docker
    setup_env
    generate_ssl_cert
    start_services
    show_access_info
}

main
