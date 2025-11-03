# IoT安全管理系统 - 前端

基于Vue 3 + TypeScript + Element Plus构建的物联网设备安全管理前端应用。

## 技术栈

- **框架**: Vue 3.4+
- **语言**: TypeScript
- **构建工具**: Vite 5.0+
- **UI框架**: Element Plus 2.5+
- **路由**: Vue Router 4.2+
- **状态管理**: Pinia 2.1+
- **HTTP客户端**: Axios 1.6+
- **图表**: ECharts 5.5+

## 快速开始

### 安装依赖

```bash
npm install
# 或
pnpm install
# 或
yarn install
```

### 开发模式

```bash
npm run dev
```

前端服务将运行在 `http://localhost:5173`

### 构建生产版本

```bash
npm run build
```

构建产物将输出到 `dist` 目录。

### 预览生产构建

```bash
npm run preview
```

## 默认账号

系统默认管理员账号：
- **用户名**: `admin`
- **密码**: `admin123`

> ⚠️ 首次使用前，请确保已运行后端初始化脚本创建管理员账号：
> ```bash
> cd ../backend
> python scripts/init_admin.py
> ```

## 项目结构

```
frontend/
├── src/
│   ├── assets/          # 静态资源
│   ├── components/      # 公共组件
│   ├── layout/          # 布局组件
│   ├── router/          # 路由配置
│   ├── stores/          # Pinia状态管理
│   ├── types/           # TypeScript类型定义
│   ├── utils/           # 工具函数
│   ├── views/           # 页面组件
│   │   ├── dashboard/   # 仪表盘
│   │   ├── devices/     # 设备管理
│   │   ├── login/       # 登录页面
│   │   ├── monitoring/  # 监控告警
│   │   └── security/    # 安全管理
│   ├── App.vue          # 根组件
│   └── main.ts          # 入口文件
├── index.html           # HTML模板
├── package.json         # 项目配置
├── vite.config.ts       # Vite配置
└── tsconfig.json        # TypeScript配置
```

## 环境变量

创建 `.env.development` 文件（已提供模板）：

```env
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

## 功能模块

### 已实现
- ✅ 用户登录/登出
- ✅ 路由守卫
- ✅ 基础布局（侧边栏、头部、主内容区）
- ✅ 仪表盘页面（基础框架）
- ✅ 设备列表页面
- ✅ 设备详情页面

### 开发中
- 🔄 设备添加/编辑功能
- 🔄 监控告警完整功能
- 🔄 安全管理完整功能
- 🔄 用户管理功能
- 🔄 实时数据推送（WebSocket）

## API对接

前端通过 `src/utils/request.ts` 封装了axios请求，自动添加JWT token。

所有API请求会自动添加 `Authorization: Bearer <token>` 头。

## 开发指南

### 添加新页面

1. 在 `src/views/` 下创建页面组件
2. 在 `src/router/index.ts` 中添加路由配置
3. 如需要，在菜单中添加导航项

### 状态管理

使用Pinia进行状态管理，参考 `src/stores/user.ts` 的实现。

### 样式规范

- 使用SCSS编写样式
- 遵循Element Plus的设计规范
- 使用CSS变量进行主题定制

## 浏览器支持

现代浏览器和最新版本的Chrome、Firefox、Safari、Edge。

## 许可证

MIT

