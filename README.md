# AgentGOD

[English](README.md) | [中文](README_CN.md)

**Hierarchical multi-agent orchestration for Cursor IDE.**

You talk to one commander. It breaks down your request, delegates to specialist agents, and delivers the combined result — all inside Cursor.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Cursor](https://img.shields.io/badge/Built%20for-Cursor%20IDE-7c3aed)](https://cursor.sh)
[![Agents](https://img.shields.io/badge/Default%20Agents-4-green)]()

---

## How It Works

```
You: "Refactor the utils module, research best practices first, then implement, then review"

                         ┌─────────────┐
                         │ Orchestrator │ ← You talk here
                         └──────┬──────┘
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
              ┌──────────┐ ┌────────┐ ┌──────────┐
              │Researcher│ │ Coder  │ │ Reviewer │
              │(explore) │ │(build) │ │(inspect) │
              └──────────┘ └────────┘ └──────────┘
                    │           │           │
                    └───────────┼───────────┘
                                ▼
                         Combined result → You
```

Each agent runs in its **own fresh context window** via Cursor's Task tool. The orchestrator coordinates everything — parallel execution, error handling, context checkpoints, and even asking you questions when agents need clarification.

---

## Quick Start

**1. Clone**

```bash
git clone https://github.com/povli/AgentGOD.git
cd AgentGOD
```

**2. Deploy** (installs global components + initializes your project)

```bash
./scripts/deploy.sh /path/to/your-project
```

**3. Open the project in Cursor and start talking**

> "Help me implement a REST API with authentication"

The orchestrator handles the rest.

---

## Features

### Hierarchical Orchestration

One commander agent receives your request, analyzes complexity, and delegates to the right specialists. Simple tasks are handled directly; complex tasks are decomposed and dispatched in parallel.

### Fresh Context Per Agent

Each specialist runs in a separate context window (via Cursor's `Task` tool). No context pollution. When a task gets too long, agents automatically checkpoint their progress and continue in a new context.

### Agents Ask You Questions

When an agent lacks critical information, it sends a structured `NEEDS_INPUT` request back to the orchestrator, which presents the questions to you in a friendly format. Your answers are injected into the agent's continuation.

### Project Takeover

Drop the agent system into an existing codebase and run a full scan:

```bash
./scripts/deploy.sh --takeover /path/to/existing-project
```

The scanner agent analyzes directory structure, tech stack, git history, and documentation — then generates a `project-knowledge.md` that gives the orchestrator full project context.

### Fully Customizable Agents

Create new agents by copying a template:

```bash
cp agents/_template.md agents/my-specialist.md
# Edit the file — done. No restart needed.
```

Each agent is a single Markdown file with YAML frontmatter:

```yaml
---
name: my-specialist
role: One-line description
expertise: [area-1, area-2]
tools: [Read, Write, Grep]
subagent_type: generalPurpose
model: fast  # or leave empty to inherit the main window model
can_ask_user: true
---

You are [role], specialized in [domain].

(system prompt: responsibilities, workflow, output format)
```

### Cross-Project Reusable

Global components install once to `~/.cursor/` and work across all projects. Each project gets its own agent team. Deploy to a new project in one command.

---

## Default Agents

| Agent | Role | Best For |
|-------|------|----------|
| **researcher** | Information search & exploration | Codebase analysis, tech research, best practices |
| **coder** | Code implementation | Feature development, bug fixes, refactoring |
| **reviewer** | Code review & quality | Quality checks, security audit, best practices |
| **scanner** | Project takeover | Codebase scanning, knowledge extraction |

---

## Architecture

```
~/.cursor/ (global, shared across all projects)
├── skills/agent-orchestrator/     ← Orchestration logic
│   ├── SKILL.md
│   └── references/
└── rules/agent-orchestrator.mdc   ← Checkpoint protocol

your-project/ (per-project)
├── .cursor/rules/
│   └── agent-system.mdc           ← Activates the orchestrator
├── agents/                         ← Your agent team (customize freely)
│   ├── researcher.md
│   ├── coder.md
│   ├── reviewer.md
│   └── scanner.md
└── workflows/
    ├── project-knowledge.md        ← Generated on takeover
    └── state/                      ← Runtime state (gitignored)
```

---

## Deploy Commands

| Command | What It Does |
|---------|-------------|
| `./scripts/deploy.sh` | Install global components only |
| `./scripts/deploy.sh /path/to/project` | Global + init project |
| `./scripts/deploy.sh --takeover /path/to/project` | Deploy + mark for auto-scan |
| `./scripts/deploy.sh --project-only /path/to/project` | Init project only |
| `./scripts/deploy.sh --force` | Force-update global components |

All commands are **idempotent** — running twice won't overwrite your customized agents.

---

## Creating Custom Agents

**Step 1:** Copy the template

```bash
cp agents/_template.md agents/api-designer.md
```

**Step 2:** Edit the frontmatter

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase + hyphens, 3-50 chars |
| `role` | Yes | One-line description |
| `expertise` | Yes | Areas of expertise (orchestrator uses this for task matching) |
| `tools` | Yes | Allowed tools (principle of least privilege) |
| `subagent_type` | Yes | `explore` / `generalPurpose` / `shell` / `browser-use` |
| `model` | No | `fast` for cheap tasks, empty to inherit main model |
| `can_ask_user` | No | Allow the agent to ask you questions (default: false) |

**Step 3:** Write the system prompt (the body of the file)

**Step 4:** Done. The orchestrator discovers new agents automatically on the next conversation.

---

## How Context Switching Works

```
Agent starts task
    → Reaches a checkpoint (phase boundary / large output / 8+ tool calls)
    → Saves progress to workflows/state/{id}.md
    → Returns CHECKPOINT to orchestrator
    → Orchestrator spawns a NEW Task that reads the state file
    → Agent continues from where it left off
```

This happens automatically. You just see the orchestrator say "continuing..." — no action needed from you.

---

## FAQ

**The orchestrator isn't delegating tasks?**
Check that `.cursor/rules/agent-system.mdc` exists and `agents/` has at least one non-`_` prefixed `.md` file.

**How many agents can run in parallel?**
Up to 4 (Cursor Task tool limit). Dependent tasks run sequentially.

**Do I need to restart after changing agents?**
No. The orchestrator scans `agents/` dynamically each conversation.

**Will this affect projects without AgentGOD?**
No. The global Skill only activates when trigger conditions match. The global Rule only fires when `workflows/` files are present. Projects without `agent-system.mdc` are unaffected.

**How to upgrade?**

```bash
git pull
./scripts/deploy.sh --force  # Updates global components
```

**How to uninstall?**

```bash
rm -rf ~/.cursor/skills/agent-orchestrator
rm -f ~/.cursor/rules/agent-orchestrator.mdc
# Per project: remove .cursor/rules/agent-system.mdc, agents/, workflows/
```

---

## Contributing

Contributions are welcome! Feel free to:

- Add new agent templates
- Improve the orchestration logic
- Fix bugs or improve documentation

Please open an issue first to discuss significant changes.

---

## License

[MIT](LICENSE)
