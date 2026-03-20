---
name: springboot-security
description: Spring Security最佳实践，涵盖认证/授权、输入验证、CSRF、密钥管理、安全头、限流和依赖安全，用于Java Spring Boot服务。
---

# Spring Boot安全审查

在添加认证、处理输入、创建端点或处理密钥时使用。

## 激活时机

- 添加认证（JWT、OAuth2、基于会话）
- 实现授权（@PreAuthorize、基于角色的访问控制）
- 验证用户输入（Bean Validation、自定义验证器）
- 配置CORS、CSRF或安全头
- 管理密钥（Vault、环境变量）
- 添加限流或暴力破解防护
- 扫描依赖项的CVE漏洞

## 认证

- 优先使用无状态的JWT或带撤销列表的不透明令牌
- 会话使用 `httpOnly`、`Secure`、`SameSite=Strict` 的Cookie
- 使用 `OncePerRequestFilter` 或资源服务器验证令牌

```java
@Component
public class JwtAuthFilter extends OncePerRequestFilter {
  private final JwtService jwtService;

  public JwtAuthFilter(JwtService jwtService) {
    this.jwtService = jwtService;
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String header = request.getHeader(HttpHeaders.AUTHORIZATION);
    if (header != null && header.startsWith("Bearer ")) {
      String token = header.substring(7);
      Authentication auth = jwtService.authenticate(token);
      SecurityContextHolder.getContext().setAuthentication(auth);
    }
    chain.doFilter(request, response);
  }
}
```

## 授权

- 启用方法安全：`@EnableMethodSecurity`
- 使用 `@PreAuthorize("hasRole('ADMIN')")` 或 `@PreAuthorize("@authz.canEdit(#id)")`
- 默认拒绝；仅暴露必要的范围

```java
@RestController
@RequestMapping("/api/admin")
public class AdminController {

  @PreAuthorize("hasRole('ADMIN')")
  @GetMapping("/users")
  public List<UserDto> listUsers() {
    return userService.findAll();
  }

  @PreAuthorize("@authz.isOwner(#id, authentication)")
  @DeleteMapping("/users/{id}")
  public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
    userService.delete(id);
    return ResponseEntity.noContent().build();
  }
}
```

## 输入验证

- 在Controller上使用Bean Validation的 `@Valid`
- 在DTO上应用约束：`@NotBlank`、`@Email`、`@Size`、自定义验证器
- 渲染前使用白名单消毒任何HTML

```java
// 错误：无验证
@PostMapping("/users")
public User createUser(@RequestBody UserDto dto) {
  return userService.create(dto);
}

// 正确：验证DTO
public record CreateUserDto(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email String email,
    @NotNull @Min(0) @Max(150) Integer age
) {}

@PostMapping("/users")
public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserDto dto) {
  return ResponseEntity.status(HttpStatus.CREATED)
      .body(userService.create(dto));
}
```

## SQL注入防护

- 使用Spring Data Repository或参数化查询
- 原生查询使用 `:param` 绑定；永远不要拼接字符串

```java
// 错误：原生查询中的字符串拼接
@Query(value = "SELECT * FROM users WHERE name = '" + name + "'", nativeQuery = true)

// 正确：参数化原生查询
@Query(value = "SELECT * FROM users WHERE name = :name", nativeQuery = true)
List<User> findByName(@Param("name") String name);

// 正确：Spring Data派生查询（自动参数化）
List<User> findByEmailAndActiveTrue(String email);
```

## 密码加密

- 始终使用BCrypt或Argon2哈希密码 —— 永远不要存储明文
- 使用 `PasswordEncoder` Bean，不要手动哈希

```java
@Bean
public PasswordEncoder passwordEncoder() {
  return new BCryptPasswordEncoder(12); // 代价因子12
}

// 在Service中
public User register(CreateUserDto dto) {
  String hashedPassword = passwordEncoder.encode(dto.password());
  return userRepository.save(new User(dto.email(), hashedPassword));
}
```

## CSRF防护

- 浏览器会话应用：保持CSRF启用；在表单/请求头中包含令牌
- 纯Bearer令牌API：禁用CSRF，依赖无状态认证

```java
http
  .csrf(csrf -> csrf.disable())
  .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
```

## 密钥管理

- 源代码中不放密钥；从环境变量或Vault加载
- `application.yml` 中不放凭据；使用占位符
- 定期轮换令牌和数据库凭据

```yaml
# 错误：在application.yml中硬编码
spring:
  datasource:
    password: mySecretPassword123

# 正确：环境变量占位符
spring:
  datasource:
    password: ${DB_PASSWORD}

# 正确：Spring Cloud Vault集成
spring:
  cloud:
    vault:
      uri: https://vault.example.com
      token: ${VAULT_TOKEN}
```

## 安全头

```java
http
  .headers(headers -> headers
    .contentSecurityPolicy(csp -> csp
      .policyDirectives("default-src 'self'"))
    .frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin)
    .xssProtection(Customizer.withDefaults())
    .referrerPolicy(rp -> rp.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER)));
```

## CORS配置

- 在安全过滤器层面配置CORS，而非每个Controller
- 限制允许的来源 —— 生产环境永远不要使用 `*`

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
  CorsConfiguration config = new CorsConfiguration();
  config.setAllowedOrigins(List.of("https://app.example.com"));
  config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
  config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
  config.setAllowCredentials(true);
  config.setMaxAge(3600L);

  UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
  source.registerCorsConfiguration("/api/**", config);
  return source;
}

// 在SecurityFilterChain中：
http.cors(cors -> cors.configurationSource(corsConfigurationSource()));
```

## 限流

- 在高消耗端点上使用Bucket4j或网关级别的限制
- 记录并告警突发流量；返回429并附带重试提示

```java
// 使用Bucket4j进行端点限流
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  private Bucket createBucket() {
    return Bucket.builder()
        .addLimit(Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1))))
        .build();
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String clientIp = request.getRemoteAddr();
    Bucket bucket = buckets.computeIfAbsent(clientIp, k -> createBucket());

    if (bucket.tryConsume(1)) {
      chain.doFilter(request, response);
    } else {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
      response.getWriter().write("{\"error\": \"Rate limit exceeded\"}");
    }
  }
}
```

## 依赖安全

- 在CI中运行OWASP Dependency Check / Snyk
- 保持Spring Boot和Spring Security在支持版本上
- 发现已知CVE时构建失败

## 日志与PII

- 永远不要记录密钥、令牌、密码或完整的PAN数据
- 脱敏敏感字段；使用结构化JSON日志

## 文件上传

- 验证大小、内容类型和扩展名
- 存储在Web根目录之外；必要时扫描

## 发布前检查清单

- [ ] 认证令牌已正确验证和过期
- [ ] 每个敏感路径都有授权守卫
- [ ] 所有输入已验证和消毒
- [ ] 无字符串拼接的SQL
- [ ] CSRF策略与应用类型匹配
- [ ] 密钥已外部化；无提交
- [ ] 安全头已配置
- [ ] API已限流
- [ ] 依赖已扫描且为最新版本
- [ ] 日志无敏感数据

**记住**：默认拒绝、验证输入、最小权限、配置优先的安全策略。
