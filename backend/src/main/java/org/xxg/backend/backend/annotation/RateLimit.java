package org.xxg.backend.backend.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 限流注解
 * 用于接口方法上，自动限流
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RateLimit {

    /**
     * 限流键类型
     */
    KeyType keyType() default KeyType.IP;

    /**
     * 时间窗口内最大请求数
     */
    int maxRequests() default 60;

    /**
     * 时间窗口（秒）
     */
    int windowSeconds() default 60;

    /**
     * 限流算法
     */
    Algorithm algorithm() default Algorithm.FIXED_WINDOW;

    /**
     * 超限后的错误消息
     */
    String message() default "请求过于频繁，请稍后再试";

    enum KeyType {
        IP,           // 按IP限流
        USER,         // 按用户限流
        API_KEY,      // 按API Key限流
        CUSTOM        // 自定义键
    }

    enum Algorithm {
        FIXED_WINDOW,    // 固定窗口
        SLIDING_WINDOW   // 滑动窗口
    }
}
