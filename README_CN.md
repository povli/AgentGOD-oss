# AgentGOD

[English](README.md) | [中文](README_CN.md)

**Cursor IDE 中的层级式多 Agent 编排系统。**

你只需跟一个指挥官对话。它分解你的需求，委派给专家 Agent 执行，最后汇总结果交给你 —— 全部在 Cursor 里完成。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Cursor](https://img.shields.io/badge/Built%20for-Cursor%20IDE-7c3aed)](https://cursor.sh)
[![Agents](https://img.shields.io/badge/Default%20Agents-4-green)]()

---

## 工作原理

```
你: "重构 utils 模块，先调研最佳实践，再实现，最后审查代码质量"

                         ┌────────┐
                         │ 指挥官  │ ← 你在这里对话
                         └───┬────┘
                    ┌────────┼────────┐
                    ▼        ▼        ▼
              ┌────────┐ ┌──────┐ ┌────────┐
              │ 研究员  │ │ 开发者│ │ 审查员  │
              │(调研)   │ │(实现) │ │(审查)  │
              └────────┘ └──────┘ └────────┘
                    │        │        │
                    └────────┼────────┘
                             ▼
                      汇总结果 → 你
```

每个 Agent 在**独立的上下文窗口**中运行（通过 Cursor 的 Task 工具）。指挥官负责协调一切 —— 并行执行、错误处理、上下文检查点，甚至在 Agent 需要信息时向你提问。

---

## 快速开始

**1. 克隆**

```bash
git clone https://github.com/povli/AgentGOD.git
cd AgentGOD
```

**2. 部署**（安装全局组件 + 初始化你的项目）

```bash
./scripts/deploy.sh /path/to/your-project
```

**3. 在 Cursor 中打开项目，开始对话**

> "帮我实现一个带认证的 REST API"

指挥官会自动处理剩下的事情。

---

## 核心特性

### 层级编排

一个指挥官接收你的请求，分析复杂度，委派给合适的专家。简单任务直接完成；复杂任务自动分解并行执行。

### 每个 Agent 独立上下文

每个专家在独立的上下文窗口中运行（通过 Cursor 的 `Task` 工具）。互不干扰。任务过长时，Agent 自动保存检查点并在新上下文中继续。

### Agent 会向你提问

当 Agent 缺少关键信息时，它会发送结构化的 `NEEDS_INPUT` 请求给指挥官，指挥官以友好的格式向你展示问题。你的回答会被注入到 Agent 的后续执行中。

### 项目接管

将 Agent 系统部署到已有代码库，一键扫描：

```bash
./scripts/deploy.sh --takeover /path/to/existing-project
```

Scanner Agent 会分析目录结构、技术栈、Git 历史和文档，然后生成 `project-knowledge.md`，让指挥官完整了解你的项目。

### 完全自定义 Agent

复制模板即可创建新 Agent：

```bash
cp agents/_template.md agents/my-specialist.md
# 编辑文件 —— 完成。无需重启。
```

每个 Agent 是一个带 YAML frontmatter 的 Markdown 文件：

```yaml
---
name: my-specialist
role: 一句话描述角色
expertise: [领域1, 领域2]
tools: [Read, Write, Grep]
subagent_type: generalPurpose
model: fast  # 或留空以继承主窗口模型
can_ask_user: true
---

你是 [角色]，专精于 [领域]。

（系统提示：职责、工作流程、输出格式）
```

### 跨项目复用

全局组件安装一次到 `~/.cursor/`，所有项目共享。每个项目拥有独立的 Agent 团队。一条命令部署到新项目。

---

## 默认 Agent

| Agent | 角色 | 适用场景 |
|-------|------|----------|
| **researcher** | 信息搜索与探索 | 代码库分析、技术调研、最佳实践 |
| **coder** | 代码实现 | 功能开发、Bug 修复、重构 |
| **reviewer** | 代码审查与质量 | 质量检查、安全审查、规范验证 |
| **scanner** | 项目接管 | 代码库扫描、知识提取 |
| **system-editor** | 系统改造 | 根据行业需求重新编排 Agent 团队 |

---

## 系统架构

```
~/.cursor/（全局，所有项目共享）
├── skills/agent-orchestrator/     ← 编排逻辑
│   ├── SKILL.md
│   └── references/
└── rules/agent-orchestrator.mdc   ← 检查点协议

你的项目/（每个项目独立）
├── .cursor/rules/
│   └── agent-system.mdc           ← 激活指挥官
├── agents/                         ← 你的 Agent 团队（自由定制）
│   ├── researcher.md
│   ├── coder.md
│   ├── reviewer.md
│   └── scanner.md
└── workflows/
    ├── project-knowledge.md        ← 接管时生成
    └── state/                      ← 运行时状态（已 gitignore）
```

---

## 部署命令

| 命令 | 说明 |
|------|------|
| `./scripts/deploy.sh` | 仅安装全局组件 |
| `./scripts/deploy.sh /path/to/project` | 全局 + 初始化项目 |
| `./scripts/deploy.sh --takeover /path/to/project` | 部署 + 标记待接管 |
| `./scripts/deploy.sh --project-only /path/to/project` | 仅初始化项目 |
| `./scripts/deploy.sh --force` | 强制更新全局组件 |

所有命令都是**幂等的** —— 重复执行不会覆盖你已自定义的 Agent。

---

## 创建自定义 Agent

**第 1 步：** 复制模板

```bash
cp agents/_template.md agents/api-designer.md
```

**第 2 步：** 编辑 frontmatter

| 字段 | 必填 | 说明 |
|------|------|------|
| `name` | 是 | 小写+连字符，3-50 字符 |
| `role` | 是 | 一句话描述角色 |
| `expertise` | 是 | 专长领域列表（指挥官据此匹配任务） |
| `tools` | 是 | 允许的工具列表（最小权限原则） |
| `subagent_type` | 是 | `explore` / `generalPurpose` / `shell` / `browser-use` |
| `model` | 否 | `fast` = 快速低成本；留空 = 继承主窗口模型 |
| `can_ask_user` | 否 | 是否允许向用户提问（默认 false） |

**第 3 步：** 编写系统提示（文件正文部分）

**第 4 步：** 完成。指挥官会在下次对话时自动发现新 Agent。

---

## 上下文切换机制

```
Agent 开始执行任务
    → 到达检查点（阶段边界 / 输出量大 / 超过 8 次工具调用）
    → 保存进度到 workflows/state/{id}.md
    → 返回 CHECKPOINT 给指挥官
    → 指挥官生成新的 Task，读取状态文件
    → Agent 从断点继续执行
```

这个过程是自动的。你只会看到指挥官说"正在继续处理..." —— 不需要你做任何操作。

---

## 常见问题

**指挥官没有自动分解任务？**
确认 `.cursor/rules/agent-system.mdc` 存在，且 `agents/` 目录至少有一个非 `_` 前缀的 `.md` 文件。

**最多能并行几个 Agent？**
最多 4 个（Cursor Task 工具限制）。有依赖关系的任务会自动串行执行。

**修改 Agent 后需要重启吗？**
不需要。指挥官每次对话时动态扫描 `agents/` 目录。

**会影响没有部署 AgentGOD 的项目吗？**
不会。全局 Skill 仅在触发条件匹配时激活。没有 `agent-system.mdc` 的项目完全不受影响。

**如何升级？**

```bash
git pull
./scripts/deploy.sh --force  # 更新全局组件
```

**如何卸载？**

```bash
rm -rf ~/.cursor/skills/agent-orchestrator
rm -f ~/.cursor/rules/agent-orchestrator.mdc
# 项目中：删除 .cursor/rules/agent-system.mdc、agents/、workflows/
```

---

## 贡献

欢迎贡献！你可以：

- 添加新的 Agent 模板
- 改进编排逻辑
- 修复 Bug 或完善文档

请先开 Issue 讨论较大的变更。

---

## 许可证

[MIT](LICENSE)
