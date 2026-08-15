CREATE TABLE IF NOT EXISTS admins (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME NULL,
    access_token VARCHAR(512) NULL,
    refresh_token VARCHAR(512) NULL,
    totp_secret VARCHAR(255) NULL,
    totp_enabled TINYINT(1) NOT NULL DEFAULT 0,
    email VARCHAR(100) NULL,
    UNIQUE KEY uk_admins_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS settings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    value TEXT NULL,
    UNIQUE KEY uk_settings_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NULL,
    password VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NULL,
    avatar VARCHAR(255) NULL,
    phone VARCHAR(20) NULL,
    status TINYINT(1) NOT NULL DEFAULT 1,
    email_verified TINYINT(1) NOT NULL DEFAULT 0,
    last_login_time DATETIME NULL,
    last_login_ip VARCHAR(50) NULL,
    login_count INT NOT NULL DEFAULT 0,
    register_ip VARCHAR(50) NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    access_token VARCHAR(512) NULL,
    refresh_token VARCHAR(512) NULL,
    UNIQUE KEY uk_users_username (username),
    UNIQUE KEY uk_users_email (email),
    INDEX idx_users_status (status),
    INDEX idx_users_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
