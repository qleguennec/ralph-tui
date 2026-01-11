# Ralph TUI

**AI Agent Loop Orchestrator** - A terminal UI for orchestrating AI coding agents to work through task lists autonomously.

Ralph TUI connects your AI coding assistant (Claude Code, OpenCode) to your task tracker (Beads, prd.json) and runs them in an autonomous loop, completing tasks one-by-one with intelligent selection, error handling, and full visibility into what's happening.

## Features

- **Autonomous Execution Loop** - Select task, build prompt, run agent, check completion, repeat
- **Multiple AI Agent Support** - Claude Code CLI, OpenCode, extensible plugin system
- **Multiple Task Trackers** - Beads (with optional bv intelligence), prd.json, extensible plugin system
- **Beautiful Terminal UI** - Real-time task list, iteration history, progress dashboard
- **Smart Task Selection** - Priority-based ordering, dependency awareness, bv graph analysis
- **Session Persistence** - Pause anytime, resume later, survive crashes
- **Graceful Interruption** - Ctrl+C with confirmation, clean shutdown, state preservation
- **Customizable Prompts** - Handlebars templates for task-to-prompt generation
- **Headless Mode** - Run without TUI for CI/CD or background execution
- **Iteration Logs** - Full output capture, browseable history, cleanup tools

## Requirements

