# 委派协议详细参考

## Agent 定义文件解析

每个 `agents/*.md` 文件采用 YAML frontmatter + Markdown body 格式：

```yaml
---
name: string          # 标识符，小写+连字符，3-50 字符
role: string          # 一句话描述角色
expertise: [string]   # 专长领域列表
tools: [string]       # 允许的工具列表
subagent_type: string # generalPurpose | explore | shell | browser-use
model: string         # fast=快速低成本 | 留空/删除=继承主窗口模型（更强能力）
max_context_items: int # 建议单次最大处理条目数
can_ask_user: bool    # 是否允许向用户提问（默认 false）
---
```

Body 部分为该 Agent 的系统提示，在构造 Task prompt 时注入。

## Task prompt 构造模板

```
你是 {name}，{role}。

{--- Agent 系统提示 body ---}

{--- 如果 can_ask_user: true，注入 NEEDS_INPUT 协议 ---}

{--- 如果 can_ask_user: false，注入以下内容 ---}
如果执行过程中缺少信息，请用合理的默认值继续，并在结果中明确标注你所做的假设。

---
## 当前任务
{子任务详细描述}

## 项目上下文
{project-knowledge.md 中的相关摘要（控制在 500 字以内）}

## 工作流状态
状态文件：{path}
请将关键中间结果和最终结果写入此文件。

## 输出要求
1. 执行摘要（3-5 句话）
2. 关键产出物
3. 遇到的问题或风险
```

## subagent_type 选择指南

| 类型 | 适用场景 | 特点 |
|------|----------|------|
| explore | 代码搜索、信息收集、结构分析 | 快速，擅长搜索 |
| generalPurpose | 编码、分析、审查等通用任务 | 全能，最常用 |
| shell | Git 操作、命令执行、环境配置 | 命令行专长 |
| browser-use | Web 测试、UI 验证、页面交互 | 浏览器自动化 |

## 并行策略

- 最多同时发起 4 个 Task（Cursor 限制）
- 无依赖关系的任务尽量并行
- 有依赖的任务按拓扑序串行
- 并行任务全部返回后再进入汇总阶段

## 状态文件生命周期

```
创建(in_progress) → 更新(checkpoint) → 完成(completed) / 失败(failed)
```

- `in_progress`：工作流执行中
- `waiting_for_input`：等待用户输入
- `completed`：所有子任务完成
- `failed`：存在失败的子任务

## CHECKPOINT 格式

子 Agent 在任务量大需要切换上下文时返回：

```
## CHECKPOINT

### 已完成
{到目前为止的工作成果}

### 待继续
{下一步需要做什么}

### 关键上下文
{续接时必须知道的信息}
```

指挥官检测到后：
1. 将 CHECKPOINT 内容写入 state 文件
2. 发起新 Task，prompt 中引用 state 文件路径
3. 新 Task 的 Agent 读取 state 文件后从断点继续
