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
│   └── SETUP.md          # 前端启动指南
└── README.md
```

## 环境要求

| 组件 | 版本 |
|------|------|
| Java | 17+ |
| Maven | 3.8+ |
| MySQL | 8.0+ |
| Flutter | 3.x+ |

## 启动指南

### 一、后端启动（Spring Boot）

#### 1. 准备 MySQL 数据库
```sql
CREATE DATABASE attendance_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 2. 配置环境变量
```bash
export DB_HOST=localhost
export DB_PORT=3306
export DB_NAME=attendance_db
export DB_USERNAME=root
export DB_PASSWORD=your_password
export DASHSCOPE_API_KEY=your_qwen_api_key   # 通义千问 API Key
export JWT_SECRET=your-jwt-secret-at-least-32-chars-long
```

#### 3. 获取通义千问 API Key
1. 访问 https://dashscope.aliyun.com
2. 注册/登录阿里云账号
3. 开通 DashScope 服务，创建 API Key
4. 将 Key 设置为 DASHSCOPE_API_KEY 环境变量

#### 4. 启动后端
```bash
cd ManagementSystem
./mvnw spring-boot:run
```
或在 IntelliJ IDEA 中运行 `AttendanceApplication`

后端启动后访问：http://localhost:8080/api/v1运行

### 二、移动端启动（Flutter）

#### 1. 安装 Flutter SDK
```bash
# macOS
brew install flutter
flutter doctor
```

#### 2. 安装依赖
```bash
cd attendance_app
flutter pub get
```

#### 3. 配置后端地址
编辑 `lib/core/constants/api_constants.dart`：
```dart
// 真实设备调试时，替换为本机局域网 IP
static const String baseUrl = 'http://192.168.x.x:8080/api/v1';
```

#### 4. 运行
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Chrome 浏览器预览
flutter run -d chrome
```

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
| 办公地点 | 多地点管理，配置 GPS 打卡范围 |
| 考勤打卡 | 传统点击式 + AI 对话式（GPS 校验） |
| 考勤表 | 日历视图，支持月视图与日期详情 |
| 工作日历 | 管理员灵活调整工作日/工作时间 |
| AI 对话 | 基于通义千问，自然语言打卡与查询 |

### 特色说明： AI 助手
- 点击首页右下角 **AI 助手** 浮动按钮
- 直接输入自然语言，如：
    - "帮我上班打卡"
    - "我今天打卡了吗？"
    - "查看这个月迟到了几次"
- AI 自动识别意图并调用对应工具完成操作

## 构建 JAR

```bash
mvn clean package -DskipTests
java -jar target/attendance-system-1.0.0.jar
```
