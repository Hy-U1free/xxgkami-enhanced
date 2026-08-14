package org.xxg.backend.backend.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.regex.Pattern;

/**
 * SQL注入防护过滤器
 * 检测并阻止常见的SQL注入攻击
 */
@Component
public class SqlInjectionFilter implements Filter {

    // SQL注入关键字检测模式
    private static final Pattern[] SQL_INJECTION_PATTERNS = {
        Pattern.compile("('.+(or|and).+[=<>])|('.*or.*'.*=.*')", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(union.+(select|all))", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(exec(\\s|\\+)+(s|x)p\\w+)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(insert|update|delete|drop|create|alter).+(into|table|database)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(select.+from.+[\\w`]+)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(--|;|/\\*|\\*/|xp_|sp_|exec|execute|@@)", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(sleep|benchmark|waitfor)\\s*\\(", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(and|or)\\s+\\d+\\s*[=><]\\s*\\d+", Pattern.CASE_INSENSITIVE)
    };

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;

        // 包装请求，过滤参数
        SqlInjectionRequestWrapper wrappedRequest = new SqlInjectionRequestWrapper(httpRequest);

        chain.doFilter(wrappedRequest, response);
    }

    private static class SqlInjectionRequestWrapper extends HttpServletRequestWrapper {

        public SqlInjectionRequestWrapper(HttpServletRequest request) {
            super(request);
        }

        @Override
        public String getParameter(String name) {
            String value = super.getParameter(name);
            return cleanInput(value);
        }

        @Override
        public String[] getParameterValues(String name) {
            String[] values = super.getParameterValues(name);
            if (values == null) {
                return null;
            }

            String[] cleanedValues = new String[values.length];
            for (int i = 0; i < values.length; i++) {
                cleanedValues[i] = cleanInput(values[i]);
            }
            return cleanedValues;
        }

        @Override
        public String getHeader(String name) {
            String value = super.getHeader(name);
            return cleanInput(value);
        }

        private String cleanInput(String value) {
            if (value == null || value.isEmpty()) {
                return value;
            }

            // 检测SQL注入
            for (Pattern pattern : SQL_INJECTION_PATTERNS) {
                if (pattern.matcher(value).find()) {
                    // 记录可疑请求
                    System.err.println("Possible SQL injection detected: " + value);
                    // 返回清理后的值或抛出异常
                    return sanitize(value);
                }
            }

            return value;
        }

        private String sanitize(String value) {
            // 移除危险字符
            return value.replaceAll("[';\"\\-\\-/\\*\\*/]", "");
        }
    }
}
