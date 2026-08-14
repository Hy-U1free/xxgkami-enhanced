#!/bin/bash

# xxgkami 数据库恢复脚本

set -e

# 配置
BACKUP_DIR="/app/backups"
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_USER="${MYSQL_USER:-kami}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-kami}"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 显示帮助
show_help() {
    echo -e "${BLUE}xxgkami 数据库恢复工具${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -f FILE    指定备份文件路径"
    echo "  -l         列出所有可用备份"
    echo "  -h         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -l                                    # 列出备份"
    echo "  $0 -f kami_backup_20261215_120000.sql.gz  # 从文件恢复"
    echo ""
}

# 列出备份
list_backups() {
    log_info "可用备份列表:"
    echo ""

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.sql.gz 2>/dev/null)" ]; then
        log_warn "未找到任何备份文件"
        return
    fi

    echo -e "${BLUE}序号  时间                     大小      文件名${NC}"
    echo "------------------------------------------------------------"

    i=1
    for backup in $(ls -t "$BACKUP_DIR"/*.sql.gz 2>/dev/null); do
        filename=$(basename "$backup")
        size=$(du -h "$backup" | cut -f1)
        timestamp=$(echo "$filename" | sed 's/kami_backup_\(.*\)\.sql\.gz/\1/')
        formatted_time=$(date -d "${timestamp:0:8} ${timestamp:9:2}:${timestamp:11:2}:${timestamp:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")

        echo -e "$i     $formatted_time     $size     $filename"
        i=$((i+1))
    done

    echo ""
}

# 恢复数据库
restore_database() {
    local backup_file=$1

    # 检查文件是否存在
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        exit 1
    fi

    log_info "备份文件: $(basename $backup_file)"
    log_info "文件大小: $(du -h $backup_file | cut -f1)"

    # 确认操作
    echo ""
    log_warn "⚠️  警告: 此操作将覆盖现有数据库！"
    echo -ne "${YELLOW}确认恢复？(yes/no): ${NC}"
    read -r confirmation

    if [ "$confirmation" != "yes" ]; then
        log_info "已取消恢复操作"
        exit 0
    fi

    # 再次确认
    echo -ne "${RED}再次确认？输入数据库名称 '$MYSQL_DATABASE' 以继续: ${NC}"
    read -r db_confirm

    if [ "$db_confirm" != "$MYSQL_DATABASE" ]; then
        log_error "数据库名称不匹配，已取消"
        exit 1
    fi

    # 创建恢复前备份
    log_info "创建恢复前备份..."
    PRESTORE_BACKUP="${BACKUP_DIR}/kami_pre_restore_$(date +%Y%m%d_%H%M%S).sql.gz"

    if mysqldump -h "$MYSQL_HOST" \
        -u "$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        --single-transaction \
        "$MYSQL_DATABASE" 2>/dev/null | gzip > "$PRESTORE_BACKUP"; then
        log_info "恢复前备份已保存: $(basename $PRESTORE_BACKUP)"
    else
        log_warn "恢复前备份失败，是否继续？(yes/no)"
        read -r continue_restore
        if [ "$continue_restore" != "yes" ]; then
            exit 1
        fi
    fi

    # 解压并恢复
    log_info "开始恢复数据库..."

    if [[ "$backup_file" == *.gz ]]; then
        # 压缩文件
        if gunzip -c "$backup_file" | mysql -h "$MYSQL_HOST" \
            -u "$MYSQL_USER" \
            -p"$MYSQL_PASSWORD" \
            "$MYSQL_DATABASE" 2>/dev/null; then
            log_info "✅ 数据库恢复成功！"
        else
            log_error "❌ 数据库恢复失败"
            log_info "尝试从恢复前备份回滚..."
            gunzip -c "$PRESTORE_BACKUP" | mysql -h "$MYSQL_HOST" \
                -u "$MYSQL_USER" \
                -p"$MYSQL_PASSWORD" \
                "$MYSQL_DATABASE" 2>/dev/null || log_error "回滚失败，请手动恢复"
            exit 1
        fi
    else
        # 未压缩文件
        if mysql -h "$MYSQL_HOST" \
            -u "$MYSQL_USER" \
            -p"$MYSQL_PASSWORD" \
            "$MYSQL_DATABASE" < "$backup_file" 2>/dev/null; then
            log_info "✅ 数据库恢复成功！"
        else
            log_error "❌ 数据库恢复失败"
            exit 1
        fi
    fi

    # 验证恢复
    log_info "验证数据库..."
    table_count=$(mysql -h "$MYSQL_HOST" \
        -u "$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$MYSQL_DATABASE'" \
        -sN 2>/dev/null)

    log_info "数据库表数量: $table_count"

    # 记录恢复操作
    RESTORE_RECORD="${BACKUP_DIR}/restore_history.log"
    echo "$(date +'%Y-%m-%d %H:%M:%S') | SUCCESS | $(basename $backup_file) | $table_count tables" >> "$RESTORE_RECORD"

    log_info "恢复操作完成！"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    while getopts "f:lh" opt; do
        case $opt in
            f)
                BACKUP_FILE="$OPTARG"

                # 如果是相对路径，添加备份目录前缀
                if [[ "$BACKUP_FILE" != /* ]]; then
                    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
                fi

                restore_database "$BACKUP_FILE"
                ;;
            l)
                list_backups
                ;;
            h)
                show_help
                ;;
            \?)
                log_error "无效选项: -$OPTARG"
                show_help
                exit 1
                ;;
        esac
    done
}

main "$@"
