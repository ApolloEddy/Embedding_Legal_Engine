# 法律案件分析系统 (Legal Case Analysis System)

> **Alpha 版本** — 本项目处于早期开发阶段，功能可能存在不完善之处。

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📖 项目介绍

本系统是一套基于 **语义向量匹配 (Semantic Embedding Matching)** 的法律案件分析工具，旨在通过 AI 技术辅助法律工作者快速从案情描述中提取关键事实要素，并智能匹配可能适用的罪名。

### 核心特性

- **离线优先**：核心分析功能完全离线运行，无需联网，保障数据安全。
- **AI 驱动**：集成阿里云 Qwen 大模型，实现智能事实提取和向量计算。
- **双程序架构**：维护与运行分离，确保系统稳定性和资产安全。
- **跨平台支持**：Windows 桌面端 + Android 移动端。

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        法律案件分析系统                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────┐         ┌───────────────────┐           │
│  │ Embedding Builder │         │   Legal Assist    │           │
│  │   (离线工具)       │   ──▶   │   (主运行程序)     │           │
│  └───────────────────┘         └───────────────────┘           │
│         │                              │                        │
│         │  ① 维护 YAML 基座            │  ④ 加载只读资产         │
│         │  ② 调用 LLM 计算 Embedding   │  ⑤ 用户输入案情         │
│         │  ③ 导出 .pak 包              │  ⑥ 本地向量匹配分析     │
│         │                              │                        │
│         ▼                              ▼                        │
│  ┌───────────────────────────────────────────────────┐         │
│  │              只读文件资产 (Assets)                  │         │
│  │  ┌─────────────────┐  ┌────────────────────────┐  │         │
│  │  │ legal_base.yaml │  │ v4-embedding-刑法.pak  │  │         │
│  │  │   (YAML 基座)   │  │   (Embedding 向量包)   │  │         │
│  │  └─────────────────┘  └────────────────────────┘  │         │
│  └───────────────────────────────────────────────────┘         │
│                                                                 │
│  ┌───────────────────────────────────────────────────┐         │
│  │                  Shared 库                         │         │
│  │  • 数据模型 (YamlBase, EmbeddingPackage, etc.)    │         │
│  │  • 工具类 (SimilarityCalculator, InputSanitizer)  │         │
│  │  • 校验器 (JsonSchemaValidator)                   │         │
│  └───────────────────────────────────────────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 目录结构

```
Embedding_Legal_Engine/
├── embedding_builder_tool/   # 离线工具（维护人员专用）
│   ├── lib/
│   │   ├── providers/        # 状态管理
│   │   ├── screens/          # UI 界面
│   │   └── services/         # Embedding 计算服务
│   └── pubspec.yaml
│
├── legal_assist/             # 主运行程序（终端用户）
│   ├── assets/               # 内置资产
│   │   ├── legal_base.yaml
│   │   └── v4-embedding-刑法.pak
│   ├── lib/
│   │   ├── engines/          # 本地分析引擎
│   │   ├── providers/        # 状态管理
│   │   ├── screens/          # UI 界面
│   │   └── services/         # LLM 提取 & 资产加载
│   └── pubspec.yaml
│
├── shared/                   # 共享库
│   └── lib/
│       ├── models/           # 数据模型
│       ├── utils/            # 工具类
│       └── validators/       # 校验器
│
├── assets/                   # 原始资产存放
│   ├── law_articles/         # 法律条文原文
│   └── embeddings/           # 已生成的 Embedding 包
│
└── docs/                     # 文档
```

---

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.10+
- Dart SDK 3.10+
- （可选）阿里云 DashScope API Key（用于 LLM 功能）

### 安装与运行

```bash
# 1. 克隆项目
git clone https://github.com/your-repo/Embedding_Legal_Engine.git
cd Embedding_Legal_Engine

# 2. 安装依赖
cd legal_assist
flutter pub get

# 3. 运行程序
flutter run -d windows   # Windows 桌面
flutter run -d android   # Android 设备
```

### 构建 APK

```bash
cd legal_assist
flutter build apk --release
# 输出位置：build/app/outputs/flutter-apk/app-release.apk
```

---

## 📚 详细使用方法

请参阅 [使用手册 (USER_MANUAL.md)](./USER_MANUAL.md)。

---

## 🔧 技术栈

| 组件 | 技术 |
|------|------|
| 前端框架 | Flutter 3.10+ (Material 3) |
| 状态管理 | Provider |
| LLM API | 阿里云 DashScope (Qwen) |
| Embedding | text-embedding-v4 (1024 维) |
| 持久化 | SharedPreferences |
| 向量计算 | 余弦相似度 (本地) |

---

## ⚠️ 已知限制 (Alpha 阶段)

- 仅包含刑法第341条（濒危野生动物保护）相关罪名。
- LLM 事实提取依赖网络连接（本地分析不需要）。
- 部分 Windows 插件可能需要手动配置。

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