- **Bun** >= 1.0.0 (Ralph TUI is built with OpenTUI which requires Bun)
- An AI coding agent CLI:
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`claude` CLI)
  - [OpenCode](https://github.com/opencode-ai/opencode) (`opencode` CLI)
- A task tracker:
  - [Beads](https://github.com/anthropics/beads) (`.beads/` directory with `bd` CLI)
  - `prd.json` file (simple JSON-based task list)

## Installation

```bash
# Install globally with Bun
bun install -g ralph-tui

# Or run directly without installing
bunx ralph-tui
```

## Quick Start

### 1. Initialize a Project

```bash
cd your-project
ralph-tui setup
```

This interactive wizard will:
- Detect available trackers (Beads, prd.json)
- Detect installed agents (Claude, OpenCode)
- Create a `.ralph-tui.yaml` configuration file

### 2. Run Ralph

```bash
# With Beads tracker
ralph-tui run --epic your-epic-id

# With prd.json tracker
ralph-tui run --prd ./prd.json

# Launch interactive TUI first (then use 'run' command)
ralph-tui
```

### 3. Watch the Magic

Ralph will:
1. Select the next available task (highest priority, no blockers)
2. Build a prompt with task details
3. Run your AI agent with the prompt
4. Detect completion via `<promise>COMPLETE</promise>` token
5. Mark the task complete and move to the next one

Press `q` to quit, `p` to pause, `d` for dashboard, `i` for iteration history.

## CLI Reference

```
Usage: ralph-tui [command] [options]

Commands:
  (none)              Launch the interactive TUI
  run [options]       Start Ralph execution
  resume [options]    Resume an interrupted session
  status              Check session status
  logs [options]      View/manage iteration output logs
  setup [options]     Run interactive project setup
  config show         Display merged configuration
  template show       Display current prompt template
  template init       Copy default template for customization
  plugins agents      List available agent plugins
  plugins trackers    List available tracker plugins
  help, --help, -h    Show this help message
```

### Run Options

| Option | Description |
|--------|-------------|
| `--epic <id>` | Epic ID for beads tracker |
| `--prd <path>` | PRD file path for json tracker |
| `--agent <name>` | Override agent plugin (claude, opencode) |
| `--model <name>` | Override model (opus, sonnet, haiku) |
| `--tracker <name>` | Override tracker plugin (beads, beads-bv, json) |
| `--iterations <n>` | Maximum iterations (0 = unlimited) |
| `--headless` | Run without TUI |
| `--no-setup` | Skip interactive setup wizard |
| `--on-error <strategy>` | Error handling: retry, skip, abort |
| `--max-retries <n>` | Maximum retries before skipping |

### Resume Options

| Option | Description |
|--------|-------------|
| `--cwd <path>` | Working directory |
| `--headless` | Run without TUI |
| `--force` | Override stale lock |

### Log Options

| Option | Description |
|--------|-------------|
| `--iteration <n>` | View specific iteration |
| `--task <id>` | View logs for a specific task |
| `--clean` | Clean up old logs |
| `--keep <n>` | Number of recent logs to keep (with --clean) |
| `--dry-run` | Preview cleanup without deleting |
| `--verbose` | Show full output (not truncated) |

## Configuration

Ralph TUI uses a layered configuration system:

1. **Global config**: `~/.config/ralph-tui/config.yaml`
2. **Project config**: `.ralph-tui.yaml` (in project root)
3. **CLI flags**: Override everything

### Example Configuration

```yaml
# .ralph-tui.yaml

# Default agent and tracker
agent: claude
tracker: beads-bv

# Agent-specific options
agentOptions:
  model: sonnet
  skipPermissions: true

# Tracker-specific options
trackerOptions:
  epicId: my-project-epic
  labels:
    - backend
    - priority

# Execution settings
maxIterations: 10
iterationDelay: 1000

# Error handling
errorHandling:
  strategy: skip      # retry | skip | abort
  maxRetries: 3
  retryDelayMs: 5000

# Auto-commit after task completion
autoCommit: false

# Custom prompt template (relative to project root)
prompt_template: ./my-prompt.hbs
```

## Usage Examples

### Working with Beads

Beads is a git-backed issue tracker. Ralph TUI integrates with it via the `bd` CLI.

```bash
# Run all open tasks in an epic
ralph-tui run --epic my-project-v1

# Use intelligent task selection with bv
ralph-tui run --epic my-project-v1 --tracker beads-bv

# The beads-bv tracker uses graph analysis to prioritize:
# - Tasks that unblock the most downstream work
# - Critical path items
# - High PageRank centrality scores
```

### Working with prd.json

The `prd.json` format is a simple JSON structure for task tracking:

```json
{
  "title": "My Project PRD",
  "userStories": [
    {
      "id": "US-001",
      "title": "User authentication",
      "description": "Implement login and logout",
      "acceptanceCriteria": [
        "Users can log in with email/password",
        "Users can log out"
      ],
      "priority": 1,
      "passes": false,
      "dependsOn": []
    }
  ]
}
```

```bash
# Run with PRD file
ralph-tui run --prd ./prd.json
```

### Using Different Agents

```bash
# Use Claude Code
ralph-tui run --agent claude --model opus

# Use OpenCode
ralph-tui run --agent opencode --model anthropic/claude-3-5-sonnet
```

### Headless Mode (CI/CD)

```bash
# Run without TUI for automation
ralph-tui run --epic my-epic --headless --iterations 5

# Logs are saved to .ralph-tui/iterations/
ralph-tui logs --iteration 1
```

### Session Management

```bash
# Check if a resumable session exists
ralph-tui status

# Resume an interrupted session
ralph-tui resume

# Force restart (clear stale lock)
ralph-tui run --force
```

## TUI Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `q` / `Escape` | Quit (from task list) |
| `Escape` | Back (from detail views) |
| `p` | Pause/Resume execution |
| `d` | Toggle progress dashboard |
| `i` | Toggle iteration history view |
| `t` | Return to task list |
| `j` / `Down` | Move selection down |
| `k` / `Up` | Move selection up |
| `Enter` | Drill into task/iteration details |
| `Ctrl+C` | Interrupt (with confirmation) |
| `Ctrl+C` x2 | Force quit immediately |

## Prompt Templates

Ralph uses Handlebars templates to generate prompts. You can customize the prompt format:

```bash
# View current template
ralph-tui template show

# Create a custom template
ralph-tui template init
# Edit .ralph-tui-prompt.hbs
```

### Available Template Variables

| Variable | Description |
|----------|-------------|
| `{{taskId}}` | Task identifier |
| `{{taskTitle}}` | Task title |
| `{{taskDescription}}` | Full description |
| `{{acceptanceCriteria}}` | Acceptance criteria |
| `{{epicId}}` | Parent epic ID |
| `{{epicTitle}}` | Parent epic title |
| `{{trackerName}}` | Active tracker name |
| `{{labels}}` | Task labels |
| `{{priority}}` | Priority level (P0-P4) |
| `{{status}}` | Current status |
| `{{type}}` | Task type |
| `{{dependsOn}}` | Dependencies |
| `{{blocks}}` | Tasks this unblocks |
| `{{model}}` | Agent model |
| `{{agentName}}` | Agent name |
| `{{cwd}}` | Working directory |
| `{{currentDate}}` | Current date |
| `{{currentTimestamp}}` | Current timestamp |

## Plugin System

Ralph TUI supports custom plugins for agents and trackers.

### Listing Plugins

```bash
ralph-tui plugins agents
ralph-tui plugins trackers
```

### Plugin Locations

- **Global plugins**: `~/.config/ralph-tui/plugins/agents/` and `~/.config/ralph-tui/plugins/trackers/`
- **Built-in plugins**: Bundled with the package

### Built-in Trackers

| Name | Description |
|------|-------------|
| `beads` | Beads issue tracker via `bd` CLI |
| `beads-bv` | Beads with `bv` intelligent task selection |
| `json` | prd.json file-based tracking |

### Built-in Agents

| Name | Description |
|------|-------------|
| `claude` | Claude Code CLI (`claude --print`) |
| `opencode` | OpenCode CLI (`opencode run`) |

## Architecture

```
ralph-tui/
├── src/
│   ├── cli.tsx           # CLI entry point
│   ├── commands/         # CLI commands (run, resume, status, logs, etc.)
│   ├── config/           # Configuration loading and validation
│   ├── engine/           # Execution engine (iteration loop)
│   ├── interruption/     # Signal handling and graceful shutdown
│   ├── logs/             # Iteration log persistence
│   ├── plugins/
│   │   ├── agents/       # Agent plugin system
│   │   └── trackers/     # Tracker plugin system
│   ├── session/          # Session and lock management
│   ├── setup/            # Interactive setup wizard
│   ├── templates/        # Prompt template system
│   └── tui/              # Terminal UI components
│       └── components/   # React components for OpenTUI
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Setting up the development environment
- Code style and conventions
- Testing requirements
- Pull request process

### Development Setup

```bash
# Clone the repo
git clone https://github.com/your-org/ralph-tui.git
cd ralph-tui

# Install dependencies
pnpm install

# Run in development mode
bun run ./src/cli.tsx

# Type check
pnpm typecheck

# Lint
pnpm lint
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Ralph TUI is built with:
- [OpenTUI](https://github.com/AshMartian/opentui) - Terminal UI framework for Bun
- [Handlebars](https://handlebarsjs.com/) - Template engine
- [Zod](https://zod.dev/) - Schema validation
