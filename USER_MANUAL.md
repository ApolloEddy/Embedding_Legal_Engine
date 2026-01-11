# Legal Assist 用户手册

[![Version](https://img.shields.io/badge/Version-Alpha%200.2.0-blue)](https://github.com/ApolloEddy/Embedding_Legal_Engine/releases)
[![License](https://img.shields.io/badge/License-Apache%202.0-green)](LICENSE)

**更新日期**: 2026-01-11

---

## 目录

1. [快速开始](#快速开始)
2. [Windows 桌面端](#windows-桌面端)
3. [Android 移动端](#android-移动端)
4. [功能详解](#功能详解)
5. [Embedding Builder Tool (高级)](#embedding-builder-tool-高级)
6. [常见问题](#常见问题)

---

## 快速开始

### 系统要求

| 平台 | 最低要求 |
| :--- | :--- |
| Windows | Windows 10 64-bit |
| Android | Android 8.0+ (API 26) |
| Flutter | 3.10.4+ |

### 运行方式

```bash
# Windows 桌面端
cd legal_assist
flutter run -d windows

# Android 设备
flutter run -d <设备ID>

# 构建 Android APK
flutter build apk --release
```

---

## Windows 桌面端

### 首次启动

1. **自动加载配置**
   - 程序启动时自动读取 `secrets.yaml` 中的 API Key
   - 自动加载内置法律资产（YAML + Embedding 包）

2. **手动配置（如需）**
   - 打开「设置」页面
   - 配置 LLM API Key（阿里云 DashScope）
   - 选择自定义的 YAML 基座或 Embedding 包

### 分析案件

#### 步骤 1：输入案情

在「案情输入」页面的文本框中输入案件描述：

```
嫌疑人刘某通过网络渠道联系上游卖家，非法收购穿山甲鳞片并准备倒卖牟利，
数量较大，查获时相关物品仍存放在其住所内，
经鉴定为国家一级保护动物制品，主观上具有明显牟利目的。
```

#### 步骤 2：提取事实

点击「提取事实」按钮：

- 系统调用 LLM 自动识别法律要素
- 为每个要素计算语义向量
- 显示提取结果预览

> ⚠️ 此步骤需要网络连接和有效的 API Key

#### 步骤 3：分析罪名

点击「分析罪名」按钮：

- 执行 100% 本地分析（无需网络）
- 自动完成 L1→L2→L3 三层分析
- 跳转至结果页面

### 查看结果

#### 列表视图（默认）

展开任意罪名卡片，查看：

- **L1 核心要件**：命中/缺失/不确定的要素
- **L2 阻却事由**：是否存在排除情形
- **L3 量刑情节**：加重/减轻因素
- **最终结论**：构成程度或不构成原因

#### 思维导图视图

点击右上角「导图」按钮切换：

- 可视化展示分析层级结构
- 支持缩放和拖拽
- 点击节点可展开/折叠
- 点击罪名节点查看详情

#### 导出图片

在思维导图模式下，点击下载按钮：

- 自动保存为 PNG 格式
- 保存位置：`文档/crime_analysis_<时间戳>.png`

---

## Android 移动端

### 安装 APK

```bash
cd legal_assist
flutter build apk --release
```

APK 位置：`build/app/outputs/flutter-apk/app-release.apk`

### 首次配置

1. **法律资产**：系统会自动加载 APK 内部集成的默认资产（`assets/legal_base.yaml` 和 `assets/embeddings/v4-embedding-criminal.pak`）。
   > **注意**：程序会自动解压内置资产到应用私有目录，现在会显示完整的文件路径。
   > 如需使用自定义配置文件：请将文件传输到手机存储（推荐 `Download` 文件夹），然后在 App「设置」页面点击“选择文件”手动加载。

2. **API Key**：必须在「设置」页面手动配置
   > ⚠️ Android 端无法读取 `secrets.yaml`，请手动输入 API Key。建议将 API Key 保存到手机剪贴板后粘贴。

### 界面适配

| 屏幕尺寸 | 导航方式 | 侧栏状态 |
| :--- | :--- | :--- |
| 手机竖屏 (< 600px) | 底部导航栏 | 无 |
| 平板竖屏 (600-900px) | 侧边导航栏 | 可折叠 |
| 平板横屏 (> 900px) | 侧边导航栏 | 固定展开 |

### 思维导图手势

| 手势 | 操作 |
| :--- | :--- |
| 双指缩放 | 放大/缩小视图 |
| 单指拖拽 | 平移视图 |
| 单击节点 | 展开/折叠子节点 |
| 单击罪名 | 查看详细分析 |

---

## 功能详解

### 设置页面

#### LLM 配置

| 参数 | 说明 | 默认值 |
| :--- | :--- | :--- |
| API Key | 阿里云 DashScope 密钥 | 从 secrets.yaml 读取 |
| 模型 | Embedding 模型 | text-embedding-v4 |
| 维度 | 向量维度 | 1024 |

#### 分析参数

| 参数 | 说明 | 默认值 |
| :--- | :--- | :--- |
| 相似度阈值 | 匹配判定边界 | 45% |

> 💡 阈值越低，匹配越宽松；阈值越高，匹配越严格

### 分析层级说明

| 层级 | 名称 | 作用 |
| :--- | :--- | :--- |
| L1 | 核心构成要件 | 判断是否满足犯罪构成 |
| L2 | 阻却事由 | 检查排除犯罪情形 |
| L3 | 量刑情节 | 确定加重/减轻因素 |

### 结论类型

| 图标 | 结论 | 含义 |
| :--- | :--- | :--- |
| 🔴 | 构成（严重） | L3 命中加重情节 |
| 🟠 | 构成（一般） | L3 无特殊情节 |
| 🟡 | 构成（轻微） | L3 命中减轻情节 |
| ⚪ | 不构成 | L1 缺失核心要件 |
| 🟢 | 排除 | L2 命中阻却事由 |
| 🟡 | 待定 | L1 存在不确定要件 |

---

## Embedding Builder Tool (高级)

> 此组件供**维护人员**使用，用于管理 YAML 基座和生成 Embedding 包。

### 1. YAML 基座编辑

1. **新建模板**：点击"新建模板"创建默认 YAML 结构。
2. **打开文件**：加载现有的 `legal_base.yaml` 文件。
3. **编辑 Slots**：添加/删除事实要素槽位，设置名称、语义边界、分析层级。
4. **编辑 Crimes**：添加/删除罪名定义，配置必需/可选/排除要件。
5. **保存**：导出修改后的 YAML 文件。

### 2. Embedding 计算

1. 确保已加载 YAML 基座。
2. 在"设置"页面配置 LLM API Key 和 Embedding 模型。
3. 选择法律条文目录（包含 `.txt` 格式的法条文件）。
4. 点击"开始计算"，等待进度完成。
5. 点击"导出 .pak 文件"保存 Embedding 包。

> 生成的 `.pak` 文件需复制到 `legal_assist/assets/` 目录并更新 `pubspec.yaml`。

---

## 常见问题

### Q: 提取事实失败？

**可能原因**：

1. 网络连接问题
2. API Key 无效或过期
3. API 额度用尽

**解决方案**：

- 检查网络连接
- 在设置页面重新配置 API Key
- 查看错误信息中的 HTTP 状态码

### Q: 分析结果不准确？

**调整方法**：

1. 降低相似度阈值（更宽松匹配）
2. 检查案情描述是否完整
3. 确认使用的 Embedding 包版本

### Q: 内置资产加载失败？

**排查步骤**：

1. 检查 `pubspec.yaml` 中的 assets 配置
2. 运行 `flutter clean && flutter pub get`
3. 重新构建应用

### Q: 如何更新法律条文？

**操作流程**：

1. 使用 Program A（Embedding Builder）编辑 YAML
2. 重新生成 Embedding 包
3. 替换 Program B 的 assets 文件
4. 重新构建应用

### Q: Windows 运行时报 MissingPluginException？

**A:** 执行 `flutter clean` 后重新运行 `flutter run`。

---

## 技术支持

如遇问题，请提供：

- 操作系统版本
- Flutter 版本 (`flutter --version`)
- 错误截图或日志
- 复现步骤
