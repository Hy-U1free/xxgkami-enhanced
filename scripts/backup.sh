#!/bin/bash

# xxgkami 数据库自动备份脚本
# 支持本地备份和远程备份（OSS/S3）

set -e

# 配置
BACKUP_DIR="/app/backups"
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_USER="${MYSQL_USER:-kami}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-kami}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# OSS 配置（可选）
OSS_ENABLED="${BACKUP_OSS_ENABLED:-false}"
OSS_ENDPOINT="${BACKUP_OSS_ENDPOINT}"
OSS_ACCESS_KEY="${BACKUP_OSS_ACCESS_KEY}"
OSS_SECRET_KEY="${BACKUP_OSS_SECRET_KEY}"
OSS_BUCKET="${BACKUP_OSS_BUCKET}"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $1"
}

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 生成备份文件名
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="kami_backup_${TIMESTAMP}.sql"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
COMPRESSED_FILE="${BACKUP_PATH}.gz"

log_info "开始数据库备份..."

# 执行备份
if mysqldump -h "$MYSQL_HOST" \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --set-gtid-purged=OFF \
    "$MYSQL_DATABASE" > "$BACKUP_PATH" 2>/dev/null; then

    log_info "数据库备份完成: $BACKUP_FILE"

    # 获取文件大小
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    log_info "备份文件大小: $BACKUP_SIZE"

    # 压缩备份
    log_info "压缩备份文件..."
    if gzip "$BACKUP_PATH"; then
        COMPRESSED_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
        log_info "压缩完成: ${BACKUP_FILE}.gz (${COMPRESSED_SIZE})"
    else
        log_error "压缩失败"
        COMPRESSED_FILE="$BACKUP_PATH"
    fi

    # 上传到 OSS（如果启用）
    if [ "$OSS_ENABLED" = "true" ]; then
        log_info "上传到远程存储..."

        if command -v aws &> /dev/null; then
            # 使用 AWS CLI（兼容 S3）
            if aws s3 cp "$COMPRESSED_FILE" \
                "s3://${OSS_BUCKET}/backups/$(basename $COMPRESSED_FILE)" \
                --endpoint-url="$OSS_ENDPOINT" \
                --region=auto 2>/dev/null; then
                log_info "远程备份成功"
            else
                log_warn "远程备份失败，仅保留本地备份"
            fi
        else
            log_warn "未安装 AWS CLI，跳过远程备份"
        fi
    fi

    # 清理旧备份
    log_info "清理 ${RETENTION_DAYS} 天前的备份..."
    find "$BACKUP_DIR" -name "kami_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

    # 统计当前备份数量
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "kami_backup_*.sql.gz" | wc -l)
    log_info "当前保留备份数量: $BACKUP_COUNT"

    # 备份记录
    BACKUP_RECORD="${BACKUP_DIR}/backup_history.log"
    echo "$(date +'%Y-%m-%d %H:%M:%S') | SUCCESS | ${BACKUP_FILE}.gz | ${COMPRESSED_SIZE}" >> "$BACKUP_RECORD"

    log_info "备份完成！"

else
    log_error "数据库备份失败"

    # 记录失败
    BACKUP_RECORD="${BACKUP_DIR}/backup_history.log"
    echo "$(date +'%Y-%m-%d %H:%M:%S') | FAILED | N/A | N/A" >> "$BACKUP_RECORD"

    # 发送告警（如果配置了 webhook）
    if [ -n "$ALERT_WEBHOOK_URL" ]; then
        curl -X POST "$ALERT_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"数据库备份失败: $(date)\"}" \
            2>/dev/null || true
    fi

    exit 1
fi

# 验证备份完整性（可选）
log_info "验证备份完整性..."
if gzip -t "$COMPRESSED_FILE" 2>/dev/null; then
    log_info "备份文件完整性验证通过"
else
    log_error "备份文件可能已损坏！"
    exit 1
fi

log_info "所有备份任务完成"

exit 0
