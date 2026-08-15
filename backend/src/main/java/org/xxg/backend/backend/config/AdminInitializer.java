package org.xxg.backend.backend.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.xxg.backend.backend.entity.Admin;
import org.xxg.backend.backend.mapper.AdminMapper;

import jakarta.annotation.PostConstruct;

/**
 * 管理员账号初始化
 * 从环境变量读取管理员账号和密码
 */
@Configuration
@DependsOn("databaseInitializer")
public class AdminInitializer {

    @Autowired
    private AdminMapper adminMapper;

    @Value("${admin.username:admin}")
    private String adminUsername;

    @Value("${admin.password:admin123}")
    private String adminPassword;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @PostConstruct
    public void initAdmin() {
        try {
            // 检查管理员是否已存在
            Admin existingAdmin = adminMapper.findByUsername(adminUsername);

            if (existingAdmin == null) {
                // 创建新的管理员账号
                Admin admin = new Admin();
                admin.setUsername(adminUsername);
                admin.setPassword(passwordEncoder.encode(adminPassword));

                adminMapper.insertAdmin(admin);
                System.out.println("===========================================");
                System.out.println("✓ 管理员账号初始化成功");
                System.out.println("  用户名: " + adminUsername);
                System.out.println("===========================================");
            } else {
                // 管理员已存在，更新密码（如果环境变量有设置）
                String currentPassword = System.getenv("ADMIN_PASSWORD");
                if (currentPassword != null && !currentPassword.isEmpty()) {
                    existingAdmin.setPassword(passwordEncoder.encode(currentPassword));
                    adminMapper.updateAdmin(existingAdmin);
                    System.out.println("✓ 管理员密码已更新");
                } else {
                    System.out.println("✓ 管理员账号已存在: " + adminUsername);
                }
            }
        } catch (Exception e) {
            System.err.println("✗ 管理员初始化失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
