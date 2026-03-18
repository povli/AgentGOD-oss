# Agent 注册表

本目录下所有非 `_` 前缀的 `.md` 文件会被指挥官自动发现并纳入可委派列表。

## 当前可用 Agent

| Agent | 文件 | 角色 | 专长 |
|-------|------|------|------|
| researcher | researcher.md | 研究员 | 信息搜索、代码探索、文献调研 |
| coder | coder.md | 开发者 | 代码实现、功能开发、bug 修复 |
| reviewer | reviewer.md | 审查员 | 代码审查、质量检查、最佳实践 |
| scanner | scanner.md | 扫描员 | 项目接管、代码库分析（内置，建议保留）|

## 添加新 Agent

1. 复制 `_template.md` 为 `{agent-name}.md`
2. 编辑 frontmatter：
   - `name`：小写 + 连字符，3-50 字符
   - `role`：一句话描述
   - `expertise`：专长领域列表（指挥官据此匹配任务）
   - `tools`：限制该 Agent 可用的工具（最小权限原则）
   - `subagent_type`：选择执行模式（见下方）
   - `can_ask_user`：是否允许向用户提问
3. 编写系统提示（文件 body 部分）
4. 更新本文件的表格（可选，指挥官会自动扫描）

## subagent_type 选择

| 类型 | 适用场景 |
|------|----------|
| `explore` | 搜索、探索、信息收集（快速，只读） |
| `generalPurpose` | 编码、分析、审查等通用任务 |
| `shell` | Git 操作、命令执行、环境配置 |
| `browser-use` | Web 测试、UI 验证 |

## tools 常用组合

| 用途 | 推荐 tools |
|------|-----------|
| 只读分析 | `[Read, Grep, Glob, SemanticSearch]` |
| 代码编写 | `[Read, Write, StrReplace, Shell, Grep]` |
| 测试执行 | `[Read, Shell, Grep]` |
| 信息搜索 | `[Read, Grep, Glob, SemanticSearch, WebSearch]` |

## 命名规范

- 使用小写字母和连字符：`data-analyst`，不用 `DataAnalyst` 或 `data_analyst`
- 名称要体现职能：`api-designer` 优于 `helper`
- 3-50 个字符
