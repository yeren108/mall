# Mall 项目数据库表结构

## 项目概览

Mall 是一个完整的电商系统，共 **55 张表**，按业务模块划分为 5 大系统：

```
┌─────────────────────────────────────────────────────────────┐
│                     Mall 数据库架构                          │
├─────────────────────────────────────────────────────────────┤
│  PMS (商品) │ OMS (订单) │ SMS (营销) │ UMS (用户) │ CMS (内容) │
│   11张表   │   7张表    │   9张表   │   19张表  │   9张表   │
└─────────────────────────────────────────────────────────────┘
```

---

## 一、PMS - 商品管理 (11张表)

### 核心表结构

```
pms_product (商品表 - 核心)
├── pms_brand (品牌)
├── pms_product_category (分类)
├── pms_sku_stock (SKU库存)
├── pms_product_attribute (属性)
├── pms_product_attribute_value (属性值)
├── pms_product_attribute_category (属性分类)
├── pms_product_category_attribute_relation (分类属性关联)
├── pms_member_price (会员价格)
├── pms_product_ladder (阶梯价格)
├── pms_product_full_reduction (满减)
└── pms_feight_template (运费模板)
```

### pms_product - 商品表 (核心)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 商品ID (主键) |
| brand_id | BIGINT | → pms_brand 品牌ID |
| product_category_id | BIGINT | → pms_product_category 分类ID |
| feight_template_id | BIGINT | → pms_feight_template 运费模板ID |
| name | VARCHAR(200) | 商品名称 |
| pic | VARCHAR(500) | 商品主图 |
| product_sn | VARCHAR(64) | 货号 |
| delete_status | INT | 删除状态 (0未删除/1已删除) |
| publish_status | INT | 上架状态 (0下架/1上架) |
| new_status | INT | 新品状态 (0否/1是) |
| recommand_status | INT | 推荐状态 (0否/1是) |
| verify_status | INT | 审核状态 (0未审核/1已审核) |
| sort | INT | 排序 |
| sale | INT | 销量 |
| price | DECIMAL(10,2) | 商品价格 |
| promotion_price | DECIMAL(10,2) | 促销价格 |
| gift_growth | INT | 赠送成长值 |
| gift_point | INT | 赠送积分 |
| sub_title | VARCHAR(200) | 副标题 |
| original_price | DECIMAL(10,2) | 市场价 |
| stock | INT | 库存 |
| low_stock | INT | 库存预警值 |
| unit | VARCHAR(16) | 单位 |
| weight | DECIMAL(10,2) | 商品重量(克) |
| promotion_type | INT | 促销类型 (0无/1促销价/2会员价/3阶梯价/4满减/5限时购) |
| keywords | VARCHAR(200) | 关键词 |
| description | VARCHAR(1000) | 商品描述 |
| detail_html | LONGTEXT | 详情HTML |

**关联关系:**
- 多对一 → pms_brand (brand_id)
- 多对一 → pms_product_category (product_category_id)
- 一对多 → pms_sku_stock

### pms_product_category - 商品分类表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 分类ID |
| parent_id | BIGINT | 上级分类 (0表示一级) |
| name | VARCHAR(200) | 分类名称 |
| level | INT | 分类级别 (0一级/1二级) |
| product_count | INT | 商品数量 |
| nav_status | INT | 显示在导航栏 (0否/1是) |
| show_status | INT | 显示状态 (0否/1是) |
| sort | INT | 排序 |

**关联关系:** 自关联 (parent_id → id)

### pms_brand - 品牌表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 品牌ID |
| name | VARCHAR(100) | 品牌名称 |
| first_letter | VARCHAR(8) | 首字母 |
| sort | INT | 排序 |
| factory_status | INT | 品牌制造商 (0否/1是) |
| show_status | INT | 显示状态 |
| product_count | INT | 产品数量 |
| logo | VARCHAR(500) | 品牌logo |
| brand_story | VARCHAR(1000) | 品牌故事 |

### pms_sku_stock - SKU库存表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | SKU ID |
| product_id | BIGINT | → pms_product 商品ID |
| sku_code | VARCHAR(64) | SKU编码 |
| price | DECIMAL(10,2) | 价格 |
| stock | INT | 库存 |
| low_stock | INT | 预警库存 |
| pic | VARCHAR(500) | 展示图片 |
| sale | INT | 销量 |
| lock_stock | INT | 锁定库存 |
| sp_data | TEXT | 商品销售属性 |

