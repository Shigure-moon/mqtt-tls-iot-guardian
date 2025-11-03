# 基于MQTT与TLS的物联网设备安全管理与入侵检测系统

## 项目概述
本项目旨在构建一个完整的物联网设备安全管理与入侵检测系统，通过MQTT协议和TLS加密确保设备通信安全，实现设备管理、数据采集、安全监控和入侵检测等功能。

## 系统架构
- 设备层：ESP8266物联网设备
- 通信层：MQTT+TLS安全传输
- 应用层：FastAPI后端+Vue3前端
- 存储层：PostgreSQL+Redis

## 主要功能
1. 设备管理与监控
2. 安全认证与加密通信
3. 入侵检测与告警
4. 数据采集与分析
5. 系统管理与配置

## 目录结构
```
lstdemo/
├── docs/          # 项目文档
├── backend/       # 后端服务
├── frontend/      # 前端界面
├── device/        # 设备端程序
└── deploy/        # 部署配置
```

## 技术栈
- 后端：Python 3.11+, FastAPI, SQLAlchemy, Paho-MQTT
- 前端：Vue 3, Element Plus, ECharts
- 数据库：PostgreSQL, Redis
- 通信：MQTT, TLS 1.3
- 部署：Docker, Nginx, RockyLinux 10

## 开发团队
- 项目负责人：[待定]
- 后端开发：[待定]
- 前端开发：[待定]
- 设备开发：[待定]
- 运维支持：[待定]

## 项目进度
项目预计周期：[待定]
详细进度请查看 `docs/PROJECT_PLAN.md`