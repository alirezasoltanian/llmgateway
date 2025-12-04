# Customization Workflow

This is a forked open-source project with custom changes on `main`.

## Update Process

```bash
git fetch upstream
git checkout main
git merge upstream/main
# Resolve conflicts, then test
```

## Development Rules

- **Work directly on `main`** (no rebase/rewrite history)
- **Prefer new files/modules** over editing core upstream files
- **Minimize changes** to shared files to reduce conflicts
- **Resolve conflicts immediately** after merge

## Remotes

- `origin` = this fork
- `upstream` = original project

## When Making Changes

Ask: "Can this be a new file/wrapper instead of modifying core?" If yes, do that.