### pms_product_attribute - 商品属性表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 属性ID |
| product_attribute_category_id | BIGINT | 属性分类ID |
| name | VARCHAR(200) | 属性名称 |
| select_type | INT | 选择类型 (0唯一/1单选/2多选) |
| input_type | INT | 录入方式 (0手工/1从列表) |
| filter_type | INT | 筛选样式 (0普通/1颜色) |
| search_type | INT | 检索类型 (0不需要/1关键字/2范围) |
| type | INT | 属性类型 (0规格/1参数) |

### pms_product_attribute_value - 商品属性值表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| product_id | BIGINT | 商品ID |
| product_attribute_id | BIGINT | 属性ID |
| value | VARCHAR(500) | 属性值 |

### pms_member_price - 会员价格表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| product_id | BIGINT | 商品ID |
| member_level_id | BIGINT | 会员等级ID |
| member_price | DECIMAL(10,2) | 会员价格 |

### pms_product_ladder - 商品阶梯价格表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| product_id | BIGINT | 商品ID |
| count | INT | 满足数量 |
| discount | DECIMAL(10,2) | 折扣 |
| price | DECIMAL(10,2) | 折后价格 |

### pms_product_full_reduction - 商品满减表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| product_id | BIGINT | 商品ID |
| full_price | DECIMAL(10,2) | 满减金额 |
| reduce_price | DECIMAL(10,2) | 减免金额 |

---

## 二、OMS - 订单管理 (7张表)

### 核心表结构

```
oms_order (订单表 - 核心)
├── oms_order_item (订单商品)
├── oms_cart_item (购物车)
├── oms_order_operate_history (操作历史)
├── oms_order_return_apply (退货申请)
├── oms_order_return_reason (退货原因)
└── oms_order_setting (订单设置)
```

### oms_order - 订单表 (核心)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 订单ID (主键) |
| member_id | BIGINT | → ums_member 会员ID |
| coupon_id | BIGINT | → sms_coupon 优惠券ID |
| order_sn | VARCHAR(64) | 订单编号 |
| create_time | DATETIME | 提交时间 |
| member_username | VARCHAR(64) | 用户账号 |
| total_amount | DECIMAL(10,2) | 订单总金额 |
| pay_amount | DECIMAL(10,2) | 应付金额 |
| freight_amount | DECIMAL(10,2) | 运费金额 |
| promotion_amount | DECIMAL(10,2) | 促销优化金额 |
| integration_amount | DECIMAL(10,2) | 积分抵扣金额 |
| coupon_amount | DECIMAL(10,2) | 优惠券抵扣金额 |
| discount_amount | DECIMAL(10,2) | 管理员折扣 |
| pay_type | INT | 支付方式 (0未付/1支付宝/2微信) |
| source_type | INT | 订单来源 (0PC/1APP) |
| status | INT | 订单状态 (0待付款/1待发货/2已发货/3已完成/4已关闭/5无效) |
| order_type | INT | 订单类型 (0正常/1秒杀) |
| delivery_company | VARCHAR(64) | 物流公司 |
| delivery_sn | VARCHAR(64) | 物流单号 |
| integration | INT | 可获得积分 |
| growth | INT | 可获得成长值 |
| receiver_name | VARCHAR(32) | 收货人姓名 |
| receiver_phone | VARCHAR(32) | 收货人电话 |
| receiver_province | VARCHAR(32) | 省份 |
| receiver_city | VARCHAR(32) | 城市 |
| receiver_region | VARCHAR(32) | 区 |
| receiver_detail_address | VARCHAR(200) | 详细地址 |
| note | TEXT | 订单备注 |
| confirm_status | INT | 确认收货状态 |
| delete_status | INT | 删除状态 |
| payment_time | DATETIME | 支付时间 |
| delivery_time | DATETIME | 发货时间 |
| receive_time | DATETIME | 收货时间 |
| comment_time | DATETIME | 评价时间 |

**关联关系:**
- 多对一 → ums_member (member_id)
- 多对一 → sms_coupon (coupon_id)
- 一对多 → oms_order_item

### oms_order_item - 订单商品表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| order_id | BIGINT | → oms_order 订单ID |
| product_id | BIGINT | → pms_product 商品ID |
| product_pic | VARCHAR(500) | 商品图片 |
| product_name | VARCHAR(200) | 商品名称 |
| product_brand | VARCHAR(200) | 商品品牌 |
| product_sn | VARCHAR(64) | 商品货号 |
| product_price | DECIMAL(10,2) | 销售价格 |
| product_quantity | INT | 购买数量 |
| product_category_id | BIGINT | 商品分类ID |
| real_amount | DECIMAL(10,2) | 商品实付金额 |
| product_attr | VARCHAR(500) | 销售属性 |

