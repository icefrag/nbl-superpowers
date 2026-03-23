# 开发规范

> Java Spring Boot项目的编码规范、数据持久化规范、工具类使用规范等。

## Spring依赖注入规范 (NON-NEGOTIABLE)

- **推荐方式**: 使用Lombok的`@RequiredArgsConstructor`注解配合`final`字段实现构造器注入
- **禁止**: 使用`@Autowired`字段注入、使用`@Resource`字段注入
- **适用范围**: 所有Spring管理的Bean，包括Controller、Service、Manager、Job等
- **必选依赖**: 所有需要注入的依赖必须声明为`final`字段

```java
// 正确
@RestController
@RequiredArgsConstructor
public class UserController implements UserApi {
    private final UserService userService;
}

// 错误
@RestController
public class UserController {
    @Autowired
    private UserService userService;
}
```

## Lombok @Builder注解使用规范 (NON-NEGOTIABLE)

- **适用范围**: 所有实体对象类，包括Entity、DTO、Req、Resp、Query等
- **注解组合**: 使用@Builder时必须同时添加`@AllArgsConstructor`和`@NoArgsConstructor`
- **禁止**: 实体对象使用@Builder但不添加@AllArgsConstructor或不添加@NoArgsConstructor

## 数据持久化规范 (NON-NEGOTIABLE)

### ID生成规范

- **必须**: 所有表写入数据时，id字段必须使用`com.baomidou.mybatisplus.core.toolkit.IdWorker.getId()`进行设置
- **禁止**: 使用UUID、自增ID、时间戳等其他方式生成主键ID

```java
UserEntity entity = UserEntity.builder()
    .name("test")
    .build();
entity.setId(IdWorker.getId());  // 必须
userMapper.insert(entity);
```

### 数据库表设计规范 (NON-NEGOTIABLE)

所有数据库表必须包含以下基础字段：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，使用IdWorker.getId()生成，禁止自增 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |
| created_by | BIGINT | 创建人ID |
| updated_by | BIGINT | 更新人ID |
| is_deleted | TINYINT | 逻辑删除标识（0-未删除，1-已删除） |

**说明**：
- 上述基础字段由BaseEntity统一定义，业务表Entity继承BaseEntity即可
- 禁止在业务表Entity中重复定义上述字段
- MyBatis-Plus逻辑删除插件会自动处理is_deleted字段
- 所有字段不允许为空，必须设置默认值：字符串类型默认值为''，数字类型默认值为0

### Entity定义规范

- **必须**: 所有Entity实体类继承`com.guozhi.api.framework.model.entity.BaseEntity`
- **禁止**: 在子类Entity中重复定义id、createTime、updateTime、deleted字段
- **必须**: is_deleted字段必须添加`@TableLogic`注解，明确标识逻辑删除字段

### 更新操作规范

- **必须**: 执行按ID更新操作时，使用MyBatis-Plus提供的`updateById()`方法
- **必须**: 入参必须new一个新对象，禁止使用从数据库查询出来的Entity对象
- **必须**: 新创建的对象必须先设置ID，然后只设置需要更新的字段属性

```java
// 正确
UserEntity user = new UserEntity();
user.setId(userId);
user.setName("newName");
userMapper.updateById(user);

// 错误：使用查询出来的对象
UserEntity user = userMapper.selectById(userId);
user.setName("newName");
userMapper.updateById(user);
```

### 查询操作规范 (NON-NEGOTIABLE)

- **禁止**: 在Service层创建QueryWrapper、LambdaQueryWrapper等查询构造器
- **必须**: 所有查询操作在Mapper层使用`default`方法封装

```java
// Mapper层
public interface UserMapper extends BaseMapper<UserEntity> {
    default UserEntity selectByGzId(String gzId) {
        return selectOne(new LambdaQueryWrapper<UserEntity>()
            .eq(UserEntity::getGzId, gzId));
    }
}

// Service层 - 直接调用封装好的方法
public User getUserByGzId(String gzId) {
    return userMapper.selectByGzId(gzId);
}
```

### 逻辑删除规范

- MyBatis-Plus已全局启用逻辑删除插件，所有查询自动过滤已删除数据
- **禁止**: 查询时显式设置逻辑删除条件

## JSON操作规范

- **统一工具类**: `com.guozhi.api.framework.utils.JsonUtil`
- **禁止**: 直接使用Gson、Jackson、Fastjson等其他JSON库的API
- **对象转JSON字符串**: 使用`JsonUtil.toJsonString(Object)`方法
- **JSON字符串转对象**: 使用`JsonUtil.toObject(String, TypeReference)`方法

## EnumUtil工具类使用规范 (NON-NEGOTIABLE)

- **工具类路径**: `com.guozhi.api.framework.utils.EnumUtil`
- **适用范围**: 所有实现了`IEnum<T>`接口的枚举类
- **主要方法**:
  - `of()`: 根据code值获取枚举实例，返回Optional类型
  - `getDescByCode()`: 根据code值获取枚举的desc描述
  - `getCodeByDesc()`: 根据desc描述获取枚举的code值
- **禁止**: 枚举类内部提供静态工具方法，手动遍历枚举values()来查找对应的枚举实例

## 业务异常处理规范 (NON-NEGOTIABLE)

