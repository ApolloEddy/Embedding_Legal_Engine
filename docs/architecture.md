# 法律案件分析系统 - 架构文档

## 系统概述

本系统是一个**法律案件分析系统**，核心设计原则：

- **LLM 只是翻译器，不是裁决者**
- 使用 LLM 进行结构化提取与 text→embedding 映射
- 使用本地确定性算法完成罪名分析与解释
- 全过程可解释、可回溯、可复核

## 程序架构

系统由**两个完全独立的程序**组成，通过只读文件资产交互：

```
┌─────────────────────┐     只读资产      ┌─────────────────────┐
│    程序 A（离线）    │ ──────────────→   │  程序 B（主运行）   │
│                     │                   │                     │
│ • YAML 编辑         │   legal_base.yaml │ • 资产加载          │
│ • 条文管理          │   embeddings.pak  │ • Phase 2 提取      │
│ • Embedding 预计算  │                   │ • Phase 3 分析      │
└─────────────────────┘                   └─────────────────────┘
```

### 程序 A：离线工具程序

**职责（不可扩展）：**

1. 维护与编辑 YAML 基座文件
2. 按 YAML 中定义的 Slot 结构，对法律条文逐条调用 LLM 计算 Embedding
3. 导出只读的法律 Embedding 包

**禁止：**

- 解析案件事实
- 进行罪名分析
- 调用任何裁决或推理逻辑

### 程序 B：主运行程序

**功能：**

1. 加载 YAML 基座
2. 加载法律 Embedding 包
3. 接收用户输入案情
4. Phase 2：调用 LLM 提取案件事实
5. Phase 3：本地执行罪名分析（100% 本地、确定性、白箱）
6. 渲染解释性结果到 UI

## 核心数据结构

### YAML 基座

YAML 是系统的**唯一权威结构定义**，包含：

- 全局信息（版本、法律体系类型、分析层级）
- Slot 定义（构成要素，Embedding 的最小对齐单位）
- Crime 定义（罪名、必需/排除要件、解释模板）

### Slot 模型

每个 Slot 包含：

- `slot_id`：全局唯一标识
- `slot_name`：名称
- `analysis_level`：分析层级（1/2/3 级）
- `required`：是否必需
- `role`：角色（定性/排除/解释/统计）
- `semantic_scope`：语义边界（限定 Embedding 语义）

### Embedding 包

只读资产，包含：

- `embedding_model_id`：模型标识
- `embedding_version`：版本
- `dimension`：向量维度
- `embeddings`：slot_id → embedding_vector 映射

## 处理流程

### Phase 2：案件事实提取

1. 接收用户自然语言案情
2. 按 YAML 中 Slot 列表组装 Prompt
3. **单次**调用 LLM API（禁止多次调用）
4. LLM 输出 JSON：slot_id → slot_text, slot_embedding
5. slot_embedding 必须由 slot_text 派生
6. 执行 JSON Schema 校验

### Phase 3：罪名分析（纯本地）

1. 根据 analysis_level 选择参与分析的 Slot
2. 对每个候选罪名执行：
   - required_slots 是否齐全
   - exclusion_slots 是否命中
   - slot_embedding 相似度计算（Cosine/Dot Product）
3. 使用固定阈值判定
4. 输出：命中要件、缺失要件、不确定要件
5. 解释文本只能来自 YAML 的 explanation_template

**Phase 3 禁止：**

- 调用 LLM
- 生成新的 Embedding
- 修改 YAML

## LLM 使用规范

1. 全流程使用**同一个 Embedding 模型**
2. 更换 Embedding 模型必须**全量重算**法律 Embedding
3. 所有 LLM 输出必须为 JSON
4. 必须实现 Schema 校验
5. Slot 不允许由 LLM 自行新增或修改

## 目录结构

```
Embedding_Legal_Engine/
├── program_a/              # 离线工具程序
│   ├── lib/
│   │   ├── main.dart
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   └── pubspec.yaml
│
├── program_b/              # 主运行程序
│   ├── lib/
│   │   ├── main.dart
│   │   ├── engines/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── services/
│   └── pubspec.yaml
│
├── shared/                 # 共享数据结构
│   └── lib/
│       ├── models/
│       ├── schemas/
│       ├── validators/
│       └── utils/
│
├── assets/                 # 只读资产
│   ├── legal_base.yaml
│   ├── law_articles/
│   └── embeddings/
│
└── docs/
    └── architecture.md
```