### oms_cart_item - 购物车表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| product_id | BIGINT | → pms_product 商品ID |
| product_sku_id | BIGINT | SKU ID |
| member_id | BIGINT | → ums_member 会员ID |
| quantity | INT | 购买数量 |
| price | DECIMAL(10,2) | 添加时价格 |
| product_pic | VARCHAR(500) | 商品主图 |
| product_name | VARCHAR(200) | 商品名称 |
| product_sub_title | VARCHAR(500) | 商品副标题 |
| product_sku_code | VARCHAR(64) | SKU条码 |
| create_date | DATETIME | 创建时间 |
| delete_status | INT | 是否删除 |

### oms_order_operate_history - 订单操作历史表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| order_id | BIGINT | 订单ID |
| operate_man | VARCHAR(100) | 操作人 |
| create_time | DATETIME | 操作时间 |
| order_status | INT | 订单状态 |
| note | VARCHAR(500) | 备注 |

### oms_order_return_apply - 订单退货申请表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| order_id | BIGINT | 订单ID |
| product_id | BIGINT | 退货商品ID |
| member_username | VARCHAR(64) | 会员用户名 |
| return_amount | DECIMAL(10,2) | 退货金额 |
| return_name | VARCHAR(100) | 退货人姓名 |
| return_phone | VARCHAR(100) | 退货人电话 |
| status | INT | 申请状态 (0待处理/1退货中/2已完成/3已拒绝) |
| handle_time | DATETIME | 处理时间 |
| product_pic | VARCHAR(500) | 商品图片 |
| product_name | VARCHAR(200) | 商品名称 |
| product_count | INT | 退货数量 |
| price | DECIMAL(10,2) | 商品单价 |
| reason | VARCHAR(200) | 退货原因 |

### oms_order_return_reason - 退货原因表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| name | VARCHAR(100) | 退货原因 |
| sort | INT | 排序 |
| status | INT | 状态 (0禁用/1启用) |

### oms_order_setting - 订单设置表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| comment_overtime | INT | 超时自动评价时间(天) |
| confirm_overtime | INT | 超时自动确认收货(天) |
| finish_overtime | INT | 完成后自动结束(天) |
| close_overtime | INT | 超时自动关闭(分钟) |

---

## 三、SMS - 营销管理 (9张表)

### 核心表结构

```
sms_coupon (优惠券 - 核心)
├── sms_coupon_history (使用历史)
├── sms_coupon_product_relation (关联商品)
└── sms_coupon_product_category_relation (关联分类)

sms_flash_promotion (限时购)
├── sms_flash_promotion_session (场次)
├── sms_flash_promotion_product_relation (商品关联)
└── sms_flash_promotion_log (通知记录)

首页内容:
├── sms_home_advertise (轮播广告)
├── sms_home_brand (推荐品牌)
├── sms_home_new_product (新鲜好物)
├── sms_home_recommend_product (人气推荐)
└── sms_home_recommend_subject (推荐专题)
```

### sms_coupon - 优惠券表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 优惠券ID |
| type | INT | 类型 (0全场赠券/1会员赠券/2购物赠券/3注册赠券) |
| name | VARCHAR(100) | 名称 |
| platform | INT | 使用平台 (0全部/1移动/2PC) |
| count | INT | 数量 |
| amount | DECIMAL(10,2) | 金额 |
| per_limit | INT | 每人限领张数 |
| min_point | DECIMAL(10,2) | 使用门槛 (0无门槛) |
| start_time | DATETIME | 开始时间 |
| end_time | DATETIME | 结束时间 |
| use_type | INT | 使用类型 (0全场通用/1指定分类/2指定商品) |
| publish_count | INT | 发行数量 |
| use_count | INT | 已使用数量 |
| receive_count | INT | 已领取数量 |
| code | VARCHAR(64) | 优惠码 |

### sms_coupon_history - 优惠券使用历史表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| coupon_id | BIGINT | → sms_coupon 优惠券ID |
| member_id | BIGINT | → ums_member 会员ID |
| coupon_code | VARCHAR(64) | 优惠码 |
| use_type | INT | 使用状态 (0未使用/1已使用/2已过期) |
| use_time | DATETIME | 使用时间 |
| order_id | BIGINT | → oms_order 订单ID |

### sms_flash_promotion - 限时购表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| title | VARCHAR(200) | 秒杀时间段名称 |
| start_date | DATE | 开始日期 |
| end_date | DATE | 结束日期 |
| status | INT | 上下线状态 |

### sms_flash_promotion_session - 限时购场次表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| name | VARCHAR(200) | 场次名称 |
| start_time | TIME | 开始时间 |
| end_time | TIME | 结束时间 |
| status | INT | 启用状态 |

