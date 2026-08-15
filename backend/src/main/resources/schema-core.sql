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
