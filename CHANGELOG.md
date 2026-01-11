# 更新日志

## [Alpha 0.2.0] - 2026-01-11

### 🚀 重大更新：自适应分层分析架构

本次版本对分析引擎进行了全面重构，从用户手动选择层级改为引擎自适应执行全量分析。

### ✨ 新增功能

#### 分析引擎

- **自适应三层分析**：系统自动执行 L1→L2→L3 全量分析
  - L1: 核心构成要件比对（定性）
  - L2: 阻却事由排查（过滤）
  - L3: 量刑情节分析（定量）
- **Embedding 批量请求**：将 N 次串行请求优化为 1 次批量请求，显著降低延迟
- **分层结果模型**：新增 `TieredAnalysisResult`、`CoreElementsResult`、`ExclusionResult`、`SentencingResult` 等数据结构

#### 用户界面

- **思维导图视图**：可视化展示分析层级结构
  - 渐变色节点 + 贝塞尔曲线连接
  - 支持展开/折叠、缩放、拖拽
  - 点击节点查看详情
- **PNG 导出功能**：一键导出思维导图为图片
- **视图切换**：支持列表视图和思维导图视图切换

#### Android 适配

- **响应式布局优化**：
  - 手机竖屏：底部导航栏
  - 平板竖屏：可折叠侧边栏
  - 桌面/平板横屏：固定侧边栏
- **思维导图手机适配**：自动缩小节点尺寸，显示缩放提示
- **应用图标**：配置 LOGO.png 为应用图标

### 🔧 重构与优化

- 移除 `analysisLevel` 参数，改为引擎自适应
- 重构 `LocalAnalysisEngine.analyze()` 返回 `TieredAnalysisResult`
- 重构 `AppProvider`：移除层级相关状态和方法
- 重构 `SettingsScreen`：移除层级选择器，添加自适应分析说明
- 重构 `AnalysisResultScreen`：支持分层结果展示和视图切换
- 新增 `SentencingType` 枚举（加重/减轻/中性）
- 更新 `legal_base.yaml`：Level 3 Slot 添加 `sentencing_type` 字段

### 📝 文档

- 重写技术原理 README.md（含架构图、算法公式）
- 新增使用操作指南 USER_GUIDE.md
- 更新 CHANGELOG.md

### 🐛 修复

- 修复 `optional_slots` 未参与分析的问题
- 修复测试文件包名引用错误

---

## [Alpha 0.1.0] - 2026-01-09

### 初版发布

- 基础案情输入和分析功能
- LLM 事实提取（Phase 2）
- 本地罪名分析（Phase 3）
- Windows 和 Android 双平台支持
- secrets.yaml 自动配置加载
