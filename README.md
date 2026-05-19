# 考勤打卡 APP

Spring Boot 3.3 + Flutter + Qwen AI 全栈考勤系统，支持 GPS 打卡与 AI 对话式打卡。

## 项目结构

```
ManagementSystem/
├── src/                  # 后端：Spring Boot 3.3
├── pom.xml
├── attendance_app/       # 前端：Flutter
│   ├── lib/
│   ├── pubspec.yaml
│   └── web/amap_picker.html   # 高德地图选点页面
└── README.md
```

## 环境要求

| 组件 | 版本 |
|------|------|
| Java | 17+ |
| Maven | 3.8+ |
| MySQL | 8.0+ |
| Flutter | 3.x+ |

---

## 启动指南

### 一、后端启动（Spring Boot）

#### 1. 准备 MySQL 数据库
```sql
CREATE DATABASE attendance_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 2. 配置环境变量

复制以下变量并填写真实值，在 IntelliJ 运行配置的 **Environment variables** 栏或系统环境中设置：

```bash
DB_HOST=localhost
DB_PORT=3306
DB_NAME=attendance_db
DB_USERNAME=root
DB_PASSWORD=your_db_password
DASHSCOPE_API_KEY=your_qwen_api_key   # 通义千问 API Key，见下方说明
JWT_SECRET=your-jwt-secret-at-least-32-chars  # 可随机生成
```

> **注意**：`DASHSCOPE_API_KEY` 不填时 AI 功能不可用，但其他考勤功能不受影响。

#### 3. 启动后端
```bash
cd ManagementSystem
./mvnw spring-boot:run
```
或在 IntelliJ IDEA 中运行 `AttendanceApplication`。

后端启动后监听：`http://localhost:8080/api/v1`

---

### 二、移动端启动（Flutter）

#### 1. 安装依赖
```bash
cd attendance_app
flutter pub get
```

#### 2. 配置后端地址

编辑 `attendance_app/lib/core/constants/api_constants.dart`：

```dart
// 真实设备调试时，替换为本机局域网 IP
static const String baseUrl = 'http://192.168.x.x:8080/api/v1';
```

#### 3. 配置高德地图（地图选点功能）

编辑 `attendance_app/lib/core/constants/api_constants.dart`，填写以下两项：

```dart
static const String amapWebKey = 'your_amap_js_api_key';
static const String amapSecurityCode = 'your_amap_security_code';
```

获取方式见下方 **[高德地图 API 配置](#高德地图-api-配置)**。

#### 4. 运行
```bash
# Chrome 浏览器（推荐用于开发）
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 第三方 API 配置

### 通义千问 API（Qwen AI）

AI 对话打卡功能依赖阿里云 DashScope 服务。

**获取 API Key：**

1. 访问 [https://dashscope.aliyun.com](https://dashscope.aliyun.com) 并登录阿里云账号
2. 进入控制台 → **API-KEY 管理** → 创建新 Key
3. 将 Key 设置为环境变量 `DASHSCOPE_API_KEY`

**IntelliJ 配置方式：**

打开运行配置 → **Environment variables** → 添加：
```
DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**验证：** 启动后在 App 内打开 AI 助手，发送任意消息，如能正常回复则配置成功。

---

### 高德地图 API 配置

办公地点管理页面的「地图选点」功能依赖高德地图 JS API 2.0（仅 Flutter Web 端可用）。

**获取 Key 与安全密钥：**

1. 登录 [高德开放平台控制台](https://console.amap.com/dev/key/app)
2. 点击「创建新应用」，服务平台选择 **Web端(JS API)**
3. 在应用详情中找到：
   - **API Key**：填入 `amapWebKey`
   - **JS安全密钥（安全验证码）**：填入 `amapSecurityCode`

> **注意**：2021 年后创建的应用默认开启安全模式，两项均需填写；缺少安全密钥时地图可加载但瓦片（底图）不会显示。

**配置文件位置：**

```
attendance_app/lib/core/constants/api_constants.dart
```

```dart
static const String amapWebKey = 'your_key_here';
static const String amapSecurityCode = 'your_security_code_here';
```

**域名白名单：** 在高德控制台将运行环境的域名（如 `localhost`）加入白名单，否则 Key 可能被拒绝。

---

## API 接口说明

| 模块 | 地址前缀 | 说明 |
|------|---------|------|
| 认证 | `/auth` | 登录、获取当前用户 |
| 员工管理 | `/employees` | CRUD，仅管理员 |
| 部门管理 | `/departments` | CRUD，仅管理员 |
| 办公地点 | `/office-locations` | CRUD，仅管理员 |
| 考勤打卡 | `/attendance` | 打卡、查询、日历 |
| 工作日历 | `/work-calendar` | 工作日调整 |
| 通知 | `/notifications` | 消息通知 |
| AI 对话 | `/ai/chat` | 通义千问智能打卡 |

## 默认账号

| 角色 | 账号 | 密码 |
|------|------|------|
| 管理员 | ADMIN001 | Admin@123 |
| 员工 | EMP20240001 | Test@123 |

## 主要功能

| 模块 | 说明 |
|------|------|
| 员工管理 | 新增、修改、查询、停用员工 |
| 办公地点 | 多地点管理，配置 GPS 打卡范围，支持地图选点 |
| 考勤打卡 | 传统点击式 + AI 对话式（GPS 校验） |
| 考勤日历 | 月视图，颜色区分正常/迟到/缺卡/补签 |
| 工作日历 | 管理员按员工或地点灵活调整工作日/休息日 |
| 补签管理 | 管理员代员工补录缺失打卡记录 |
| AI 助手 | 基于通义千问，自然语言打卡与考勤查询 |
| 打卡提醒 | 上下班前自动弹出 AI 提醒消息 |

### AI 助手使用方式
- 点击任意页面右下角 **AI 助手** 浮动按钮
- 输入自然语言，例如：
  - "帮我上班打卡"
  - "我今天打卡了吗？"
  - "查看这个月迟到了几次"
- AI 自动识别意图并调用对应功能完成操作

## 构建 JAR

```bash
mvn clean package -DskipTests
java -jar target/attendance-system-1.0.0.jar \
  --spring.datasource.password=xxx \
  --qwen.api-key=sk-xxx
```
