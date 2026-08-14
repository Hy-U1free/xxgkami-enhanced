package org.xxg.backend.backend.ratelimit;

import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * Redis 分布式限流器
 * 使用令牌桶算法
 */
@Component
public class RateLimiter {

    private final RedisTemplate<String, Object> redisTemplate;

    public RateLimiter(RedisTemplate<String, Object> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /**
     * 检查是否允许请求
     *
     * @param key 限流键（如 IP、用户ID、API Key）
     * @param maxRequests 时间窗口内最大请求数
     * @param windowSeconds 时间窗口（秒）
     * @return true 允许，false 拒绝
     */
    public boolean isAllowed(String key, int maxRequests, int windowSeconds) {
        String redisKey = "rate_limit:" + key;

        try {
            Long count = redisTemplate.opsForValue().increment(redisKey);

            if (count == null) {
                return false;
            }

            // 第一次请求，设置过期时间
            if (count == 1) {
                redisTemplate.expire(redisKey, windowSeconds, TimeUnit.SECONDS);
            }

            return count <= maxRequests;
        } catch (Exception e) {
            // Redis 异常时放行，避免影响正常请求
            return true;
        }
    }

    /**
     * 滑动窗口限流（更精确）
     *
     * @param key 限流键
     * @param maxRequests 时间窗口内最大请求数
     * @param windowSeconds 时间窗口（秒）
     * @return true 允许，false 拒绝
     */
    public boolean isAllowedSlidingWindow(String key, int maxRequests, int windowSeconds) {
        String redisKey = "rate_limit:sliding:" + key;
        long now = System.currentTimeMillis();
        long windowStart = now - windowSeconds * 1000L;

        try {
            // 移除过期的请求记录
            redisTemplate.opsForZSet().removeRangeByScore(redisKey, 0, windowStart);

            // 获取当前窗口内的请求数
            Long count = redisTemplate.opsForZSet().zCard(redisKey);

            if (count != null && count >= maxRequests) {
                return false;
            }

            // 添加当前请求
            redisTemplate.opsForZSet().add(redisKey, String.valueOf(now), now);

            // 设置过期时间
            redisTemplate.expire(redisKey, windowSeconds + 1, TimeUnit.SECONDS);

            return true;
        } catch (Exception e) {
            return true;
        }
    }

    /**
     * 获取剩余配额
     */
    public int getRemainingQuota(String key, int maxRequests, int windowSeconds) {
        String redisKey = "rate_limit:" + key;

        try {
            Object value = redisTemplate.opsForValue().get(redisKey);
            if (value == null) {
                return maxRequests;
            }

            int used = Integer.parseInt(value.toString());
            return Math.max(0, maxRequests - used);
        } catch (Exception e) {
            return maxRequests;
        }
    }

    /**
     * 重置限流计数
     */
    public void reset(String key) {
        String redisKey = "rate_limit:" + key;
        redisTemplate.delete(redisKey);
    }

    /**
     * 黑名单检查
     */
    public boolean isBlacklisted(String ip) {
        String key = "blacklist:ip:" + ip;
        Boolean exists = redisTemplate.hasKey(key);
        return exists != null && exists;
    }

    /**
     * 添加到黑名单
     */
    public void addToBlacklist(String ip, long durationSeconds) {
        String key = "blacklist:ip:" + ip;
        redisTemplate.opsForValue().set(key, "1", durationSeconds, TimeUnit.SECONDS);
    }

    /**
     * 从黑名单移除
     */
    public void removeFromBlacklist(String ip) {
        String key = "blacklist:ip:" + ip;
        redisTemplate.delete(key);
    }

    /**
     * 白名单检查
     */
    public boolean isWhitelisted(String ip) {
        String key = "whitelist:ip:" + ip;
        Boolean exists = redisTemplate.hasKey(key);
        return exists != null && exists;
    }

    /**
     * 添加到白名单
     */
    public void addToWhitelist(String ip) {
        String key = "whitelist:ip:" + ip;
        redisTemplate.opsForValue().set(key, "1");
    }
}
