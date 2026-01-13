# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 提供在此代码库中工作的指导。

## 项目概述

**mall** 是一个完整的电商系统，包含后台管理和前台商城。基于 Spring Boot 2.7.5 + MyBatis 构建，采用分层单体架构，包含多个 Maven 模块。

**当前环境：**
- **master 分支**: Spring Boot 2.7 + JDK 8
- **dev-v3 分支**: Spring Boot 3.2 + JDK 17（如需使用新版本）

## 常用命令

### 构建与运行
```bash
# 构建整个项目（pom.xml 中默认跳过测试）
mvn clean package

# 构建特定模块
mvn clean package -pl mall-admin

# 运行后台管理系统（端口 8080）
cd mall-admin && mvn spring-boot:run

# 运行前台商城（端口 8085）
cd mall-portal && mvn spring-boot:run

# 运行搜索服务（端口 8081）
cd mall-search && mvn spring-boot:run
```

### 测试
```bash
# 运行所有测试
mvn test

# 运行特定模块的测试
mvn test -pl mall-admin

# 跳过测试进行构建
mvn clean package -DskipTests
```

### 数据库设置
```bash
# 导入完整数据库脚本
mysql -u root -p < document/sql/mall.sql

# 数据库名: mall
# application-dev.yml 中的实际凭据: root/yR@12345678
# 注意：不同环境可能使用不同密码，请检查配置文件
```

### 服务管理
```bash
# 启动 MySQL
brew services start mysql
mysql.server status

# 启动 Redis（当前配置密码: admin）
redis-cli -a admin ping
brew services restart redis  # 如需重启
```

## 架构概览

### 模块结构

```
mall-common/    - 公共工具类、配置、领域对象、Redis 服务
mall-mbg/      - MyBatis Generator（从数据库自动生成 Mapper 和 Model）
mall-security/ - Spring Security + JWT 认证模块
mall-admin/    - 后台管理 API（对应 mall-admin-web 前端）
mall-portal/   - 前台商城 API（对应 mall-app-web 前端）
mall-search/   - 基于 Elasticsearch 的商品搜索
mall-demo/     - 框架测试代码
```

### 分层架构模式

每个应用模块遵循以下结构：

```
controller/    - REST 端点（@RestController + @Api 标签）
service/       - 业务逻辑接口
  impl/        - Service 实现（@Service）
dao/           - 自定义 DAO（用于复杂查询）
dto/           - 数据传输对象（请求/响应）
bo/            - 业务对象（后台模块内部使用）
validator/     - 自定义验证注解
config/        - Spring 配置类
```

**mall-mbg** 生成（当数据库结构变更时运行 MyBatis Generator）：
```
mapper/        - MyBatis Mapper 接口（标准 CRUD 操作）
model/         - 数据库实体类及 Example 类（用于复杂查询）
```

### 领域组织（表前缀约定）

- **Pms** - 商品管理（商品、品牌、分类、SKU、库存）
- **Oms** - 订单管理（订单、购物车、退货、订单设置）
- **Sms** - 营销管理（优惠券、秒杀、首页内容）
- **Ums** - 用户管理（后台用户、会员、角色、权限、菜单）
- **Cms** - 内容管理（帮助、专题、话题、会员报告）

### API 响应模式

所有端点返回 `CommonResult<T>` 包装器：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { ... }
}
```

分页响应使用 `CommonPage<T>`，包含 `pageNum`、`pageSize`、`total`。

## 配置详情

### 数据库（application-dev.yml）
- URL: `jdbc:mysql://localhost:3306/mall`
- 实际凭据: root/yR@12345678（需手动配置）
- 连接池: Druid（initial: 5, min: 10, max: 20）
- 监控页面: http://localhost:8080/druid/ (druid/druid)
- **注意**: 如果连接失败，添加 URL 参数 `allowPublicKeyRetrieval=true`

### Redis（application-dev.yml）
- Host: localhost, Port: 6379, Database: 0
- **当前密码**: admin
- 用途: 管理员权限缓存、会员信息、验证码、订单锁
- 缓存键模式: `ums:admin:{id}`、`ums:resource:{id}`、`oms:cart:{id}`

### JWT（application-dev.yml）
- Header: `Authorization: Bearer <token>`
- 后台密钥: `mall-admin-secret`
- 前台密钥: `mall-portal-secret`
- 过期时间: 604800 秒（7 天）

### 应用端口
- mall-admin: 8080
- mall-portal: 8085
- mall-search: 8081

### 文件存储
- MinIO（默认）: http://localhost:9000
- 阿里云 OSS: 已配置但需要凭据

## 开发流程

### 添加新功能
1. **数据库**: 在 `document/sql/mall.sql` 中添加表
2. **生成代码**: 运行 MyBatis Generator（参考 `mall-mbg/src/main/resources/generatorConfig.xml`）
3. **创建 DTO**: 定义请求/响应对象
4. **创建 Controller**: 添加 API 端点并使用 Swagger 注解
5. **创建 Service**: 接口 + 实现类，编写业务逻辑
6. **创建 DAO**（如需要）: 用于 MBG 生成的 Mapper 无法覆盖的复杂查询

### MyBatis Generator
- 配置文件: `mall-mbg/src/main/resources/generatorConfig.xml`
- 生成内容: Model 类、Mapper 接口、XML 映射文件
- 数据库结构变更后需重新生成

### 安全与认证
- 公开 URL: 在 `application-dev.yml` 的 `secure.ignored.urls` 中配置白名单
- JWT token 在 Redis 中进行验证
- 管理员权限从数据库加载并缓存到 Redis
- 添加新端点时：如需公开访问，添加到白名单

### API 文档
- Swagger UI: http://localhost:8080/swagger-ui/
- 通过 `@Api` 和 `@ApiOperation` 注解自动生成

