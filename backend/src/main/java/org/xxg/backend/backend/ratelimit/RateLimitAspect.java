package org.xxg.backend.backend.ratelimit;

import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.server.ResponseStatusException;
import org.xxg.backend.backend.annotation.RateLimit;

import java.lang.reflect.Method;

/**
 * 限流切面
 * 自动处理 @RateLimit 注解
 */
@Aspect
@Component
public class RateLimitAspect {

    private final RateLimiter rateLimiter;

    public RateLimitAspect(RateLimiter rateLimiter) {
        this.rateLimiter = rateLimiter;
    }

    @Around("@annotation(org.xxg.backend.backend.annotation.RateLimit)")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        RateLimit rateLimit = method.getAnnotation(RateLimit.class);

        if (rateLimit == null) {
            return joinPoint.proceed();
        }

        HttpServletRequest request = getRequest();
        if (request == null) {
            return joinPoint.proceed();
        }

        // 获取客户端IP
        String clientIp = getClientIp(request);

        // 白名单检查
        if (rateLimiter.isWhitelisted(clientIp)) {
            return joinPoint.proceed();
        }

        // 黑名单检查
        if (rateLimiter.isBlacklisted(clientIp)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "您已被封禁");
        }

        // 构造限流键
        String key = buildRateLimitKey(rateLimit.keyType(), request);

        // 执行限流检查
        boolean allowed;
        if (rateLimit.algorithm() == RateLimit.Algorithm.SLIDING_WINDOW) {
            allowed = rateLimiter.isAllowedSlidingWindow(
                key, rateLimit.maxRequests(), rateLimit.windowSeconds()
            );
        } else {
            allowed = rateLimiter.isAllowed(
                key, rateLimit.maxRequests(), rateLimit.windowSeconds()
            );
        }

        if (!allowed) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, rateLimit.message());
        }

        return joinPoint.proceed();
    }

    private String buildRateLimitKey(RateLimit.KeyType keyType, HttpServletRequest request) {
        switch (keyType) {
            case IP:
                return "ip:" + getClientIp(request);
            case USER:
                String username = request.getRemoteUser();
                return "user:" + (username != null ? username : getClientIp(request));
            case API_KEY:
                String apiKey = request.getHeader("X-API-Key");
                return "apikey:" + (apiKey != null ? apiKey : getClientIp(request));
            case CUSTOM:
                String customKey = request.getHeader("X-Rate-Limit-Key");
                return "custom:" + (customKey != null ? customKey : getClientIp(request));
            default:
                return "ip:" + getClientIp(request);
        }
    }

    private HttpServletRequest getRequest() {
        ServletRequestAttributes attributes =
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        return attributes != null ? attributes.getRequest() : null;
    }

    /**
     * 获取客户端真实IP
     * 考虑代理和负载均衡场景
     */
    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");

        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }

        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("Proxy-Client-IP");
        }

        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("WL-Proxy-Client-IP");
        }

        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_CLIENT_IP");
        }

        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_X_FORWARDED_FOR");
        }

        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }

        // X-Forwarded-For 可能包含多个IP，取第一个
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }

        return ip != null ? ip : "unknown";
    }
}