### sms_flash_promotion_product_relation - 限时购商品关联表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| flash_promotion_id | BIGINT | 限时购ID |
| flash_promotion_session_id | BIGINT | 场次ID |
| product_id | BIGINT | → pms_product 商品ID |
| flash_promotion_price | DECIMAL(10,2) | 限时购价格 |
| flash_promotion_count | INT | 限时购数量 |
| flash_promotion_limit | INT | 每人限购数量 |

---

## 四、UMS - 用户管理 (19张表)

### 核心表结构

```
会员体系:
├── ums_member (会员表 - 核心)
├── ums_member_level (会员等级)
├── ums_member_receive_address (收货地址)
├── ums_member_login_log (登录日志)
├── ums_integration_change_history (积分历史)
├── ums_growth_change_history (成长值历史)
├── ums_member_tag (会员标签)
└── ums_member_task (会员任务)

后台权限体系 (RBAC):
├── ums_admin (后台用户 - 核心)
├── ums_role (角色)
├── ums_permission (权限)
├── ums_resource (资源)
├── ums_menu (菜单)
└── 关系表 (多对多关联)
    ├── ums_admin_role_relation
    ├── ums_role_permission_relation
    ├── ums_role_menu_relation
    └── ums_role_resource_relation
```

### ums_member - 会员表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 会员ID (主键) |
| member_level_id | BIGINT | → ums_member_level 等级ID |
| username | VARCHAR(64) | 用户名 (唯一) |
| password | VARCHAR(64) | 密码 |
| nickname | VARCHAR(64) | 昵称 |
| phone | VARCHAR(64) | 手机号 (唯一) |
| status | INT | 状态 (0禁用/1启用) |
| create_time | DATETIME | 注册时间 |
| icon | VARCHAR(500) | 头像 |
| gender | INT | 性别 (0未知/1男/2女) |
| birthday | DATE | 生日 |
| city | VARCHAR(64) | 所在城市 |
| integration | INT | 积分 |
| growth | INT | 成长值 |
| luckey_count | INT | 剩余抽奖次数 |

**关联关系:**
- 多对一 → ums_member_level (member_level_id)
- 一对多 → oms_order (member_id)
- 一对多 → oms_cart_item (member_id)

### ums_member_level - 会员等级表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| name | VARCHAR(100) | 等级名称 |
| growth_point | INT | 成长点 |
| default_status | INT | 是否默认等级 |
| free_freight_point | DECIMAL(10,2) | 免运费标准 |
| priviledge_free_freight | INT | 是否免邮费 |
| priviledge_sign_in | INT | 每次登录赠送积分 |
| priviledge_member_price | INT | 是否有会员价格特权 |

### ums_admin - 后台用户表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 管理员ID |
| username | VARCHAR(64) | 用户名 |
| password | VARCHAR(64) | 密码 |
| icon | VARCHAR(500) | 头像 |
| email | VARCHAR(100) | 邮箱 |
| nick_name | VARCHAR(100) | 昵称 |
| note | VARCHAR(500) | 备注信息 |
| create_time | DATETIME | 创建时间 |
| login_time | DATETIME | 最后登录时间 |
| status | INT | 帐号启用状态 |

**关联关系:**
- 多对多 → ums_role (通过 ums_admin_role_relation)

### ums_role - 角色表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 角色ID |
| name | VARCHAR(100) | 名称 |
| description | VARCHAR(500) | 描述 |
| admin_count | INT | 后台用户数量 |
| create_time | DATETIME | 创建时间 |
| status | INT | 启用状态 |
| sort | INT | 排序 |

**关联关系:**
- 多对多 → ums_admin (通过 ums_admin_role_relation)
- 多对多 → ums_permission (通过 ums_role_permission_relation)

### ums_permission - 权限表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 权限ID |
| pid | BIGINT | 父级权限id |
| name | VARCHAR(100) | 名称 |
| value | VARCHAR(200) | 权限值 |
| icon | VARCHAR(500) | 图标 |
| type | INT | 权限类型 (0目录/1菜单/2按钮) |
| uri | VARCHAR(200) | 前端资源路径 |
| status | INT | 启用状态 |
| sort | INT | 排序 |

### ums_member_receive_address - 会员收货地址表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| member_id | BIGINT | → ums_member 会员ID |
| name | VARCHAR(100) | 收货人名称 |
| phone_number | VARCHAR(64) | 电话号码 |
| default_status | INT | 是否默认地址 |
| post_code | VARCHAR(64) | 邮政编码 |
| province | VARCHAR(100) | 省份 |
| city | VARCHAR(100) | 城市 |
| region | VARCHAR(100) | 区 |
| detail_address | VARCHAR(500) | 详细地址 |