### API 测试
- Postman 集合位于 `document/postman/`

## 技术栈

- **核心框架**: Spring Boot 2.7.5, MyBatis 3.5.10, Spring Security + JWT
- **数据库**: MySQL 5.7, Druid 连接池, PageHelper 分页插件
- **缓存**: Redis 7.0
- **搜索**: Elasticsearch 7.17.3
- **消息队列**: RabbitMQ 3.10.5
- **NoSQL**: MongoDB 5.0
- **文件存储**: MinIO 8.4.5, 阿里云 OSS
- **工具库**: Hutool 5.8.9, Lombok
- **日志**: Logback + Logstash

## 重要约定

### 包结构
- 基础包名: `com.macro.mall`
- 前台扫描: `@SpringBootApplication(scanBasePackages = "com.macro.mall")`

### 命名规范
- Controller: `XxxController` + `@Api(tags = "...")`
- Service: 接口 `XxxService` + 实现 `XxxServiceImpl`
- DAO: 自定义 DAO 在 `dao/`，MBG 生成在 `mapper/`
- DTO: API 边界的请求/响应对象

### 缓存键
- 用户信息: `ums:admin:{adminId}`
- 资源权限: `ums:resource:{resourceId}`
- 验证码: `ums:authCode:{telephone}:{code}`
- 购物车: `oms:cart:{memberId}`

## 前端项目（独立仓库）

- **mall-admin-web**: Vue + Element UI 后台管理前端
  - 运行端口: 8091
  - 使用 Vue CLI + webpack

- **mall-app-web**: Vue + uni-app 移动端商城
  - H5 端口: 8060
  - 使用 HBuilderX 开发（推荐）
  - 支持多平台：H5、微信小程序、APP

## 跨平台部署（mall-app-web）

### H5 端
- 配置文件: `manifest.json` -> `h5`
- 开发端口: 8060
- API 配置: `utils/appConfig.js`

### 微信小程序
- 需要在 `manifest.json` 中配置 `appid`
- 需要在微信公众平台配置服务器域名
- 搜索功能使用原生 `titleNView` 配置

### APP 端
- 需要准备应用图标、启动页
- 需要申请证书和 appid
- 支持iOS和Android

### 条件编译示例
```vue
<!-- #ifdef H5 -->
<H5专属内容>
<!-- #endif -->

<!-- #ifdef MP-WEIXIN -->
<小程序专属内容>
<!-- #endif -->

<!-- #ifndef MP -->
<非小程序平台显示>
<!-- #endif -->
```

## 测试账号

### 后台管理系统
| 用户名 | 密码 | 说明 |
|--------|------|------|
| admin | 123456 | 超级管理员 |
| test | 123456 | 测试管理员 |

### 前台商城
| 用户名 | 密码 | 说明 |
|--------|------|------|
| test | 123456 | 测试用户 |
| windy | 123456 | 测试用户 |
| zhengsan | 123456 | 测试用户 |

**注意**: 所有用户密码使用 BCrypt 加密存储

## 常见问题与故障排查

### 数据库连接问题
**错误**: `Public Key Retrieval is not allowed`
**解决**: 在 JDBC URL 中添加参数 `allowPublicKeyRetrieval=true`

```yaml
url: jdbc:mysql://localhost:3306/mall?...&allowPublicKeyRetrieval=true
```

### Redis 连接问题
**错误**: `NOAUTH Authentication required`
**解决**: 检查 Redis 密码配置，确保密码正确

```yaml
spring:
  redis:
    password: admin  # 确认密码正确
```

### uni-app H5 搜索框不显示
**原因**: H5 端对 `titleNView` 的搜索框支持有限
**解决**: 添加自定义搜索框组件，使用条件编译

```vue
<!-- #ifdef H5 -->
<view class="search-bar">
  <view class="search-input" @click="goToSearch">
    <text>🔍 搜索商品</text>
  </view>
</view>
<!-- #endif -->
```

### 秒杀专区不显示
**原因**: 秒杀活动时间过期
**解决**: 更新 `sms_flash_promotion` 表的活动时间

```sql
UPDATE sms_flash_promotion
SET start_date='2025-01-01', end_date='2027-12-31'
WHERE id=14;
```

### uni-app SCSS 编译错误
**错误**: `SassError: Undefined variable` 或 `expected selector`
**原因**: 从 node-sass 迁移到 dart-sass 的兼容性问题

**解决**:
1. 添加缺失的变量到 `uni.scss`
2. 将 `/deep/` 选择器改为 `::v-deep`
3. 或在 `manifest.json` 中配置使用 node-sass

### API 参数问题
**错误**: `HTTP 400 - productCategoryId=undefined`
**原因**: 前端传递了 undefined/null 参数
**解决**: 在发送请求前清理空参数

```javascript
const cleanParams = {};
for (let key in params) {
  if (params[key] !== null && params[key] !== undefined) {
    cleanParams[key] = params[key];
  }
}
```

## 维护建议

### 定期检查
1. 秒杀活动时间是否有效
2. 数据库连接配置是否正确
3. Redis 密码是否与配置一致
4. 证书和密钥是否即将过期

### 性能优化
1. 定期清理 Redis 缓存
2. 监控 Druid 连接池状态
3. 检查慢查询日志
4. 定期备份数据库

### 安全建议
1. 定期更新依赖版本
2. 使用强密码策略
3. 启用 HTTPS（生产环境）
4. 定期检查日志异常

## 项目文档

- 完整项目文档: [https://www.macrozheng.com](https://www.macrozheng.com)
- README 中包含详细的功能模块图和架构图
- 学习教程: [《mall学习教程》](https://www.macrozheng.com)
