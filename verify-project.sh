#!/bin/bash

# xxgkami 安全增强版 - 项目验证脚本
# 用于验证所有安全模块和配置是否正确部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

check_pass() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    log_info "$1"
}

check_fail() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    log_error "$1"
}

# 1. 检查文件结构
log_section "1. 检查项目文件结构"

files_to_check=(
    "backend/src/main/java/org/xxg/backend/backend/crypto/PasswordEncoder.java"
    "backend/src/main/java/org/xxg/backend/backend/crypto/EncryptionUtil.java"
    "backend/src/main/java/org/xxg/backend/backend/ratelimit/RateLimiter.java"
    "backend/src/main/java/org/xxg/backend/backend/ratelimit/RateLimitAspect.java"
    "backend/src/main/java/org/xxg/backend/backend/audit/AuditLogAspect.java"
    "backend/src/main/java/org/xxg/backend/backend/filter/SqlInjectionFilter.java"
    "backend/src/main/java/org/xxg/backend/backend/filter/XssFilter.java"
    "backend/src/main/java/org/xxg/backend/backend/annotation/RateLimit.java"
    "backend/src/main/java/org/xxg/backend/backend/annotation/AuditLog.java"
    "databaes/security_tables.sql"
    "docker-compose.yml"
    "backend/Dockerfile"
    "Dockerfile.frontend"
    "deployment/nginx-enhanced.conf"
    ".env.example"
    "scripts/backup.sh"
    "scripts/restore.sh"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        check_pass "文件存在: $file"
    else
        check_fail "文件缺失: $file"
    fi
done

# 2. 检查文档完整性
log_section "2. 检查文档完整性"

docs_to_check=(
    "README-ENHANCED.md"
    "SECURITY.md"
    "IMPROVEMENTS.md"
    "PROJECT_STATUS.md"
    "STRUCTURE.md"
    "DEPLOYMENT_GUIDE.md"
    "DELIVERY.md"
    "FINAL_SUMMARY.md"
)

for doc in "${docs_to_check[@]}"; do
    if [ -f "$doc" ]; then
        word_count=$(wc -l < "$doc")
        if [ "$word_count" -gt 50 ]; then
            check_pass "文档完整: $doc ($word_count 行)"
        else
            check_fail "文档不完整: $doc (仅 $word_count 行)"
        fi
    else
        check_fail "文档缺失: $doc"
    fi
done

# 3. 检查配置文件
log_section "3. 检查配置文件"

if [ -f ".env.example" ]; then
    required_vars=(
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_PASSWORD"
        "REDIS_PASSWORD"
        "JWT_SECRET"
        "ENCRYPTION_KEY"
    )

    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" .env.example; then
            check_pass "环境变量定义: $var"
        else
            check_fail "环境变量缺失: $var"
        fi
    done
fi

# 4. 检查 Docker 配置
log_section "4. 检查 Docker 配置"

if [ -f "docker-compose.yml" ]; then
    services=("mysql" "redis" "backend" "frontend")

    for service in "${services[@]}"; do
        if grep -q "  ${service}:" docker-compose.yml; then
            check_pass "Docker 服务定义: $service"
        else
            check_fail "Docker 服务缺失: $service"
        fi
    done
fi

# 5. 检查数据库表定义
log_section "5. 检查数据库表定义"

if [ -f "databaes/security_tables.sql" ]; then
    tables=("audit_logs" "login_logs" "ip_blacklist" "ip_whitelist")

    for table in "${tables[@]}"; do
        if grep -q "CREATE TABLE.*${table}" databaes/security_tables.sql; then
            check_pass "数据库表定义: $table"
        else
            check_fail "数据库表缺失: $table"
        fi
    done

    # 检查索引
    if grep -q "CREATE INDEX" databaes/security_tables.sql; then
        index_count=$(grep -c "CREATE INDEX" databaes/security_tables.sql)
        check_pass "数据库索引: $index_count 个索引定义"
    else
        check_warn "未发现索引定义"
    fi
fi

# 6. 检查安全特性实现
log_section "6. 检查安全特性实现"

if [ -f "backend/src/main/java/org/xxg/backend/backend/crypto/PasswordEncoder.java" ]; then
    if grep -q "Argon2" backend/src/main/java/org/xxg/backend/backend/crypto/PasswordEncoder.java; then
        check_pass "Argon2id 密码哈希实现"
    else
        check_fail "Argon2id 实现缺失"
    fi
fi

if [ -f "backend/src/main/java/org/xxg/backend/backend/crypto/EncryptionUtil.java" ]; then
    if grep -q "AES/GCM" backend/src/main/java/org/xxg/backend/backend/crypto/EncryptionUtil.java; then
        check_pass "AES-256-GCM 加密实现"
    else
        check_fail "AES-256-GCM 实现缺失"
    fi
fi

if [ -f "backend/src/main/java/org/xxg/backend/backend/ratelimit/RateLimiter.java" ]; then
    if grep -q "RedisTemplate" backend/src/main/java/org/xxg/backend/backend/ratelimit/RateLimiter.java; then
        check_pass "Redis 限流器实现"
    else
        check_fail "Redis 限流器实现不完整"
    fi
fi

# 7. 检查 Nginx 安全配置
log_section "7. 检查 Nginx 安全配置"

if [ -f "deployment/nginx-enhanced.conf" ]; then
    security_headers=(
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
        "Strict-Transport-Security"
    )

    for header in "${security_headers[@]}"; do
        if grep -q "$header" deployment/nginx-enhanced.conf; then
            check_pass "安全响应头: $header"
        else
            check_fail "安全响应头缺失: $header"
        fi
    done

    # 检查限流配置
    if grep -q "limit_req_zone" deployment/nginx-enhanced.conf; then
        check_pass "Nginx 限流配置"
    else
        check_fail "Nginx 限流配置缺失"
    fi
fi

# 8. 检查脚本可执行性
log_section "8. 检查脚本可执行性"

scripts=("install-enhanced.sh" "scripts/backup.sh" "scripts/restore.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if head -n 1 "$script" | grep -q "#!/bin/bash"; then
            check_pass "脚本 shebang: $script"
        else
            check_fail "脚本缺少 shebang: $script"
        fi
    fi
done

# 9. 生成报告
log_section "验证报告"

echo -e "总检查项: ${BLUE}${TOTAL_CHECKS}${NC}"
echo -e "通过: ${GREEN}${PASSED_CHECKS}${NC}"
echo -e "失败: ${RED}${FAILED_CHECKS}${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "\n${GREEN}✓ 所有检查项通过！项目结构完整。${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ 发现 ${FAILED_CHECKS} 个问题，请检查上述失败项。${NC}\n"
    exit 1
fi