---

## 五、CMS - 内容管理 (9张表)

### 核心表结构

```
cms_subject (专题 - 核心)
├── cms_subject_category (专题分类)
├── cms_subject_product_relation (专题商品关联)
└── cms_subject_comment (专题评论)

cms_topic (话题)
├── cms_topic_category (话题分类)
└── cms_topic_comment (话题评论)

cms_help (帮助)
└── cms_help_category (帮助分类)
```

### cms_subject - 专题表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 专题ID |
| category_id | BIGINT | → cms_subject_category 分类ID |
| title | VARCHAR(200) | 专题标题 |
| pic | VARCHAR(500) | 专题主图 |
| product_count | INT | 关联产品数 |
| recommend_status | INT | 推荐状态 |
| create_time | DATETIME | 创建时间 |
| collect_count | INT | 收藏数 |
| read_count | INT | 阅读数 |
| comment_count | INT | 评论数 |
| show_status | INT | 显示状态 |
| content | TEXT | 专题内容 |

### cms_subject_category - 专题分类表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| name | VARCHAR(100) | 分类名称 |
| icon | VARCHAR(500) | 图标 |
| subject_count | INT | 专题数量 |
| show_status | INT | 显示状态 |
| sort | INT | 排序 |

### cms_subject_product_relation - 专题商品关系表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| subject_id | BIGINT | → cms_subject 专题ID |
| product_id | BIGINT | → pms_product 商品ID |

### cms_topic - 话题表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| category_id | BIGINT | → cms_topic_category 话题分类ID |
| name | VARCHAR(200) | 话题名称 |
| create_time | DATETIME | 创建时间 |
| attention_count | INT | 关注数 |
| product_count | INT | 关联产品数量 |

### cms_help - 帮助表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT |  |
| category_id | BIGINT | → cms_help_category 帮助分类ID |
| title | VARCHAR(200) | 标题 |
| icon | VARCHAR(500) | 图标 |
| show_status | INT | 显示状态 |
| create_time | DATETIME | 创建时间 |
| content | TEXT | 内容 |

---

## 六、模块间关联关系

### 核心业务流程关联

```
┌─────────────────────────────────────────────────────────────────┐
│                         业务关联关系                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ums_member (用户)                                             │
│       │                                                         │
│       ├──→ oms_order (下单) ──→ pms_product (商品)              │
│       │         │                                               │
│       │         └──→ sms_coupon (使用优惠券)                    │
│       │                                                         │
│       ├──→ oms_cart_item (购物车) ──→ pms_product              │
│       │                                                         │
│       └──→ cms_subject_comment (评论) ──→ cms_subject          │
│                                                                 │
│   pms_product (商品)                                            │
│       │                                                         │
│       ├──→ sms_coupon_product_relation (优惠券关联)             │
│       ├──→ cms_subject_product_relation (专题关联)              │
│       └──→ sms_flash_promotion_product_relation (限时购)        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 关键外键关系总结

| 从表 | 外键字段 | → 主表 |
|------|----------|--------|
| pms_product | brand_id | pms_brand |
| pms_product | product_category_id | pms_product_category |
| oms_order | member_id | ums_member |
| oms_order | coupon_id | sms_coupon |
| oms_order_item | order_id | oms_order |
| oms_order_item | product_id | pms_product |
| oms_cart_item | member_id | ums_member |
| oms_cart_item | product_id | pms_product |
| sms_coupon_history | coupon_id | sms_coupon |
| sms_coupon_history | member_id | ums_member |

---

## 七、数据库配置信息

| 配置项 | 值 |
|--------|-----|
| 数据库名 | mall |
| 字符集 | utf8 |
| 排序规则 | utf8_general_ci |
| 存储引擎 | InnoDB |
| SQL脚本位置 | mall/document/sql/mall.sql |

---

## 八、表数量统计

| 模块 | 表数量 |
|------|--------|
| PMS - 商品管理 | 11张 |
| OMS - 订单管理 | 7张 |
| SMS - 营销管理 | 9张 |
| UMS - 用户管理 | 19张 |
| CMS - 内容管理 | 9张 |
| **合计** | **55张** |

---

## 九、ORM 映射文件位置

```
mall-mbg/
├── src/main/java/com/macro/mall/
│   ├── model/          # 实体类 (55个)
│   └── mapper/         # Mapper接口
└── src/main/resources/com/macro/mall/
    └── mapper/         # MyBatis XML (55个)
```

---

*生成时间: 2026-01-14*
