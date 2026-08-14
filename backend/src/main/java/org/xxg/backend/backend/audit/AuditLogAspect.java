package org.xxg.backend.backend.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.xxg.backend.backend.annotation.AuditLog;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/**
 * 审计日志切面
 * 自动记录标记了 @AuditLog 的方法调用
 */
@Aspect
@Component
public class AuditLogAspect {

    private static final Logger logger = LoggerFactory.getLogger(AuditLogAspect.class);

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public AuditLogAspect(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
    }

    @Around("@annotation(org.xxg.backend.backend.annotation.AuditLog)")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();

        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        AuditLog auditLog = method.getAnnotation(AuditLog.class);

        HttpServletRequest request = getRequest();
        String username = getUsername(request);
        String ip = getClientIp(request);
        String userAgent = request != null ? request.getHeader("User-Agent") : null;
        String path = request != null ? request.getRequestURI() : null;
        String httpMethod = request != null ? request.getMethod() : null;

        Object result = null;
        Throwable exception = null;
        int responseStatus = 200;

        try {
            result = joinPoint.proceed();
            return result;
        } catch (Throwable e) {
            exception = e;
            responseStatus = 500;
            throw e;
        } finally {
            long executionTime = System.currentTimeMillis() - startTime;

            // 异步记录日志
            recordAuditLog(
                username,
                auditLog.action(),
                auditLog.resource(),
                httpMethod,
                path,
                ip,
                userAgent,
                auditLog.logParams() ? getRequestParams(joinPoint) : null,
                responseStatus,
                exception != null ? exception.getMessage() : null,
                executionTime
            );
        }
    }

    @Async
    private void recordAuditLog(
        String username,
        String action,
        String resource,
        String method,
        String path,
        String ip,
        String userAgent,
        String requestParams,
        int responseStatus,
        String errorMessage,
        long executionTime
    ) {
        try {
            String sql = "INSERT INTO audit_logs (username, action, resource, method, path, ip, " +
                        "user_agent, request_params, response_status, error_message, execution_time) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            jdbcTemplate.update(sql,
                username,
                action,
                resource,
                method,
                path,
                ip,
                truncate(userAgent, 500),
                truncate(maskSensitiveData(requestParams), 5000),
                responseStatus,
                truncate(errorMessage, 1000),
                executionTime
            );
        } catch (Exception e) {
            logger.error("Failed to record audit log", e);
        }
    }

    private HttpServletRequest getRequest() {
        ServletRequestAttributes attributes =
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        return attributes != null ? attributes.getRequest() : null;
    }

    private String getUsername(HttpServletRequest request) {
        if (request == null) {
            return "system";
        }

        String username = request.getRemoteUser();
        if (username == null) {
            username = (String) request.getAttribute("username");
        }

        return username != null ? username : "anonymous";
    }

    private String getClientIp(HttpServletRequest request) {
        if (request == null) {
            return "unknown";
        }

        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }

        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }

        return ip != null ? ip : "unknown";
    }

    private String getRequestParams(ProceedingJoinPoint joinPoint) {
        try {
            Object[] args = joinPoint.getArgs();
            if (args == null || args.length == 0) {
                return null;
            }

            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            String[] parameterNames = signature.getParameterNames();

            Map<String, Object> params = new HashMap<>();
            for (int i = 0; i < args.length; i++) {
                if (args[i] != null && !(args[i] instanceof HttpServletRequest)) {
                    String paramName = parameterNames != null && i < parameterNames.length
                        ? parameterNames[i]
                        : "arg" + i;
                    params.put(paramName, args[i]);
                }
            }

            return objectMapper.writeValueAsString(params);
        } catch (Exception e) {
            logger.error("Failed to serialize request params", e);
            return null;
        }
    }

    /**
     * 脱敏敏感数据
     */
    private String maskSensitiveData(String data) {
        if (data == null) {
            return null;
        }

        // 脱敏密码字段
        data = data.replaceAll("\"password\"\\s*:\\s*\"[^\"]*\"", "\"password\":\"***\"");
        data = data.replaceAll("\"oldPassword\"\\s*:\\s*\"[^\"]*\"", "\"oldPassword\":\"***\"");
        data = data.replaceAll("\"newPassword\"\\s*:\\s*\"[^\"]*\"", "\"newPassword\":\"***\"");

        // 脱敏API密钥
        data = data.replaceAll("\"apiKey\"\\s*:\\s*\"[^\"]*\"", "\"apiKey\":\"***\"");
        data = data.replaceAll("\"api_key\"\\s*:\\s*\"[^\"]*\"", "\"api_key\":\"***\"");

        // 脱敏token
        data = data.replaceAll("\"token\"\\s*:\\s*\"[^\"]*\"", "\"token\":\"***\"");
        data = data.replaceAll("\"accessToken\"\\s*:\\s*\"[^\"]*\"", "\"accessToken\":\"***\"");
        data = data.replaceAll("\"refreshToken\"\\s*:\\s*\"[^\"]*\"", "\"refreshToken\":\"***\"");

        return data;
    }

    private String truncate(String str, int maxLength) {
        if (str == null) {
            return null;
        }
        return str.length() > maxLength ? str.substring(0, maxLength) : str;
    }
}