- **禁止**: 在代码中手动抛出RuntimeException及其子类
- **推荐方式一**: 使用WarnAssert进行条件断言，`WarnAssert.isTrue(boolean expression, String message)`
- **推荐方式二**: 使用BizException.wrap直接抛出异常，`BizException.wrap(BaseResponseCode code, String message)`
- **错误码选择**: 优先使用项目中已定义的、与当前业务场景对应的BaseResponseCode枚举值，如果没有统一使用`ClientResponseCode.BAD_REQUEST`

## Controller返回值规范

- **禁止**: 定义返回类型为`Response<XX>`、`Result<XX>`等包装类型
- **直接返回**: Controller方法直接返回业务数据对象
- **单个对象**: 直接定义为`XX`类型
- **集合对象**: 直接定义为`List<XX>`类型
- **分页对象**: 直接定义为`IPage<XX>`类型
- 全局异常处理器和响应包装器统一处理返回值封装

## 分页查询返回值规范

- **统一返回类型**: 所有分页查询接口必须返回`com.baomidou.mybatisplus.core.metadata.IPage<T>`类型
- **禁止**: 自定义分页对象如`PageResult<T>`、`PagedResponse<T>`等

## FeignClient接口规范

- **@FeignClient注解**: 必须添加`contextId`属性(使用接口类名作为值)，禁止使用`path`属性
- **@RequestMapping注解**: 必须在FeignClient接口上添加定义全局URI路径前缀
- **contextId配置**: 取值使用当前接口类的类名(不含包路径)
- **直接返回业务对象**: FeignClient接口方法直接返回业务对象类型，无需包装
- **禁止**: 使用TypedApiResponse包装，使用其他包装类型如`Response<XX>`

## @PathVariable禁止规范 (NON-NEGOTIABLE)

- **禁止**: 在Controller和FeignClient接口中使用@PathVariable注解获取路径参数
- **统一使用**: 所有参数传递必须使用@RequestParam注解，通过查询参数方式传递

## 日期时间格式规范 (NON-NEGOTIABLE)

- **统一使用Date类型**: 所有日期时间字段必须使用`java.util.Date`类型
- **禁止**: 使用String类型存储日期时间，使用LocalDateTime、LocalDate等其他时间类型
- **使用Jackson注解**: 通过`@JsonFormat`注解控制日期时间的序列化格式
- **pattern**: 必须设置为`yyyy-MM-dd HH:mm:ss`
- **timezone**: 必须设置为`GMT+8`

```java
@Schema(description = "创建时间", example = "2026-01-01 12:00:00")
@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
private Date createTime;
```

## Swagger注解规范 (NON-NEGOTIABLE)

- **api模块Swagger注解**:
  - 接口级别: `@Tag`注解描述模块
  - 方法级别: `@Operation`注解描述接口功能
  - 参数级别: `@Parameter`注解描述参数
  - Req/Resp/Query对象: `@Schema`注解描述字段
- **app模块Controller**: 不需要重复添加Swagger注解，通过实现api模块接口继承注解
- **禁止**:
  - 在Controller添加@RequestMapping注解
  - 使用`@ApiModel`和`@ApiModelProperty`等Swagger 2.x注解
  - 枚举类使用`@Schema`注解
- **@Schema注解属性**:
  - `description`: 必须填写
  - `example`: 建议填写
  - `requiredMode`: 根据JSR-303校验注解确定
  - 禁止使用已废弃的`required`属性

## Controller日志规范 (NON-NEGOTIABLE)

- **禁止**: Controller层方法内手动打印请求进入日志和请求完成日志
- **允许**: 异常处理时的调试日志、业务关键节点的日志、性能监控日志

## 事件发布规范 (NON-NEGOTIABLE)

- **统一发布方式**: 发布事件必须使用`EventUtil.publishEvent()`方法
- **禁止**: 使用`ApplicationContext.publishEvent()`或`ApplicationEventPublisher.publishEvent()`发布事件

## 类引用规范 (NON-NEGOTIABLE)

- **禁止**: 在方法参数、返回类型、变量声明等任何位置使用完整的包路径+类名
- **必须**: 所有使用的类必须通过import语句导入，然后直接使用类名

## Mapper层XML查询规范 (NON-NEGOTIABLE)

- **简单查询**: 使用MyBatis-Plus提供的内置方法
- **复杂查询**: 必须在XML文件中编写SQL，包括多表关联查询(JOIN)、复杂条件判断、动态SQL、分组查询聚合函数、子查询
- **XML文件位置**: `src/main/resources/mapper/`
- **禁止**: 在Service或Manager层拼接多表关联SQL，使用字符串拼接构建动态SQL

## Service层入参使用规范

- **Req直接使用**: Service层方法可以直接接收Controller传递的Req对象，无需转换为DTO
- **DTO使用场景**: DTO主要用于Service层之间的调用传递，ServiceA调用ServiceB时使用DTO作为参数

## 测试规范 (NON-NEGOTIABLE)

- **按需开发**: 单元测试和集成测试仅在用户需求中明确说明需要增加测试时才开发
- **禁止主动开发**: 如果用户在需求中没有明确说明需要增加单测，禁止主动开发单元测试或集成测试
- **需求确认依据**: 需求文档中明确提到需要编写测试、明确提到测试覆盖率要求、用户在需求沟通时明确表示需要测试代码
