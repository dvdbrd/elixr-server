# CLAUDE.md Maintenance Rules

## When to Update CLAUDE.md Files

After making significant code changes, update the nearest CLAUDE.md file in the affected module's directory. "Significant" means:

- Adding or removing a module/file
- Adding or removing public functions from a context/manager module
- Changing function signatures or return types
- Adding or removing schema fields
- Changing Ecto enums (status values, urgency levels, etc.)
- Adding or removing routes
- Changing associations or relationships between schemas
- Resolving a known issue or MVP limitation
- Adding new dependencies or supervision children

## What NOT to Trigger Updates For

- Formatting changes, comment edits, or minor refactors
- Private function changes that don't affect the public API
- Test file changes
- Asset/CSS changes (unless adding new design tokens documented in components CLAUDE.md)

## CLAUDE.md Structure Convention

Every module-level CLAUDE.md should follow this structure:

1. **Title** — Module name and one-line description
2. **Modules** — List of all modules with brief descriptions
3. **Key Data Structures** — Schemas, JSONB structures, enums
4. **Patterns** — Conventions specific to this module
5. **Known Issues / TODO** — Current limitations (remove when resolved)
6. **Auto-Update Rules** — Module-specific triggers for updating this file

## File Locations

Module-level CLAUDE.md files are placed in the module's directory and loaded on-demand when Claude works in that directory. The root CLAUDE.md at the project root is always loaded.

## Accuracy Over Completeness

A CLAUDE.md that says a module "does not exist" when it does is worse than one that is slightly incomplete. Always prioritize accuracy. When in doubt, read the source file and verify before documenting.
