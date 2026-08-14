-- 审计日志表
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NULL COMMENT '操作用户ID',
  `username` varchar(50) NULL COMMENT '操作用户名',
  `action` varchar(100) NOT NULL COMMENT '操作类型',
  `resource` varchar(255) NULL COMMENT '操作资源',
  `method` varchar(10) NULL COMMENT 'HTTP方法',
  `path` varchar(255) NULL COMMENT '请求路径',
  `ip` varchar(50) NULL COMMENT '客户端IP',
  `user_agent` varchar(500) NULL COMMENT '用户代理',
  `request_params` text NULL COMMENT '请求参数(脱敏)',
  `response_status` int NULL COMMENT '响应状态码',
  `error_message` text NULL COMMENT '错误信息',
  `execution_time` int NULL COMMENT '执行时间(ms)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  INDEX `idx_username` (`username`),
  INDEX `idx_action` (`action`),
  INDEX `idx_create_time` (`create_time`),
  INDEX `idx_ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='审计日志表';

-- IP黑名单表
DROP TABLE IF EXISTS `ip_blacklist`;
CREATE TABLE `ip_blacklist` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ip` varchar(50) NOT NULL COMMENT 'IP地址',
  `reason` varchar(255) NULL COMMENT '封禁原因',
  `expire_time` datetime NULL COMMENT '过期时间(NULL表示永久)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IP黑名单';

-- IP白名单表
DROP TABLE IF EXISTS `ip_whitelist`;
CREATE TABLE `ip_whitelist` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ip` varchar(50) NOT NULL COMMENT 'IP地址或CIDR',
  `description` varchar(255) NULL COMMENT '说明',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IP白名单';

-- 登录记录表
DROP TABLE IF EXISTS `login_logs`;
CREATE TABLE `login_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `ip` varchar(50) NOT NULL,
  `user_agent` varchar(500) NULL,
  `success` tinyint(1) NOT NULL COMMENT '是否成功',
  `fail_reason` varchar(255) NULL COMMENT '失败原因',
  `login_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_username` (`username`),
  INDEX `idx_ip` (`ip`),
  INDEX `idx_login_time` (`login_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录记录';
