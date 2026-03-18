# AgentGOD 端到端测试场景

## 前置条件

1. 全局组件已安装（`./scripts/deploy.sh`）
2. 测试项目已初始化（`./scripts/deploy.sh /path/to/test-project`）

---

## 测试 1：部署脚本验证

### 1.1 全局安装

```bash
./scripts/deploy.sh
```

**验证：**
- [ ] `~/.cursor/skills/agent-orchestrator/SKILL.md` 存在
- [ ] `~/.cursor/skills/agent-orchestrator/references/delegation-protocol.md` 存在
- [ ] `~/.cursor/rules/agent-orchestrator.mdc` 存在

### 1.2 项目初始化

```bash
./scripts/deploy.sh /tmp/test-project
```

**验证：**
- [ ] `/tmp/test-project/.cursor/rules/agent-system.mdc` 存在
- [ ] `/tmp/test-project/agents/` 包含 _registry.md, _template.md, researcher.md, coder.md, reviewer.md, scanner.md
- [ ] `/tmp/test-project/workflows/state/` 存在
- [ ] `/tmp/test-project/.gitignore` 包含 `workflows/state/`

### 1.3 接管模式部署

```bash
./scripts/deploy.sh --takeover /tmp/test-project-takeover
```

**验证：**
- [ ] 常规部署文件全部存在
- [ ] `/tmp/test-project-takeover/workflows/.pending-takeover` 存在

### 1.4 幂等性

```bash
./scripts/deploy.sh /tmp/test-project   # 再次运行
```

**验证：**
- [ ] 不覆盖已有的 Agent 文件
- [ ] 输出 WARN 提示已存在

---

## 测试 2：简单任务直通

在已部署的项目中打开 Cursor，发送：

> "当前时间是几点？"

**预期行为：**
- [ ] 指挥官直接回答，不启动编排
- [ ] 不创建 state 文件
- [ ] 响应速度与普通对话一致

---

## 测试 3：复杂任务编排

> "帮我分析这个项目的代码质量，并给出改进建议"

**预期行为：**
- [ ] 指挥官识别为复杂任务
- [ ] 读取 agents/ 发现可用 Agent
- [ ] 委派 researcher（调研代码现状）和 reviewer（审查质量）
- [ ] 创建 `workflows/state/` 下的状态文件
- [ ] 汇总两个 Agent 的结果后向用户呈现

**验证：**
- [ ] 状态文件包含 workflow_id 和 status
- [ ] 最终输出包含调研和审查两方面内容

---

## 测试 4：项目接管

在已有代码的项目上：

> "接管这个项目"

**预期行为：**
- [ ] 指挥官启动接管流程
- [ ] 并行发起 4 个扫描 Task（结构/代码/历史/文档）
- [ ] 汇总后生成 `workflows/project-knowledge.md`
- [ ] 向用户报告项目概况

**验证：**
- [ ] project-knowledge.md 包含：项目概览、目录结构、架构摘要、开发进度、关键文件索引
- [ ] frontmatter 包含 generated_at 和 scan_version
- [ ] `.pending-takeover` 标记已被清除（如果存在）

---

## 测试 5：NEEDS_INPUT 人机交互

准备一个模糊的任务：

> "帮我搭建一个 API 服务"

**预期行为：**
- [ ] coder Agent 发现缺少关键信息（语言、框架等）
- [ ] 返回 NEEDS_INPUT 标记
- [ ] 指挥官向用户转达问题（如"用什么语言？需要哪些端点？"）
- [ ] 用户回答后，指挥官将答案注入续接 Task
- [ ] coder Agent 根据回答完成实现

**验证：**
- [ ] 提问格式清晰，包含上下文说明
- [ ] 用户回答后工作正确继续
- [ ] 状态文件记录了 waiting_for_input -> in_progress 的状态变化

---

## 测试 6：上下文检查点

发起一个大型任务：

> "把这个项目从 JavaScript 迁移到 TypeScript"

**预期行为：**
- [ ] 任务被分解为多个子任务
- [ ] 当某个子 Agent 的处理量大时，返回 CHECKPOINT
- [ ] 指挥官将检查点保存到 state 文件
- [ ] 发起新 Task 从断点继续

**验证：**
- [ ] state 文件中包含 CHECKPOINT 的记录
- [ ] 新 Task 正确从断点继续

---

## 测试 7：增量更新项目知识

在已接管的项目上做一些代码变更后：

> "更新项目知识"

**预期行为：**
- [ ] scanner Agent 读取 project-knowledge.md 的 last_updated
- [ ] 只扫描该时间之后的变更
- [ ] 更新 project-knowledge.md 的相关章节
- [ ] scan_version 递增

**验证：**
- [ ] last_updated 已更新
- [ ] scan_version 比之前大 1
- [ ] 新变更反映在知识文件中

---

## 测试 8：自定义 Agent

1. 在 agents/ 下创建 `data-analyst.md`：

```markdown
---
name: data-analyst
role: 数据分析师
expertise: [数据分析, 统计, 可视化]
tools: [Read, Grep, Shell]
subagent_type: generalPurpose
model: fast
can_ask_user: true
---

你是数据分析师...
```

2. 然后发送：

> "分析 data/ 目录下的 CSV 数据"

**预期行为：**
- [ ] 指挥官发现新的 data-analyst Agent
- [ ] 将数据分析任务委派给 data-analyst
- [ ] data-analyst 正确执行并返回结果

---

## 测试 9：错误处理

故意触发错误场景：

### 9.1 Agent 定义不存在

删除所有 Agent 文件后发送复杂任务。

**预期：** 指挥官提示需要配置 Agent，或直接处理。

### 9.2 子 Agent 失败

发送一个子 Agent 无法处理的任务。

**预期：** 指挥官报告失败，提供重试/跳过选项。

---

## 测试 10：跨项目复用

1. 部署到第二个项目：
```bash
./scripts/deploy.sh --takeover /path/to/project-B
```

2. 自定义 project-B 的 Agent（删除不需要的，添加新的）

3. 在两个项目中分别发起任务

**验证：**
- [ ] 两个项目的 Agent 团队独立
- [ ] 共享全局 Skill 和 Rule
- [ ] 各自的 workflows/ 互不影响
