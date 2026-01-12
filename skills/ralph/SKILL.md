---
name: ralph-tui-create-json
description: "Convert PRDs to prd.json format for ralph-tui execution. Creates JSON task files with user stories, acceptance criteria, and dependencies. Triggers on: create prd.json, convert to json, ralph json, create json tasks."
---

# Ralph TUI - Create JSON Tasks

Converts PRDs to prd.json format for ralph-tui autonomous execution.

> **Note:** This skill is bundled with ralph-tui's JSON tracker plugin. Future tracker plugins (Linear, GitHub Issues, etc.) will bundle their own task creation skills.

---

## The Job

Take a PRD (markdown file or text) and create a prd.json file:
1. Parse user stories from the PRD
2. Extract acceptance criteria for each story
3. Set up dependencies between stories
4. Output ready for `ralph-tui run --prd <path>`

---

## Output Format

```json
{
  "project": "[Project name from PRD or directory]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Feature description from PRD]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "bun run typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "",
      "dependsOn": []
    },
    {
      "id": "US-002",
      "title": "[Story that depends on US-001]",
      "description": "...",
      "acceptanceCriteria": ["..."],
      "priority": 2,
      "passes": false,
      "notes": "",
      "dependsOn": ["US-001"]
    }
  ]
}
```

---

## Story Size: The #1 Rule

**Each story must be completable in ONE ralph-tui iteration (~one agent context window).**

Ralph-tui spawns a fresh agent instance per iteration with no memory of previous work. If a story is too big, the agent runs out of context before finishing.

### Right-sized stories:
- Add a database column + migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" → Split into: schema, queries, UI components, filters
- "Add authentication" → Split into: schema, middleware, login UI, session handling
- "Refactor the API" → Split into one story per endpoint or pattern

**Rule of thumb:** If you can't describe the change in 2-3 sentences, it's too big.

---

## Dependencies with `dependsOn`

Use the `dependsOn` array to specify which stories must complete first:

```json
{
  "id": "US-002",
  "title": "Create API endpoints",
  "dependsOn": ["US-001"],  // Won't be selected until US-001 passes
  ...
}
```

Ralph-tui will:
- Show US-002 as "blocked" until US-001 completes
- Never select US-002 for execution while US-001 is open
- Include "Prerequisites: US-001" in the prompt when working on US-002

**Correct dependency order:**
1. Schema/database changes (no dependencies)
2. Backend logic (depends on schema)
3. UI components (depends on backend)
4. Integration/polish (depends on UI)

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something the agent can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'open'"
- "Filter dropdown has options: All, Open, Closed"
- "Clicking delete shows confirmation dialog"
- "bun run typecheck passes"
- "bun run test passes"

### Bad criteria (vague):
- ❌ "Works correctly"
- ❌ "User can do X easily"
- ❌ "Good UX"
- ❌ "Handles edge cases"

### Always include as final criteria:
```
"bun run typecheck passes"
```

For stories with tests:
```
"bun run test passes"
```

For UI stories:
```
"Verify in browser using dev-browser skill"
```

---

## Conversion Rules

1. **Each user story → one JSON entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order (1 = highest)
4. **dependsOn**: Array of story IDs this story requires
5. **All stories**: `passes: false` and empty `notes`
6. **branchName**: Derive from feature name, kebab-case, prefixed with `ralph/`
7. **Always add**: "bun run typecheck passes" to every story

---

## Output Location

Default: `./prd.json` (project root)

Or specify a path - ralph-tui will use it with:
```bash
ralph-tui run --prd ./path/to/prd.json
```

---

## Example

**Input PRD:**
```markdown
# Task Priority System

Add priority levels to tasks.

## User Stories
- US-001: Add priority field to database
- US-002: Display priority badge on task cards
- US-003: Add priority filter
```

**Output prd.json:**
```json
{
  "project": "my-app",
  "branchName": "ralph/task-priority",
  "description": "Add priority levels to tasks",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add priority field to database",
      "description": "As a developer, I need to store task priority.",
      "acceptanceCriteria": [
        "Add priority column: 1-4 (default 2)",
        "Migration runs successfully",
        "bun run typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "",
      "dependsOn": []
    },
    {
      "id": "US-002",
      "title": "Display priority badge on task cards",
      "description": "As a user, I want to see task priority at a glance.",
      "acceptanceCriteria": [
        "Badge shows P1/P2/P3/P4 with colors",
        "Badge visible without hovering",
        "bun run typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 2,
      "passes": false,
      "notes": "",
      "dependsOn": ["US-001"]
    },
    {
      "id": "US-003",
      "title": "Add priority filter dropdown",
      "description": "As a user, I want to filter tasks by priority.",
      "acceptanceCriteria": [
        "Filter dropdown: All, P1, P2, P3, P4",
        "Filter persists in URL",
        "bun run typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 3,
      "passes": false,
      "notes": "",
      "dependsOn": ["US-002"]
    }
  ]
}
```

---

## Running with ralph-tui

After creating prd.json:
```bash
ralph-tui run --prd ./prd.json
```

Ralph-tui will:
1. Load stories from prd.json
2. Select the highest-priority story with `passes: false` and no blocking dependencies
3. Generate a prompt with story details + acceptance criteria
4. Run the agent to implement the story
5. Mark `passes: true` on completion
6. Repeat until all stories pass

---

## Checklist Before Saving

- [ ] Each story completable in one iteration
- [ ] Stories ordered by dependency (schema → backend → UI)
- [ ] `dependsOn` correctly set for each story
- [ ] Every story has "bun run typecheck passes"
- [ ] UI stories have browser verification criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No circular dependencies
