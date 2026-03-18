#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GLOBAL_DIR="$REPO_ROOT/global"
TEMPLATE_DIR="$REPO_ROOT/project-template"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
AgentGOD Deploy Tool

Usage:
  $(basename "$0")                                  Install global components only
  $(basename "$0") <project-path>                   Install global + init project
  $(basename "$0") --project-only <project-path>    Init project only (skip global)
  $(basename "$0") --takeover <project-path>        Deploy + mark for project takeover
  $(basename "$0") --force                          Force update global components
  $(basename "$0") --help                           Show this help

Options:
  --force          Overwrite existing global components
  --project-only   Skip global install, only init the project
  --takeover       Mark project for auto-scan on first Cursor launch
  --help           Show this help message
EOF
    exit 0
}

log_info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

install_global() {
    local force="${1:-false}"

    log_info "Installing global components to $CURSOR_HOME ..."

    local skill_dest="$CURSOR_HOME/skills/agent-orchestrator"
    if [[ -d "$skill_dest" && "$force" != "true" ]]; then
        log_warn "Global Skill already exists: $skill_dest (use --force to overwrite)"
    else
        mkdir -p "$skill_dest/references"
        cp "$GLOBAL_DIR/skills/agent-orchestrator/SKILL.md" "$skill_dest/SKILL.md"
        cp "$GLOBAL_DIR/skills/agent-orchestrator/references/delegation-protocol.md" \
           "$skill_dest/references/delegation-protocol.md"
        log_ok "Installed global Skill: $skill_dest"
    fi

    local rule_dest="$CURSOR_HOME/rules/agent-orchestrator.mdc"
    if [[ -f "$rule_dest" && "$force" != "true" ]]; then
        log_warn "Global Rule already exists: $rule_dest (use --force to overwrite)"
    else
        mkdir -p "$CURSOR_HOME/rules"
        cp "$GLOBAL_DIR/rules/agent-orchestrator.mdc" "$rule_dest"
        log_ok "Installed global Rule: $rule_dest"
    fi
}

init_project() {
    local project_path="$1"
    local takeover="${2:-false}"

    if [[ ! -d "$project_path" ]]; then
        log_error "Target directory does not exist: $project_path"
        exit 1
    fi

    project_path="$(cd "$project_path" && pwd)"
    log_info "Initializing project: $project_path ..."

    local rules_dir="$project_path/.cursor/rules"
    mkdir -p "$rules_dir"
    if [[ -f "$rules_dir/agent-system.mdc" ]]; then
        log_warn "Project Rule already exists, skipping: $rules_dir/agent-system.mdc"
    else
        cp "$TEMPLATE_DIR/.cursor/rules/agent-system.mdc" "$rules_dir/agent-system.mdc"
        log_ok "Created project Rule: $rules_dir/agent-system.mdc"
    fi

    local agents_dir="$project_path/agents"
    mkdir -p "$agents_dir"

    for f in "$TEMPLATE_DIR/agents/"*.md; do
        local basename="$(basename "$f")"
        local dest="$agents_dir/$basename"
        if [[ -f "$dest" ]]; then
            log_warn "Agent already exists, skipping: $dest"
        else
            cp "$f" "$dest"
            log_ok "Created Agent: $dest"
        fi
    done

    mkdir -p "$project_path/workflows/state"
    if [[ ! -f "$project_path/workflows/project-knowledge.template.md" ]]; then
        cp "$TEMPLATE_DIR/workflows/project-knowledge.template.md" \
           "$project_path/workflows/project-knowledge.template.md"
    fi

    local gitignore="$project_path/.gitignore"
    if [[ -f "$gitignore" ]]; then
        if ! grep -q "workflows/state/" "$gitignore" 2>/dev/null; then
            echo "" >> "$gitignore"
            echo "# AgentGOD runtime state" >> "$gitignore"
            echo "workflows/state/" >> "$gitignore"
            log_ok "Updated .gitignore"
        fi
    else
        cat > "$gitignore" <<'GITIGNORE'
# AgentGOD runtime state
workflows/state/
GITIGNORE
        log_ok "Created .gitignore"
    fi

    if [[ "$takeover" == "true" ]]; then
        touch "$project_path/workflows/.pending-takeover"
        log_ok "Created takeover marker: workflows/.pending-takeover"
        echo ""
        log_info "Takeover marker set. The orchestrator will suggest a project scan when you open this in Cursor."
    fi

    echo ""
    log_ok "Project initialized: $project_path"
    echo ""
    echo "  Deployed files:"
    echo "    .cursor/rules/agent-system.mdc  (orchestration rule)"
    echo "    agents/                          (agent definitions)"
    echo "    workflows/state/                 (runtime state)"
    echo ""
    echo "  Next steps:"
    echo "    1. Open the project in Cursor"
    echo "    2. Customize agents in agents/ to fit your project"
    echo "    3. Tell the orchestrator what you need"
}

# --- Main ---

FORCE=false
PROJECT_ONLY=false
TAKEOVER=false
PROJECT_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --project-only)
            PROJECT_ONLY=true
            shift
            ;;
        --takeover)
            TAKEOVER=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            PROJECT_PATH="$1"
            shift
            ;;
    esac
done

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  AgentGOD Deploy Tool${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if [[ "$PROJECT_ONLY" == "true" ]]; then
    if [[ -z "$PROJECT_PATH" ]]; then
        log_error "--project-only requires a project path"
        exit 1
    fi
    init_project "$PROJECT_PATH" "$TAKEOVER"
elif [[ -n "$PROJECT_PATH" ]]; then
    install_global "$FORCE"
    echo ""
    init_project "$PROJECT_PATH" "$TAKEOVER"
else
    install_global "$FORCE"
fi

echo ""
log_ok "Done!"
